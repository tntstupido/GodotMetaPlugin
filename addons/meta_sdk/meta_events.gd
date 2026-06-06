extends Node
## MetaEvents
##
## GDScript wrapper around Facebook App Events (analytics).

signal event_logged(event_name: String)

var sdk: Node = null


func on_initialized(_config: Dictionary) -> void:
	if sdk != null:
		sdk.event_logged.connect(_on_event_logged)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Log a custom event. Optionally include parameters and a value to sum.
## [codeblock]
## MetaSdk.events.log_event("level_completed", {
##     "level_name": "Forest-1",
##     "score": 1234,
## }, value_to_sum: 1234)
## [/codeblock]
func log_event(event_name: String, parameters: Dictionary = {}, value_to_sum: float = 0.0) -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("log_event", event_name, parameters, value_to_sum)
	emit_signal("event_logged", event_name)


## Log an in-app purchase.
## [codeblock]
## MetaSdk.events.log_purchase(4.99, "USD", {"item_id": "skin_001"})
## [/codeblock]
func log_purchase(amount: float, currency: String, parameters: Dictionary = {}) -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("log_purchase", amount, currency, parameters)
	emit_signal("event_logged", "fb_mobile_purchase")


## Set user-data fields (email, first name, last name, ...). The Meta
## SDK will hash the values for you.
func set_user_data(data: Dictionary) -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("set_user_data", data)


## Clear all user-data fields. Call this on logout.
func clear_user_data() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("clear_user_data")


## Force a flush of pending events. The SDK normally flushes every
## 15 seconds and on background.
func flush() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("flush")


# ---------------------------------------------------------------------------
# Install tracking (Meta Ads Manager)
# ---------------------------------------------------------------------------
#
# The Facebook SDK auto-logs the `fb_mobile_install` event on first
# launch and then attributes the install to an Ads Manager campaign
# using the IDFA. To get this attribution you must:
#
# 1. Have `meta_sdk/auto_log_app_events` set to `true` (the default).
# 2. Have `meta_sdk/advertiser_id_collection` set to `true` AND have
#    the user grant App Tracking Transparency permission on iOS 14+.
# 3. Have the iOS export preset include the AppTrackingTransparency
#    framework (the plugin does this automatically).
# 4. Set the `NSUserTrackingUsageDescription` Info.plist key
#    (the plugin injects one for you).

## Returns true if the SDK is about to log the install event for the
## first time on this device. Use it to run one-off first-launch logic.
func is_first_launch() -> bool:
	if sdk == null or sdk._native == null:
		return false
	return bool(sdk._native.call("is_first_launch"))


## Returns the IDFA-style anonymous advertiser id used to attribute
## installs to Meta Ads Manager campaigns. Empty if the user has not
## granted ATT permission.
func get_advertiser_id() -> String:
	if sdk == null or sdk._native == null:
		return ""
	return str(sdk._native.call("get_advertiser_id"))


## Re-emit the `fb_mobile_install` event. Useful for QA dashboards.
func log_install_event() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("log_install_event")
	emit_signal("event_logged", "fb_mobile_install")


# ---------------------------------------------------------------------------
# Signal forwarders
# ---------------------------------------------------------------------------

func _on_event_logged(event_name: String) -> void:
	emit_signal("event_logged", event_name)
