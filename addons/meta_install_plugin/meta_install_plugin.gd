@tool
extends EditorPlugin

const PLUGIN_NAME := "MetaInstallPlugin"
const META_SDK_VERSION := "18.0.3"
const DEFAULT_DISPLAY_NAME := "Die Laughing"

var export_plugin: MetaInstallExportPlugin


func _enter_tree() -> void:
	export_plugin = MetaInstallExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class MetaInstallExportPlugin extends EditorExportPlugin:
	func _get_name() -> String:
		return PLUGIN_NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray(["res://addons/meta_install_plugin/MetaInstallPlugin-debug.aar"])
		return PackedStringArray(["res://addons/meta_install_plugin/MetaInstallPlugin-release.aar"])

	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"com.facebook.android:facebook-core:%s" % META_SDK_VERSION
		])

	func _get_android_maven_repos(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"https://repo1.maven.org/maven2/"
		])

	func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		var app_id := _read_setting("meta_sdk/app_id")
		var client_token := _read_setting("meta_sdk/client_token")
		var display_name := _read_setting("meta_sdk/display_name")
		var advertiser_id_collection := bool(ProjectSettings.get_setting("meta_sdk/advertiser_id_collection", true))

		if app_id.is_empty():
			push_warning("[MetaInstallPlugin] meta_sdk/app_id is empty; Android manifest metadata will be incomplete.")

		if display_name.is_empty():
			display_name = DEFAULT_DISPLAY_NAME

		return (
			'\t\t<meta-data\n'
			+ '\t\t\tandroid:name="com.facebook.sdk.ApplicationId"\n'
			+ '\t\t\tandroid:value="%s" />\n'
			+ '\t\t<meta-data\n'
			+ '\t\t\tandroid:name="com.facebook.sdk.ClientToken"\n'
			+ '\t\t\tandroid:value="%s" />\n'
			+ '\t\t<meta-data\n'
			+ '\t\t\tandroid:name="com.facebook.sdk.ApplicationName"\n'
			+ '\t\t\tandroid:value="%s" />\n'
			+ '\t\t<meta-data\n'
			+ '\t\t\tandroid:name="com.facebook.sdk.AutoInitEnabled"\n'
			+ '\t\t\tandroid:value="false" />\n'
			+ '\t\t<meta-data\n'
			+ '\t\t\tandroid:name="com.facebook.sdk.AutoLogAppEventsEnabled"\n'
			+ '\t\t\tandroid:value="true" />\n'
			+ '\t\t<meta-data\n'
			+ '\t\t\tandroid:name="com.facebook.sdk.AdvertiserIDCollectionEnabled"\n'
			+ '\t\t\tandroid:value="%s" />\n'
		) % [
			_normalize_android_app_id(app_id).xml_escape(),
			client_token.xml_escape(),
			display_name.xml_escape(),
			str(advertiser_id_collection).to_lower()
		]

	func _get_android_permissions(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"android.permission.INTERNET",
			"android.permission.ACCESS_NETWORK_STATE",
			"com.google.android.gms.permission.AD_ID"
		])

	func _read_setting(setting_name: String) -> String:
		if not ProjectSettings.has_setting(setting_name):
			return ""
		return str(ProjectSettings.get_setting(setting_name, "")).strip_edges()

	func _normalize_android_app_id(app_id: String) -> String:
		if app_id.begins_with("fb"):
			return app_id
		return "fb%s" % app_id
