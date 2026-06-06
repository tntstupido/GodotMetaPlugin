// register_types.mm
//
// GDExtension entry-point implementations. Registers `MetaSdkPlugin` as
// an engine singleton (`MetaSdk` from GDScript) and binds its signals.

#include "register_types.h"
#include "MetaSdkPlugin.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

static MetaSdkPlugin *_meta_sdk = nullptr;

void initialize_meta_sdk_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(MetaSdkPlugin);
	_meta_sdk = memnew(MetaSdkPlugin);
	Engine::get_singleton()->register_singleton("MetaSdk", _meta_sdk);

	// Login signals
	ADD_SIGNAL(MethodInfo("login_completed",
		PropertyInfo(Variant::STRING, "access_token"),
		PropertyInfo(Variant::STRING, "user_id"),
		PropertyInfo(Variant::STRING, "name"),
		PropertyInfo(Variant::STRING, "picture_url")));
	ADD_SIGNAL(MethodInfo("login_failed", PropertyInfo(Variant::STRING, "error")));
	ADD_SIGNAL(MethodInfo("login_cancelled"));

	// Share signals
	ADD_SIGNAL(MethodInfo("share_opened", PropertyInfo(Variant::STRING, "type"), PropertyInfo(Variant::STRING, "payload")));
	ADD_SIGNAL(MethodInfo("share_completed", PropertyInfo(Variant::STRING, "type")));
	ADD_SIGNAL(MethodInfo("share_failed", PropertyInfo(Variant::STRING, "type"), PropertyInfo(Variant::STRING, "error")));

	// Events signals
	ADD_SIGNAL(MethodInfo("event_logged", PropertyInfo(Variant::STRING, "event_name")));

	// Ads signals - banner
	ADD_SIGNAL(MethodInfo("banner_ad_loaded", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("banner_ad_failed", PropertyInfo(Variant::STRING, "placement_id"), PropertyInfo(Variant::STRING, "error")));
	ADD_SIGNAL(MethodInfo("banner_ad_clicked", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("banner_ad_clicked_finished", PropertyInfo(Variant::STRING, "placement_id")));

	// Ads signals - interstitial
	ADD_SIGNAL(MethodInfo("interstitial_ad_loaded", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("interstitial_ad_failed", PropertyInfo(Variant::STRING, "placement_id"), PropertyInfo(Variant::STRING, "error")));
	ADD_SIGNAL(MethodInfo("interstitial_ad_impression", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("interstitial_ad_clicked", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("interstitial_ad_closing", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("interstitial_ad_closed", PropertyInfo(Variant::STRING, "placement_id")));

	// Ads signals - rewarded
	ADD_SIGNAL(MethodInfo("rewarded_ad_loaded", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_failed", PropertyInfo(Variant::STRING, "placement_id"), PropertyInfo(Variant::STRING, "error")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_impression", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_clicked", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_completed", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_closing", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_closed", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_server_reward", PropertyInfo(Variant::STRING, "placement_id")));
	ADD_SIGNAL(MethodInfo("rewarded_ad_server_reward_failed", PropertyInfo(Variant::STRING, "placement_id")));

	// Graph signals
	ADD_SIGNAL(MethodInfo("graph_response",
		PropertyInfo(Variant::STRING, "tag"),
		PropertyInfo(Variant::DICTIONARY, "response")));

	// App Links
	ADD_SIGNAL(MethodInfo("url_opened", PropertyInfo(Variant::STRING, "url")));

	UtilityFunctions::print("[Meta SDK] Native module initialized.");
}

void uninitialize_meta_sdk_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	if (_meta_sdk != nullptr) {
		Engine::get_singleton()->unregister_singleton("MetaSdk");
		memdelete(_meta_sdk);
		_meta_sdk = nullptr;
	}
}

extern "C" {

GDExtensionBool GDE_EXPORT godot_meta_sdk_library_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		const GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
	init_obj.register_initializer(initialize_meta_sdk_module);
	init_obj.register_terminator(uninitialize_meta_sdk_module);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
	return init_obj.init();
}

} // extern "C"
