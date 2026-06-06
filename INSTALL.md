# Installation Guide — iOS Install Attribution

This guide documents the **current supported production payload** in this repository: the iOS-only `MetaInstallPlugin` used for Meta Ads install attribution in Godot 4.5.1 projects.

## What This Installs

The supported payload is:

- `ios/plugins/meta_install_plugin/`
- `ios/native/MetaInstallPlugin/`

It is a native iOS plugin, not the older `addons/meta_sdk/` prototype.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| macOS | 13+ | Required for iOS build/export workflow |
| Xcode | 15+ | For real-device builds and logs |
| Godot | 4.5.1 | Project/editor version used by the production payload |

## Build the Native Payload

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

## Copy Into a Godot Project

Copy the full plugin payload into the game project’s iOS plugin folder:

```sh
rsync -a ios/plugins/meta_install_plugin/ /path/to/your_game/ios/plugins/meta_install_plugin/
```

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

Initialize only on iOS, and do not let the plugin own ATT prompt timing.

Typical pattern:

```gdscript
if OS.get_name() == "iOS" and Engine.has_singleton("MetaInstallPlugin"):
    var plugin := Engine.get_singleton("MetaInstallPlugin")
    plugin.initialize(app_id, client_token, display_name, true)
```

Recommended follow-up behavior:

- trigger an explicit `flush()` shortly after startup for diagnostics
- periodically call `sync_advertiser_tracking_enabled()` after ATT may have changed
- flush again when advertiser tracking state changes

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

## Notes

- Xcode/device logs are more trustworthy than Meta dashboard latency during early validation.
- Dashboard `Overview` and `Test events` can lag or appear inconsistent even when delivery succeeded.
- The older broad-scope prototype docs in this repository are legacy reference material, not the supported shipping path.
