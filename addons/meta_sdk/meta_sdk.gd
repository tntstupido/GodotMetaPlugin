extends Node
## MetaSdk
##
## Public GDScript singleton for the Meta (Facebook) SDK.
##
## Initialise once at game start:
## [codeblock]
## MetaSdk.initialize({
##     "app_id": "1234567890123456",
##     "client_token": "abcd...",
##     "display_name": "My Game",
## })
## [/codeblock]
##
## Sub-systems are exposed as child nodes (`login`, `share`, `events`,
## `ads`, `graph`) and their signals are re-emitted on this singleton as
## well. Use whichever pattern you prefer.
##
## iOS-only. On non-iOS platforms the GDScript class still loads but all
## methods become no-ops so the editor and other platforms keep working.

const _LOG_TAG := "[Meta SDK]"

## Emitted after a successful Facebook Login.
signal login_completed(access_token: String, user_id: String, name: String, picture_url: String)
## Emitted on Facebook Login failure.
signal login_failed(error: String)
## Emitted when the user cancelled the Login dialog.
signal login_cancelled

## Emitted when a share dialog was opened.
signal share_opened(type: String, payload: String)
## Emitted after a share completed.
signal share_completed(type: String)
## Emitted when a share failed.
signal share_failed(type: String, error: String)

## Emitted after an analytics event is queued for sending.
signal event_logged(event_name: String)

# Banner --------------------------------------------------------------------
signal banner_ad_loaded(placement_id: String)
signal banner_ad_failed(placement_id: String, error: String)
signal banner_ad_clicked(placement_id: String)
signal banner_ad_clicked_finished(placement_id: String)

# Interstitial --------------------------------------------------------------
signal interstitial_ad_loaded(placement_id: String)
signal interstitial_ad_failed(placement_id: String, error: String)
signal interstitial_ad_impression(placement_id: String)
signal interstitial_ad_clicked(placement_id: String)
signal interstitial_ad_closing(placement_id: String)
signal interstitial_ad_closed(placement_id: String)

# Rewarded ------------------------------------------------------------------
signal rewarded_ad_loaded(placement_id: String)
signal rewarded_ad_failed(placement_id: String, error: String)
signal rewarded_ad_impression(placement_id: String)
signal rewarded_ad_clicked(placement_id: String)
signal rewarded_ad_completed(placement_id: String)
signal rewarded_ad_closing(placement_id: String)
signal rewarded_ad_closed(placement_id: String)
signal rewarded_ad_server_reward(placement_id: String)
signal rewarded_ad_server_reward_failed(placement_id: String)

# Graph ---------------------------------------------------------------------
signal graph_response(tag: String, response: Dictionary)

# App Links -----------------------------------------------------------------
signal url_opened(url: String)

# ---------------------------------------------------------------------------
# Sub-systems
# ---------------------------------------------------------------------------

const MetaLoginScript := preload("res://addons/meta_sdk/meta_login.gd")
const MetaShareScript := preload("res://addons/meta_sdk/meta_share.gd")
const MetaEventsScript := preload("res://addons/meta_sdk/meta_events.gd")
const MetaAdsScript := preload("res://addons/meta_sdk/meta_ads.gd")
const MetaGraphScript := preload("res://addons/meta_sdk/meta_graph.gd")

var login: Node
var share: Node
var events: Node
var ads: Node
var graph: Node

var _initialized: bool = false
var _native: Object = null


func _ready() -> void:
	# Create the sub-system helpers and forward their signals.
	login = _add_child_signal_forwarder("MetaLogin", MetaLoginScript)
	share = _add_child_signal_forwarder("MetaShare", MetaShareScript)
	events = _add_child_signal_forwarder("MetaEvents", MetaEventsScript)
	ads = _add_child_signal_forwarder("MetaAds", MetaAdsScript)
	graph = _add_child_signal_forwarder("MetaGraph", MetaGraphScript)

	# Locate the native singleton (registered as `MetaSdk` by the
	# GDExtension). If it is missing (editor on non-iOS), we still
	# work as a no-op.
	if ClassDB.class_exists("MetaSdkPlugin"):
		_native = ClassDB.instantiate("MetaSdkPlugin")
		if _native != null:
			_bind_native_signals()
		else:
			push_warning("%s Could not instantiate native MetaSdkPlugin." % _LOG_TAG)
	else:
		push_warning("%s Native bridge not loaded. This is expected on non-iOS platforms or in the editor." % _LOG_TAG)


func _add_child_signal_forwarder(name: String, script: GDScript) -> Node:
	var n := Node.new()
	n.name = name
	n.set_script(script)
	n.set("sdk", self) # so sub-modules can dispatch on the singleton
	add_child(n)
	return n


func _bind_native_signals() -> void:
	# All of the native signals have the same name as ours, so we can
	# wire them up generically.
	var signal_names := [
		"login_completed", "login_failed", "login_cancelled",
		"share_opened", "share_completed", "share_failed",
		"event_logged",
		"banner_ad_loaded", "banner_ad_failed", "banner_ad_clicked", "banner_ad_clicked_finished",
		"interstitial_ad_loaded", "interstitial_ad_failed", "interstitial_ad_impression",
		"interstitial_ad_clicked", "interstitial_ad_closing", "interstitial_ad_closed",
		"rewarded_ad_loaded", "rewarded_ad_failed", "rewarded_ad_impression",
		"rewarded_ad_clicked", "rewarded_ad_completed", "rewarded_ad_closing",
		"rewarded_ad_closed", "rewarded_ad_server_reward", "rewarded_ad_server_reward_failed",
		"graph_response",
		"url_opened",
	]
	for sig in signal_names:
		# We can't easily introspect a native Object for its signals, so
		# we just connect the well-known list; if a signal does not
		# exist on the native side, connect() will print a warning and
		# the call is wrapped in a check.
		if _native.has_signal(sig):
			_native.connect(sig, _reemit.bind(sig))


func _reemit(args: Array, sig: String) -> void:
	emit_signal(sig, *args)


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

## Initialise the Meta SDK with the given configuration.
## Falls back to `meta_sdk/*` project settings when keys are missing.
func initialize(config: Dictionary = {}) -> void:
	if _initialized:
		push_warning("%s Already initialised." % _LOG_TAG)
		return

	var cfg := _resolve_config(config)
	if cfg.app_id.is_empty():
		push_error("%s meta_sdk/app_id is empty. Aborting initialization." % _LOG_TAG)
		return

	_initialized = true
	print_rich("[color=#1877F2][b]%s[/b][/color] Initializing (app_id=%s)" % [_LOG_TAG, cfg.app_id])

	if _native != null:
		_native.call("initialize", cfg.app_id, cfg.client_token, cfg.display_name)
		_native.call("set_auto_log_app_events_enabled", cfg.auto_log_app_events)
		_native.call("set_advertiser_id_collection_enabled", cfg.advertiser_id_collection)
		_native.call("set_log_level", cfg.log_level_int)

	# Bubble the initialization to the sub-modules.
	if login != null and login.has_method("on_initialized"):
		login.call("on_initialized", cfg)
	if share != null and share.has_method("on_initialized"):
		share.call("on_initialized", cfg)
	if events != null and events.has_method("on_initialized"):
		events.call("on_initialized", cfg)
	if ads != null and ads.has_method("on_initialized"):
		ads.call("on_initialized", cfg)
	if graph != null and graph.has_method("on_initialized"):
		graph.call("on_initialized", cfg)


func is_initialized() -> bool:
	return _initialized


func get_sdk_version() -> String:
	if _native != null and _native.has_method("get_sdk_version"):
		return _native.call("get_sdk_version")
	return ""


func get_ios_version() -> String:
	if _native != null and _native.has_method("get_ios_version"):
		return _native.call("get_ios_version")
	return ""


func get_device_model() -> String:
	if _native != null and _native.has_method("get_device_model"):
		return _native.call("get_device_model")
	return ""


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _resolve_config(overrides: Dictionary) -> Dictionary:
	var log_level_str: String = str(ProjectSettings.get_setting("meta_sdk/log_level", "Warning"))
	var log_level_int := _log_level_string_to_int(log_level_str)

	return {
		"app_id": str(overrides.get("app_id", ProjectSettings.get_setting("meta_sdk/app_id", ""))),
		"client_token": str(overrides.get("client_token", ProjectSettings.get_setting("meta_sdk/client_token", ""))),
		"display_name": str(overrides.get("display_name", ProjectSettings.get_setting("meta_sdk/display_name", ""))),
		"auto_log_app_events": bool(overrides.get("auto_log_app_events", ProjectSettings.get_setting("meta_sdk/auto_log_app_events", true))),
		"advertiser_id_collection": bool(overrides.get("advertiser_id_collection", ProjectSettings.get_setting("meta_sdk/advertiser_id_collection", false))),
		"facebook_domain": str(overrides.get("facebook_domain", ProjectSettings.get_setting("meta_sdk/facebook_domain", ""))),
		"url_scheme_suffix": str(overrides.get("url_scheme_suffix", ProjectSettings.get_setting("meta_sdk/url_scheme_suffix", ""))),
		"log_level": log_level_str,
		"log_level_int": log_level_int,
	}


func _log_level_string_to_int(level: String) -> int:
	match level.to_lower():
		"none": return 0
		"developer": return 0
		"debug": return 1
		"info": return 2
		"warning": return 3
		"error": return 4
		_: return 3
