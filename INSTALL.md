# Installation Guide — Meta Install Attribution

This guide documents the **current supported production payloads** in this repository: the `MetaInstallPlugin` used for Meta Ads install attribution in Godot 4.5.1 projects.

## What This Installs

The supported payloads are:

- iOS:
  - `ios/plugins/meta_install_plugin/`
  - `ios/native/MetaInstallPlugin/`
- Android:
  - `addons/meta_install_plugin/`
  - `android/plugin/`

They are the supported production bridges, not the older `addons/meta_sdk/` prototype.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| macOS | 13+ | Required for iOS build/export workflow |
| Xcode | 15+ | For real-device builds and logs |
| Godot | 4.5.1 | Project/editor version used by the production payload |
| JDK | 17 | Required for Android AAR builds |

## Build the iOS Native Payload

```sh
GODOT_HEADERS_DIR=/path/to/godot-4.5.1 \
FBSDK_CORE_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBSDKCoreKit.xcframework" \
FBSDK_BASICS_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBSDKCoreKit_Basics.xcframework" \
FBAEMKIT_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBAEMKit.xcframework" \
ios/native/MetaInstallPlugin/scripts/build_xcframework.sh
```

This produces:

- `MetaInstallPlugin.debug.xcframework`
- `MetaInstallPlugin.release.xcframework`

## Build the Android Payload

```sh
cd android
./gradlew assemble
```

This produces and syncs:

- `addons/meta_install_plugin/MetaInstallPlugin-debug.aar`
- `addons/meta_install_plugin/MetaInstallPlugin-release.aar`

## Copy Into a Godot Project

Copy the iOS payload into the game project’s iOS plugin folder:

```sh
rsync -a ios/plugins/meta_install_plugin/ /path/to/your_game/ios/plugins/meta_install_plugin/
```

Copy the Android payload into the game project’s addon folder:

```sh
rsync -a addons/meta_install_plugin/ /path/to/your_game/addons/meta_install_plugin/
```

## Enable In Godot

Enable the Android export plugin addon in the target project:

- `res://addons/meta_install_plugin/plugin.cfg`

Also keep Android Gradle export enabled.

## Enable in the iOS Export Preset

In the game project’s `export_presets.cfg`, enable:

- `plugins/MetaInstallPlugin=true`

Also set these plist-backed values:

- `plugins_plist/FacebookAppID`
- `plugins_plist/FacebookClientToken`
- `plugins_plist/FacebookDisplayName`
- `plugins_plist/FacebookAutoLogAppEventsEnabled=true`
- `plugins_plist/FacebookAdvertiserIDCollectionEnabled=true`

## Runtime Project Settings

The game should also keep these runtime settings aligned:

| Setting | Purpose |
|---------|---------|
| `meta_sdk/app_id` | Meta App ID |
| `meta_sdk/client_token` | Meta client token |
| `meta_sdk/display_name` | Meta display name |
| `meta_sdk/advertiser_id_collection` | Controls advertiser ID collection |

## Runtime Initialization

Initialize on mobile only, and do not let the plugin own ATT prompt timing on iOS.

Typical pattern:

```gdscript
if (OS.get_name() == "iOS" or OS.get_name() == "Android") and Engine.has_singleton("MetaInstallPlugin"):
    var plugin := Engine.get_singleton("MetaInstallPlugin")
    plugin.initialize(app_id, client_token, display_name, true)
```

Recommended follow-up behavior:

- trigger an explicit `flush()` shortly after startup for diagnostics
- periodically call `sync_advertiser_tracking_enabled()` after ATT may have changed
- flush again when advertiser tracking state changes
- on Android, call `log_debug_test_event()` manually only when you want an explicit QA marker in Meta Test Events / Events Manager

## ATT Ownership

This plugin does **not** request ATT itself.

That is intentional. The host game should decide when to request ATT in its own UX flow. The plugin only mirrors the resulting authorization state into Meta SDK settings via `sync_advertiser_tracking_enabled()`.

## Verification

Expected successful signs:

- device log shows Meta initialization
- device log shows requests to `graph.facebook.com/.../activities`
- responses return HTTP `200`
- response body includes `success = 1`
- Meta Events Manager later surfaces `Activate app` and `App installs`
- Android manual QA can additionally surface `godot_meta_debug_test_event` when the debug helper is called

## Notes

- Android keeps `sync_advertiser_tracking_enabled()` only for API parity with iOS.
- The Android debug event helper is manual-only; it is not triggered automatically by the runtime tracker anymore.
- Xcode/device logs are more trustworthy than Meta dashboard latency during early validation.
- Dashboard `Overview` and `Test events` can lag or appear inconsistent even when delivery succeeded.
- The older broad-scope prototype docs in this repository are legacy reference material, not the supported shipping path.
