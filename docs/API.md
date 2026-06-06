# API Reference

This is the **current supported API** of the production `MetaInstallPlugin` payload in this repository.

It is an iOS-only native singleton exposed directly to Godot as `MetaInstallPlugin`.

## Availability

- available on iOS when the native plugin is bundled and enabled
- not available on non-iOS platforms

Recommended guard:

```gdscript
if OS.get_name() == "iOS" and Engine.has_singleton("MetaInstallPlugin"):
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
- synchronizes advertiser-tracking-enabled state from current ATT authorization
- initializes the SDK
- calls `activateApp`

### `is_initialized() -> bool`

Returns whether initialization has completed successfully.

### `sync_advertiser_tracking_enabled() -> bool`

Synchronizes Meta SDK advertiser-tracking-enabled state with the current iOS ATT authorization status.

Returns:

- `true` when ATT is currently authorized
- `false` otherwise

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

### `get_sdk_version() -> String`

Returns the Meta iOS SDK version string.

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
- Android runtime

## Legacy Note

Older docs in this repository may mention a broader `MetaSdk` GDScript surface. That describes the earlier prototype, not the supported shipping payload.
