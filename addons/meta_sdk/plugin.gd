@tool
extends EditorPlugin

## Editor entry point for the Meta SDK plugin.
##
## Responsibilities:
##   * Register Project Settings (app id, client token, ...).
##   * Register the `MetaSdk` autoload (the GDScript singleton).
##   * Register an `EditorExportPlugin` that injects Meta SDK pods,
##     frameworks, plist keys and link flags into iOS exports.

const _AUTOLOAD_NAME := "MetaSdk"
const _AUTOLOAD_PATH := "res://addons/meta_sdk/meta_sdk.gd"

const _EXPORT_PLUGIN := preload("res://addons/meta_sdk/export_plugin.gd")

var _export_plugin_instance: EditorExportPlugin = null


func _enter_tree() -> void:
	_register_project_settings()
	_ensure_autoload()
	_export_plugin_instance = _EXPORT_PLUGIN.new()
	add_export_plugin(_export_plugin_instance)


func _exit_tree() -> void:
	if _export_plugin_instance != null:
		remove_export_plugin(_export_plugin_instance)
		_export_plugin_instance = null
	_unregister_project_settings()


# --------------------------------------------------------------------------
# Project Settings
# --------------------------------------------------------------------------

const _SETTINGS := [
	{
		"name": "meta_sdk/app_id",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "e.g. 1234567890123456",
		"default": "",
	},
	{
		"name": "meta_sdk/client_token",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "Required for some SDK features (e.g. Graph API with app token)",
		"default": "",
	},
	{
		"name": "meta_sdk/display_name",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"default": "",
	},
	{
		"name": "meta_sdk/auto_log_app_events",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"default": true,
	},
	{
		"name": "meta_sdk/advertiser_id_collection",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"default": false,
	},
	{
		"name": "meta_sdk/facebook_domain",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "e.g. mycoolgame.com (must match App Dashboard)",
		"default": "",
	},
	{
		"name": "meta_sdk/url_scheme_suffix",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
		"hint_string": "Optional. Allows multiple apps to share one Facebook App ID.",
		"default": "",
	},
	{
		"name": "meta_sdk/log_level",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "None,Debug,Info,Warning,Error",
		"default": "Warning",
	},
]


func _register_project_settings() -> void:
	for s in _SETTINGS:
		var key: String = s["name"]
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, s["default"])
		ProjectSettings.set_initial_value(key, s["default"])
		ProjectSettings.add_property_info({
			"name": key,
			"type": s["type"],
			"hint": s["hint"],
			"hint_string": s["hint_string"],
		})
		ProjectSettings.set_as_basic(key, true)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning("[Meta SDK] Could not save ProjectSettings (err=%d)." % err)


func _unregister_project_settings() -> void:
	# We don't delete the settings, so values persist if the plugin is
	# re-enabled later. We just clear them from the basic group.
	for s in _SETTINGS:
		ProjectSettings.set_as_basic(s["name"], false)


# --------------------------------------------------------------------------
# Autoload
# --------------------------------------------------------------------------

func _ensure_autoload() -> void:
	var existing: String = ProjectSettings.get_setting("autoload/" + _AUTOLOAD_NAME, "")
	if existing == _AUTOLOAD_PATH:
		return
	ProjectSettings.set_setting("autoload/" + _AUTOLOAD_NAME, _AUTOLOAD_PATH)
	# Make it a real autoload singleton (the value should not be marked
	# as a global-class path but as a project autoload).
	ProjectSettings.set_initial_value("autoload/" + _AUTOLOAD_NAME, _AUTOLOAD_PATH)
	var err := ProjectSettings.save()
	if err != OK:
		push_warning("[Meta SDK] Could not register autoload (err=%d)." % err)
	else:
		print_rich("[color=#1877F2][b]Meta SDK[/b][/color] autoload registered as '%s'." % _AUTOLOAD_NAME)
