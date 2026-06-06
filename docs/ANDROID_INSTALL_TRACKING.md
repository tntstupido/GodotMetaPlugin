# Meta Ads Manager — Android Install Tracking

This document describes the Android production payload for `MetaInstallPlugin`.

## Runtime API

The Android singleton exposed to Godot is `MetaInstallPlugin`.

Supported methods:

- `initialize(app_id, client_token, display_name, advertiser_id_collection=true)`
- `is_initialized()`
- `sync_advertiser_tracking_enabled()`
- `flush()`
- `log_debug_test_event()` / `logDebugTestEvent()`
- `get_sdk_version()`

## Behavior

On initialization, the Android bridge:

1. applies the Meta app ID, client token, and display name
2. disables SDK auto-init so the game owns startup timing
3. initializes the Meta Android SDK explicitly
4. enables auto-log App Events
5. enables advertiser ID collection when configured
6. logs the activation event through `AppEventsLogger.activateApp(...)`

`sync_advertiser_tracking_enabled()` is kept for API parity with iOS. On Android it simply reapplies the configured advertiser-ID-collection flag and returns the current configured state.

When the host game calls it from an Android debug run, `log_debug_test_event()` logs a custom Meta App Event named `godot_meta_debug_test_event`. This is intended only as an implementation-verification aid and is available for manual QA use, not automatic release gameplay logic.

Current verification status:

- Android debug runs initialize the SDK successfully
- Android debug runs can flush App Events successfully
- Meta Events Manager has already received both `Activate app` and `godot_meta_debug_test_event` during validation

## Build

From the repository root:

```sh
cd android
./gradlew assemble
```

This builds:

- `android/plugin/build/outputs/aar/MetaInstallPlugin-debug.aar`
- `android/plugin/build/outputs/aar/MetaInstallPlugin-release.aar`

The assemble flow also syncs those AARs into:

- `addons/meta_install_plugin/`

## Godot Packaging

The reusable Godot Android plugin payload lives under:

- `addons/meta_install_plugin/plugin.cfg`
- `addons/meta_install_plugin/meta_install_plugin.gd`
- `addons/meta_install_plugin/MetaInstallPlugin-debug.aar`
- `addons/meta_install_plugin/MetaInstallPlugin-release.aar`

Enable that addon in the target Godot project and keep Android Gradle export enabled.

## Manifest Data Injected By The Export Plugin

- `com.facebook.sdk.ApplicationId`
- `com.facebook.sdk.ClientToken`
- `com.facebook.sdk.ApplicationName`
- `com.facebook.sdk.AutoInitEnabled=false`
- `com.facebook.sdk.AutoLogAppEventsEnabled=true`
- `com.facebook.sdk.AdvertiserIDCollectionEnabled`

The export script reads those values from the host project's `meta_sdk/*` settings.
