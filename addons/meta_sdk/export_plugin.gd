@tool
extends EditorExportPlugin

## Injects the Meta (Facebook) SDK into iOS exports.
##
## * Adds the podspec that pulls in FBSDKCoreKit, FBSDKLoginKit,
##   FBSDKShareKit and FBAudienceNetwork.
## * Adds the iOS frameworks and linker flags required by the SDK.
## * Adds the URL scheme, plist entries and LSApplicationQueriesSchemes
##   required by Facebook Login & Share.
## * Copies our static GDExtension framework to the export.

const _PLUGIN_NAME := "meta_sdk"
const _POD_NAME := "GodotMetaSdk"
const _GDE_FRAMEWORK_NAME := "GodotMetaSdk"

# Files we always copy to the iOS plugin folder, regardless of options.
const _PLUGIN_SOURCE_FILES := [
	"res://addons/meta_sdk/ios/MetaSdkPlugin.h",
	"res://addons/meta_sdk/ios/MetaSdkPlugin.mm",
	"res://addons/meta_sdk/ios/MetaLogin.h",
	"res://addons/meta_sdk/ios/MetaLogin.mm",
	"res://addons/meta_sdk/ios/MetaShare.h",
	"res://addons/meta_sdk/ios/MetaShare.mm",
	"res://addons/meta_sdk/ios/MetaEvents.h",
	"res://addons/meta_sdk/ios/MetaEvents.mm",
	"res://addons/meta_sdk/ios/MetaAds.h",
	"res://addons/meta_sdk/ios/MetaAds.mm",
	"res://addons/meta_sdk/ios/MetaGraph.h",
	"res://addons/meta_sdk/ios/MetaGraph.mm",
	"res://addons/meta_sdk/ios/meta_sdk.podspec",
	"res://addons/meta_sdk/ios/Podfile",
]


# ---------------------------------------------------------------------------
# Options exposed in the iOS export dialog
# ---------------------------------------------------------------------------

func _get_name() -> String:
	return "MetaSDK"


func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
	if platform is not EditorExportPlatformIOS:
		return []
	return [
		{
			"option": {
				"name": "meta_sdk/enable_login",
				"type": TYPE_BOOL,
			},
			"default_value": true,
		},
		{
			"option": {
				"name": "meta_sdk/enable_share",
				"type": TYPE_BOOL,
			},
			"default_value": true,
		},
		{
			"option": {
				"name": "meta_sdk/enable_ads",
				"type": TYPE_BOOL,
			},
			"default_value": true,
		},
		{
			"option": {
				"name": "meta_sdk/enable_graph",
				"type": TYPE_BOOL,
			},
			"default_value": true,
		},
		{
			"option": {
				"name": "meta_sdk/enable_codeless_events",
				"type": TYPE_BOOL,
			},
			"default_value": true,
		},
	]


# ---------------------------------------------------------------------------
# Export pipeline
# ---------------------------------------------------------------------------

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	# We only care about iOS exports.
	var is_ios := false
	for f in features:
		if f == "ios":
			is_ios = true
			break
	if not is_ios:
		return

	# 1) Inject our static GDExtension framework
	var archs := _get_active_architectures(features)
	for arch in archs:
		var framework_path := "res://addons/meta_sdk/ios/bin/%s.%s.%s.framework" % [
			_GDE_FRAMEWORK_NAME, arch, "release" if not is_debug else "debug",
		]
		if FileAccess.file_exists(framework_path):
			add_ios_framework(_GDE_FRAMEWORK_NAME + ".framework", framework_path)
		else:
			# Fall back to the prebuilt bundled binary directory.
			add_ios_framework(_GDE_FRAMEWORK_NAME + ".framework", _gdextension_framework_dir())

	# 2) Add the Meta SDK podspec (pulls in FBSDKCoreKit + friends).
	add_ios_podspec("res://addons/meta_sdk/ios/meta_sdk.podspec", true)

	# 3) Required iOS frameworks / linker flags.
	_add_required_frameworks()
	_add_required_linker_flags()

	# 4) Required plist entries (Facebook App ID, URL scheme, etc.).
	_add_required_plist_entries()

	# 5) Copy our Obj-C++ plugin sources so they get compiled in the
	#    generated Xcode project. (Optional - users can build the
	#    static library separately if they prefer.)
	for src in _PLUGIN_SOURCE_FILES:
		if FileAccess.file_exists(src):
			add_file(src, src.remove_prefix("res://"), false)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _get_active_architectures(features: PackedStringArray) -> PackedStringArray:
	# We default to arm64 device + arm64 simulator. Godot 4.5.1 lets
	# users pick simulator/device, but for the framework copy we try to
	# be safe and ship the union.
	var result: PackedStringArray = []
	var has_arm64 := false
	var has_x86_64 := false
	for f in features:
		match f:
			"arm64": has_arm64 = true
			"x86_64": has_x86_64 = true
	if has_arm64:
		result.append("arm64")
	if has_x86_64:
		result.append("x86_64")
	if result.is_empty():
		result.append("arm64")
	return result


func _gdextension_framework_dir() -> String:
	return "res://addons/meta_sdk/ios/bin/GodotMetaSdk.framework"


func _add_required_frameworks() -> void:
	for fw in [
		"SafariServices.framework",
		"Security.framework",
		"SystemConfiguration.framework",
		"WebKit.framework",
		"CoreGraphics.framework",
		"UIKit.framework",
		"Foundation.framework",
		"StoreKit.framework",
		"AdServices.framework",
		"AppTrackingTransparency.framework",
	]:
		add_ios_framework(fw)


func _add_required_linker_flags() -> void:
	# -ObjC is required so that the static libraries' Objective-C
	# categories are linked into the final binary.
	add_ios_linker_flags("-ObjC")


func _add_required_plist_entries() -> void:
	# FacebookAppID
	var app_id: String = str(ProjectSettings.get_setting("meta_sdk/app_id", ""))
	if app_id.is_empty():
		push_warning("[Meta SDK] meta_sdk/app_id is empty. Facebook Login and most SDK features will not work.")
	add_ios_plist_content("""
<key>FacebookAppID</key>
<string>%s</string>
<key>FacebookClientToken</key>
<string>%s</string>
<key>FacebookDisplayName</key>
<string>%s</string>
<key>FacebookAutoLogAppEventsEnabled</key>
<%s/>
<key>FacebookAdvertiserIDCollectionEnabled</key>
<%s/>
""" % [
		_xml_escape(app_id),
		_xml_escape(str(ProjectSettings.get_setting("meta_sdk/client_token", ""))),
		_xml_escape(str(ProjectSettings.get_setting("meta_sdk/display_name", ""))),
		"true" if bool(ProjectSettings.get_setting("meta_sdk/auto_log_app_events", true)) else "false",
		"true" if bool(ProjectSettings.get_setting("meta_sdk/advertiser_id_collection", false)) else "false",
	])

	# URL scheme
	var scheme_suffix: String = str(ProjectSettings.get_setting("meta_sdk/url_scheme_suffix", ""))
	var url_scheme_id: String = app_id
	if not scheme_suffix.is_empty():
		url_scheme_id = app_id + scheme_suffix
	if not url_scheme_id.is_empty():
		add_ios_plist_content("""
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.facebook.ios</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fb%s</string>
        </array>
    </dict>
</array>
""" % _xml_escape(url_scheme_id))

	# LSApplicationQueriesSchemes (required by Facebook Share)
	add_ios_plist_content("""
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-api</string>
    <string>fbauth2</string>
    <string>fbshareextension</string>
</array>
""")

	# Facebook Domain (Universal Links)
	var domain: String = str(ProjectSettings.get_setting("meta_sdk/facebook_domain", ""))
	if not domain.is_empty():
		add_ios_plist_content("""
<key>FacebookDomain</key>
<string>%s</string>
""" % _xml_escape(domain))

	# App Tracking Transparency (required for Meta Ads Manager install
	# attribution on iOS 14+). Apple requires this string or the app
	# will crash the first time `[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:]`
	# is called.
	add_ios_plist_content("""
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used by Meta (Facebook) to deliver and measure personalised advertising, including install attribution.</string>
""")


func _xml_escape(s: String) -> String:
	# Build the XML entity strings from a base character so that the
	# actual literal entity survives the editor's escape handling.
	var amp: String = String.chr(38)
	var lt_entity: String = amp + "lt;"
	var gt_entity: String = amp + "gt;"
	var quot_entity: String = amp + "quot;"
	var amp_entity: String = amp + "amp;"
	var result := s
	result = result.replace(amp, amp_entity)
	result = result.replace(String.chr(60), lt_entity)
	result = result.replace(String.chr(62), gt_entity)
	result = result.replace(String.chr(34), quot_entity)
	return result
