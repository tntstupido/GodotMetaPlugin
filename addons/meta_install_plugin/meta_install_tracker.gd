extends Node
## MetaInstallTracker
##
## Reference autoload for `addons/meta_install_plugin`. Wraps the native
## `MetaInstallPlugin` GDExtension singleton (iOS + Android) and hides
## the singleton-name, ProjectSettings, and error-code boilerplate
## every consumer would otherwise re-implement.
##
## ## Consumer setup
##
## Add to the consumer project's `project.godot`:
##
## [codeblock]
## [autoload]
##
## MetaInstallTracker="*res://addons/meta_install_plugin/meta_install_tracker.gd"
## [/codeblock]
##
## Then in Project Settings -> Meta SDK fill in:
##
## - [code]meta_sdk/app_id[/code]
## - [code]meta_sdk/client_token[/code]
## - [code]meta_sdk/display_name[/code]
## - [code]meta_sdk/advertiser_id_collection[/code]
## - [code]meta_sdk/auto_initialize[/code] (default true; set false to defer)
##
## The tracker will auto-initialize on mobile during [code]_ready[/code]
## (Android + iOS only). On other platforms it stays idle.
##
## ## Direct usage from game code
##
## [codeblock]
## if MetaInstallTracker.is_initialized():
##     MetaInstallTracker.flush()
## var sdk_version: String = MetaInstallTracker.get_sdk_version()
## # After triggering the ATT prompt, push the new auth state into the SDK:
## var tracking: bool = MetaInstallTracker.sync_advertiser_tracking_enabled()
## [/codeblock]

signal initialization_completed(success: bool, error_code: int, message: String)

const _LOG_TAG := "[MetaInstallTracker]"

const _SINGLETON_CANDIDATES := [
	"MetaInstallPlugin",
	"metainstallplugin",
	"MetaInstall",
	"metainstall",
	"MetaInstallPluginDebug",
]

const _OK := 0
const _ERR_INVALID_PARAMETER := 31
const _ERR_UNAVAILABLE := 49

var _plugin: Object = null
var _singleton_name: String = ""
var _initialized: bool = false
var _last_error_code: int = 0
var _last_error_message: String = ""


func _ready() -> void:
	if not _should_auto_initialize():
		return
	initialize()


func _should_auto_initialize() -> bool:
	var platform: String = OS.get_name()
	if platform != "Android" and platform != "iOS":
		return false
	return bool(ProjectSettings.get_setting("meta_sdk/auto_initialize", true))


## Initialize the native plugin. Returns true on success.
## Safe to call multiple times; subsequent calls return the cached state.
func initialize() -> bool:
	if _initialized:
		return true

	var app_id: String = str(ProjectSettings.get_setting("meta_sdk/app_id", ""))
	var client_token: String = str(ProjectSettings.get_setting("meta_sdk/client_token", ""))
	var display_name: String = str(ProjectSettings.get_setting("meta_sdk/display_name", ""))
	var advertiser_id_collection: bool = bool(ProjectSettings.get_setting("meta_sdk/advertiser_id_collection", false))

	_plugin = _resolve_plugin()
	if _plugin == null:
		_record_failure(_ERR_UNAVAILABLE, "Plugin singleton not found. Tried: %s" % str(_SINGLETON_CANDIDATES))
		return false
	if not _plugin.has_method("initialize"):
		_record_failure(_ERR_UNAVAILABLE, "Resolved plugin (%s) has no initialize() method." % _singleton_name)
		_plugin = null
		return false

	var result: int = int(_plugin.call("initialize", app_id, client_token, display_name, advertiser_id_collection))
	if result == _OK:
		_initialized = true
		_last_error_code = _OK
		_last_error_message = ""
		print("%s Initialized via singleton '%s'." % [_LOG_TAG, _singleton_name])
		initialization_completed.emit(true, _OK, "")
		return true

	_plugin = null
	_record_failure(result, _describe_error(result))
	return false


## Returns true if the native plugin was successfully initialized.
func is_initialized() -> bool:
	return _initialized


## Force the native SDK to flush any queued events to Meta servers.
## No-op if not initialized.
func flush() -> void:
	if _plugin != null and _plugin.has_method("flush"):
		_plugin.call("flush")


## Re-sync the native SDK's advertiser-tracking flag with the current
## ATT authorization status. Call this after requesting ATT authorization,
## because the prompt result is not always available when initialize() runs.
## Returns the current tracking-enabled state, or false if not initialized.
func sync_advertiser_tracking_enabled() -> bool:
	if _plugin != null and _plugin.has_method("sync_advertiser_tracking_enabled"):
		return bool(_plugin.call("sync_advertiser_tracking_enabled"))
	return false


## Returns the Meta SDK version string, or empty if not available.
func get_sdk_version() -> String:
	if _plugin != null and _plugin.has_method("get_sdk_version"):
		return str(_plugin.call("get_sdk_version"))
	return ""


## Returns the resolved singleton name (which candidate matched),
## or empty if the plugin was not found.
func get_singleton_name() -> String:
	return _singleton_name


## Returns the last error code from a failed initialize() call.
## 0 means no error (or success). See _describe_error() for semantics.
func get_last_error_code() -> int:
	return _last_error_code


## Returns the last human-readable error message.
func get_last_error_message() -> String:
	return _last_error_message


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _resolve_plugin() -> Object:
	for name in _SINGLETON_CANDIDATES:
		if Engine.has_singleton(name):
			_singleton_name = name
			return Engine.get_singleton(name)
	return null


func _record_failure(code: int, message: String) -> void:
	_last_error_code = code
	_last_error_message = message
	push_error("%s init failed (code=%d): %s" % [_LOG_TAG, code, message])
	initialization_completed.emit(false, code, message)


func _describe_error(code: int) -> String:
	match code:
		_ERR_INVALID_PARAMETER:
			return "client_token or app_id is empty. Set meta_sdk/* in Project Settings."
		_ERR_UNAVAILABLE:
			return "Activity not available (plugin called before Godot attached the host activity)."
		_:
			return "Unknown error code %d." % code
