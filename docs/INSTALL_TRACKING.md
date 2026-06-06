# Meta Ads Manager — Install Tracking

This document describes the **current production behavior** of the iOS-only `MetaInstallPlugin` payload in this repository.

## What the Plugin Does

On initialization, the plugin:

1. Applies `FacebookAppID`, `FacebookClientToken`, and `FacebookDisplayName`.
2. Enables auto-log App Events.
3. Enables advertiser ID collection when configured.
4. Synchronizes Meta’s `advertiser_tracking_enabled` state against the current iOS ATT authorization.
5. Calls `initializeSDK`.
6. Calls `activateApp`.

The host game may then call `flush()` to force delivery for diagnostics.

## What We Observed in Production Validation

Real-device verification confirmed:

- `/activities` requests were sent to Meta
- HTTP responses returned `200`
- response body included `success = 1`
- Meta later surfaced `Activate app` and `App installs` in Events Manager

## Required Configuration

### Runtime

| Setting | Purpose |
|---------|---------|
| `meta_sdk/app_id` | Meta App ID |
| `meta_sdk/client_token` | Meta client token |
| `meta_sdk/display_name` | App/display name |
| `meta_sdk/advertiser_id_collection` | Advertiser ID collection toggle |

### Export / Info.plist

| Key | Required |
|-----|----------|
| `FacebookAppID` | yes |
| `FacebookClientToken` | yes |
| `FacebookDisplayName` | yes |
| `FacebookAutoLogAppEventsEnabled` | yes |
| `FacebookAdvertiserIDCollectionEnabled` | yes |
| `NSUserTrackingUsageDescription` | yes, if ATT may be requested |

## ATT Behavior

The plugin does **not** show the ATT prompt itself.

The recommended ownership split is:

- game UX decides when ATT is requested
- plugin mirrors ATT authorization into Meta SDK state
- plugin or host game flushes again after ATT changes if you want immediate diagnostics

When ATT is not yet authorized, the plugin may initially send events with:

- `advertiser_tracking_enabled: 0`
- a zeroed or unavailable advertiser identifier

After ATT becomes authorized and the host game re-syncs state, later events can include:

- `advertiser_tracking_enabled: 1`
- a real advertiser identifier

## Diagnostic Pattern

Useful validation pattern on iOS:

1. initialize plugin
2. flush once a few seconds after launch
3. request ATT at the game’s chosen moment
4. call `sync_advertiser_tracking_enabled()` after the ATT result is known
5. flush again if the tracking-enabled value changed

## Important Dashboard Note

Meta dashboard surfaces can lag or disagree temporarily:

- device/Xcode logs may already show successful delivery
- `Test events` may still appear empty
- `Overview` may update later

For early verification, trust the on-device `/activities` request/response path first.
