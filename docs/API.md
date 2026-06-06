# API Reference

This is the **current supported API** of the production `MetaInstallPlugin` payload in this repository.

It is a mobile singleton exposed directly to Godot as `MetaInstallPlugin`.

## Availability

- available on iOS when the native plugin is bundled and enabled
- available on Android when the addon export plugin and AAR payload are bundled and enabled
- not available on other platforms

Recommended guard:

```gdscript
if (OS.get_name() == "iOS" or OS.get_name() == "Android") and Engine.has_singleton("MetaInstallPlugin"):
    var plugin := Engine.get_singleton("MetaInstallPlugin")
```

## Methods

### `initialize(app_id, client_token, display_name, advertiser_id_collection=true) -> int`

Initializes Meta Core/App Events for install attribution.

Parameters:

- `app_id: String`
- `client_token: String`
- `display_name: String`
- `advertiser_id_collection: bool = true`

Returns:

- Godot `OK` on success
- `ERR_INVALID_PARAMETER` when `app_id` is empty

Behavior:

- sets Meta SDK identifiers
- enables auto-log App Events
- enables advertiser ID collection when requested
- initializes the SDK
- calls `activateApp`
- on iOS, synchronizes advertiser-tracking-enabled state from current ATT authorization

### `is_initialized() -> bool`

Returns whether initialization has completed successfully.

### `sync_advertiser_tracking_enabled() -> bool`

Synchronizes Meta SDK advertiser-tracking-enabled state with the current iOS ATT authorization status.

Returns:

- `true` when ATT is currently authorized
- `false` otherwise

On Android, this method is retained for API parity and re-applies the configured advertiser-ID-collection flag.

Typical use:

```gdscript
var enabled := plugin.sync_advertiser_tracking_enabled()
if enabled:
    plugin.flush()
```

### `flush() -> void`

Forces pending App Events to be sent immediately.

Useful for:

- startup diagnostics
- post-ATT verification
- device-log validation against Meta Events Manager

### `log_debug_test_event() -> bool`

Android debug helper.

Behavior:

- available on the Android bridge
- logs a custom Meta event named `godot_meta_debug_test_event`
- returns `true` when the event was queued
- returns `false` when the SDK is not initialized or the build is not the debug plugin variant

The host game can use this only for implementation verification and should not depend on it for production analytics.
It is intended for manual QA invocation rather than automatic startup behavior.

Observed validation use:

- Android debug builds used this helper to confirm end-to-end delivery into Meta Events Manager

### `get_sdk_version() -> String`

Returns the Meta mobile SDK version string.

## Current Scope

Supported production scope:

- install attribution
- app activation / app events initialization
- ATT-state synchronization
- explicit flushing

Not part of the supported production scope:

- login
- share
- audience network ads
- graph API helpers

## Legacy Note

Older docs in this repository may mention a broader `MetaSdk` GDScript surface. That describes the earlier prototype, not the supported shipping payload.
