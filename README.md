# Godot Meta Install Plugin

## Current Production Payload

This repository currently ships **Godot 4.5.1 install-attribution bridges** for Meta Ads on:

- iOS: `ios/plugins/meta_install_plugin/` + `ios/native/MetaInstallPlugin/`
- Android: `addons/meta_install_plugin/` + `android/plugin/`

It packages Meta Core/App Events SDK `18.0.3` and supports:

- App Events initialization
- `activateApp` / install-attribution delivery
- advertiser-tracking-enabled synchronization against iOS ATT status
- explicit event flush for diagnostics
- optional manual Android QA logging through `godot_meta_debug_test_event`

It intentionally does **not** currently ship production support for:

- Facebook Login
- Share dialogs
- Audience Network ads
- Graph API helpers
- the older `addons/meta_sdk/` prototype as an active payload

Debug builds enable Meta App Events and network-request logging so on-device delivery can be verified from Xcode/device logs.

## Project Integration

The current production integration pattern is:

1. Build or update the native iOS/Android payloads from this repository.
2. Sync:
   - `ios/plugins/meta_install_plugin/` into the game project's iOS plugin folder
   - `addons/meta_install_plugin/` into the game project's addon folder
3. Configure platform export values:
   - iOS plist values:
   - `FacebookAppID`
   - `FacebookClientToken`
   - `FacebookDisplayName`
   - `FacebookAutoLogAppEventsEnabled`
   - `FacebookAdvertiserIDCollectionEnabled`
   - Android manifest values are injected from the host project's `meta_sdk/*` settings by the addon export plugin
4. Initialize the plugin from game code on mobile only.
5. Let the game’s own consent flow own ATT timing on iOS.

In `monsterchromatic`, this runtime surface is driven by `scenes/autoload/MetaInstallTracker.gd`.

## Build

Build the native iOS xcframeworks with:

```sh
GODOT_HEADERS_DIR=/path/to/godot-4.5.1 \
FBSDK_CORE_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBSDKCoreKit.xcframework" \
FBSDK_BASICS_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBSDKCoreKit_Basics.xcframework" \
FBAEMKIT_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBAEMKit.xcframework" \
ios/native/MetaInstallPlugin/scripts/build_xcframework.sh
```

Outputs:

- `ios/plugins/meta_install_plugin/MetaInstallPlugin.debug.xcframework`
- `ios/plugins/meta_install_plugin/MetaInstallPlugin.release.xcframework`

Build the Android AARs with:

```sh
cd android
./gradlew assemble
```

Outputs:

- `addons/meta_install_plugin/MetaInstallPlugin-debug.aar`
- `addons/meta_install_plugin/MetaInstallPlugin-release.aar`

## Runtime API

The native singleton exposed to Godot is `MetaInstallPlugin`.

Supported methods:

- `initialize(app_id, client_token, display_name, advertiser_id_collection=true)`
- `is_initialized()`
- `sync_advertiser_tracking_enabled()`
- `flush()`
- `log_debug_test_event()` / `logDebugTestEvent()` (Android manual QA helper)
- `get_sdk_version()`

## Verification Notes

The current production payload has been verified to:

- initialize on real iOS hardware
- deliver `/activities` requests successfully with HTTP `200`
- return Meta `success = 1`
- surface `Activate app` and `App installs` in Meta Events Manager after dashboard propagation
- build Android AAR artifacts that package the same Godot singleton API for Gradle-based Godot Android exports
- initialize on Android debug hardware and deliver both `Activate app` and a custom `godot_meta_debug_test_event` into Meta Events Manager

## Legacy Prototype

The older `addons/meta_sdk/` GDExtension/export-plugin prototype remains in this repository as reference material only. Its docs describe a broader Meta surface than the current production payload and should not be treated as shipping behavior.

## Docs

- `INSTALL.md` — install-attribution integration flow
- `docs/ANDROID_INSTALL_TRACKING.md` — Android runtime/build behavior
- `docs/INSTALL_TRACKING.md` — runtime behavior and verification notes
- `docs/API.md` — current native singleton API

## License

MIT — see `LICENSE`.

Meta SDK is © Meta Platforms, Inc. and is governed by Meta's platform terms, not by this repository's license.
