// MetaSdkPlugin.mm
//
// Implementation of the Godot ↔ Meta SDK bridge. This file is the only
// place that directly calls into the Meta (Facebook) SDK. Sub-modules
// (MetaLogin, MetaShare, MetaEvents, MetaAds, MetaGraph) live in their
// own files but are wired up through this central class so that Godot
// sees a single `MetaSdk` singleton.

#include "MetaSdkPlugin.h"
#include "MetaLogin.h"
#include "MetaShare.h"
#include "MetaEvents.h"
#include "MetaAds.h"
#include "MetaGraph.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Meta SDK
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/main_loop.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/core/memory.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

MetaSdkPlugin *MetaSdkPlugin::singleton = nullptr;

// ---------------------------------------------------------------------------
// Singleton
// ---------------------------------------------------------------------------

MetaSdkPlugin *MetaSdkPlugin::get_singleton() {
	return singleton;
}

MetaSdkPlugin::MetaSdkPlugin() {
	singleton = this;
}

MetaSdkPlugin::~MetaSdkPlugin() {
	if (singleton == this) {
		singleton = nullptr;
	}
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

void MetaSdkPlugin::initialize(const String &app_id, const String &client_token, const String &display_name) {
	if (initialized) {
		UtilityFunctions::push_warning("[Meta SDK] Already initialized.");
		return;
	}

	if (app_id.is_empty()) {
		UtilityFunctions::push_error("[Meta SDK] FacebookAppID is empty. Initialization aborted.");
		return;
	}

	// FBSDKSettings is configured first; FBSDKApplicationDelegate is
	// installed in [FBSDKApplicationDelegate.sharedInstance application:didFinishLaunchingWithOptions:].
	[FBSDKSettings.sharedSettings setAppID:app_id.utf8().get_data()];
	[FBSDKSettings.sharedSettings setClientToken:client_token.utf8().get_data()];
	[FBSDKSettings.sharedSettings setDisplayName:display_name.utf8().get_data()];
	[FBSDKSettings.sharedSettings setAutoLogAppEventsEnabled:YES];
	[FBSDKSettings.sharedSettings setAdvertiserIDCollectionEnabled:NO];
	[FBSDKSettings.sharedSettings setLogLevel:[FBSDKLoggingBehavior FBLogBehaviorWarnings]];

	// Activate App Events.
	[FBSDKAppEvents.shared activateApp];

	initialized = true;
	UtilityFunctions::print("[Meta SDK] Initialized. app_id=", app_id, " display_name=", display_name);
}

void MetaSdkPlugin::set_auto_log_app_events_enabled(bool enabled) {
	[FBSDKSettings.sharedSettings setAutoLogAppEventsEnabled:enabled];
}

void MetaSdkPlugin::set_advertiser_id_collection_enabled(bool enabled) {
	[FBSDKSettings.sharedSettings setAdvertiserIDCollectionEnabled:enabled];
}

void MetaSdkPlugin::set_log_level(int p_level) {
	log_level = p_level;
	FBSDKLoggingBehavior behavior = FBSDKLoggingBehavior.FBLogBehaviorWarnings;
	switch (p_level) {
		case 0: behavior = FBSDKLoggingBehavior.FBLogBehaviorDeveloperErrors; break;
		case 1: behavior = FBSDKLoggingBehavior.FBLogBehaviorDebug; break;
		case 2: behavior = FBSDKLoggingBehavior.FBLogBehaviorInfo; break;
		case 3: behavior = FBSDKLoggingBehavior.FBLogBehaviorWarnings; break;
		case 4: behavior = FBSDKLoggingBehavior.FBLogBehaviorErrors; break;
		default: break;
	}
	[FBSDKSettings.sharedSettings setLogLevel:behavior];
}

int MetaSdkPlugin::get_log_level() const {
	return log_level;
}

bool MetaSdkPlugin::is_initialized() const {
	return initialized;
}

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

void MetaSdkPlugin::login_with_read_permissions(const PackedStringArray &permissions) {
	if (!initialized) {
		UtilityFunctions::push_warning("[Meta SDK] login called before initialize().");
		return;
	}
	MetaLogin::login(permissions, false);
}

void MetaSdkPlugin::login_with_publish_permissions(const PackedStringArray &permissions) {
	if (!initialized) {
		UtilityFunctions::push_warning("[Meta SDK] login called before initialize().");
		return;
	}
	MetaLogin::login(permissions, true);
}

void MetaSdkPlugin::logout() {
	MetaLogin::logout();
}

bool MetaSdkPlugin::is_logged_in() const {
	return MetaLogin::is_logged_in();
}

String MetaSdkPlugin::get_access_token() const {
	return MetaLogin::get_access_token();
}

String MetaSdkPlugin::get_user_id() const {
	return MetaLogin::get_user_id();
}

String MetaSdkPlugin::get_profile_name() const {
	return MetaLogin::get_profile_name();
}

String MetaSdkPlugin::get_profile_picture_url() const {
	return MetaLogin::get_profile_picture_url();
}

Dictionary MetaSdkPlugin::get_profile() const {
	return MetaLogin::get_profile();
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

void MetaSdkPlugin::log_event(const String &event_name, const Dictionary &parameters, double value_to_sum) {
	if (!initialized) {
		return;
	}
	MetaEvents::log_event(event_name, parameters, value_to_sum);
}

void MetaSdkPlugin::log_purchase(double amount, const String &currency, const Dictionary &parameters) {
	if (!initialized) {
		return;
	}
	MetaEvents::log_purchase(amount, currency, parameters);
}

void MetaSdkPlugin::set_user_data(const Dictionary &data) {
	MetaEvents::set_user_data(data);
}

void MetaSdkPlugin::clear_user_data() {
	MetaEvents::clear_user_data();
}

void MetaSdkPlugin::flush() {
	MetaEvents::flush();
}

String MetaSdkPlugin::get_advertiser_id() const {
	// The IDFA (Identifier for Advertisers) is the anonymous id Meta
	// uses to attribute an install to a specific Ads Manager campaign.
	// It is only populated when the user has granted ATT permission.
	return [FBSDKSettings.sharedSettings.advertiserID ?: @""];
}

bool MetaSdkPlugin::is_first_launch() const {
	return [FBSDKAppEvents.shared anonymousID].length > 0 && !MetaEvents::install_event_sent();
}

void MetaSdkPlugin::log_install_event() {
	// Re-emit the install event. Useful for QA / debugging.
	[FBSDKAppEvents.shared logEvent:@"fb_mobile_install"];
	MetaEvents::mark_install_event_sent();
}

// ---------------------------------------------------------------------------
// Share
// ---------------------------------------------------------------------------

void MetaSdkPlugin::share_link(const String &url, const String &quote, const String &mode) {
	if (!initialized) {
		UtilityFunctions::push_warning("[Meta SDK] share_link called before initialize().");
		return;
	}
	MetaShare::share_link(url, quote, mode);
}

void MetaSdkPlugin::share_photo(const String &photo_path, const String &caption, const String &mode) {
	MetaShare::share_photo(photo_path, caption, mode);
}

void MetaSdkPlugin::share_video(const String &video_path, const String &caption, const String &mode) {
	MetaShare::share_video(video_path, caption, mode);
}

bool MetaSdkPlugin::can_share() const {
	return MetaShare::can_share();
}

bool MetaSdkPlugin::can_show_share_dialog() const {
	return MetaShare::can_show_share_dialog();
}

void MetaSdkPlugin::message_share_link(const String &url, const String &quote) {
	MetaShare::message_share_link(url, quote);
}

// ---------------------------------------------------------------------------
// Ads
// ---------------------------------------------------------------------------

void MetaSdkPlugin::load_banner_ad(const String &placement_id, int position) {
	MetaAds::load_banner(placement_id, position);
}

void MetaSdkPlugin::show_banner_ad() {
	MetaAds::show_banner();
}

void MetaSdkPlugin::hide_banner_ad() {
	MetaAds::hide_banner();
}

void MetaSdkPlugin::destroy_banner_ad() {
	MetaAds::destroy_banner();
}

bool MetaSdkPlugin::is_banner_ad_loaded() const {
	return MetaAds::is_banner_loaded();
}

void MetaSdkPlugin::load_interstitial_ad(const String &placement_id) {
	MetaAds::load_interstitial(placement_id);
}

void MetaSdkPlugin::show_interstitial_ad() {
	MetaAds::show_interstitial();
}

bool MetaSdkPlugin::is_interstitial_ad_loaded() {
	return MetaAds::is_interstitial_loaded();
}

void MetaSdkPlugin::load_rewarded_ad(const String &placement_id) {
	MetaAds::load_rewarded(placement_id);
}

void MetaSdkPlugin::show_rewarded_ad() {
	MetaAds::show_rewarded();
}

bool MetaSdkPlugin::is_rewarded_ad_loaded() {
	return MetaAds::is_rewarded_loaded();
}

// ---------------------------------------------------------------------------
// Graph
// ---------------------------------------------------------------------------

void MetaSdkPlugin::graph_request(const String &graph_path, const Dictionary &parameters, const String &http_method, const String &tag) {
	if (!initialized) {
		UtilityFunctions::push_warning("[Meta SDK] graph_request called before initialize().");
		return;
	}
	MetaGraph::request(graph_path, parameters, http_method, tag);
}

// ---------------------------------------------------------------------------
// App Links
// ---------------------------------------------------------------------------

bool MetaSdkPlugin::handle_open_url(const String &url) {
	NSString *nsurl = [NSString stringWithUTF8String:url.utf8().get_data()];
	NSURL *u = [NSURL URLWithString:nsurl];
	if (u == nil) {
		return false;
	}
	[[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication] openURL:u sourceApplication:@"com.apple.mobilesafari" annotation:nil];
	return true;
}

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------

String MetaSdkPlugin::get_sdk_version() const {
	return [FBSDKSettings.sharedSettings.sdkVersion];
}

String MetaSdkPlugin::get_ios_version() const {
	return [[UIDevice currentDevice] systemVersion];
}

String MetaSdkPlugin::get_device_model() const {
	return [[UIDevice currentDevice] model];
}

// ---------------------------------------------------------------------------
// Thread marshalling
// ---------------------------------------------------------------------------

void MetaSdkPlugin::_dispatch_to_main_thread(const Callable &cb) {
	// Always bounce onto the main thread; Meta SDK callbacks often come
	// from background queues.
	dispatch_async(dispatch_get_main_queue(), ^{
		Engine *engine = Engine::get_singleton();
		if (engine == nullptr) {
			return;
		}
		MainLoop *ml = engine->get_main_loop();
		if (ml == nullptr) {
			return;
		}
		SceneTree *tree = Object::cast_to<SceneTree>(ml);
		if (tree == nullptr) {
			return;
		}
		tree->call_deferred("call_group", "MainLoop", "callv", cb);
	});
}

// ---------------------------------------------------------------------------
// Method bindings
// ---------------------------------------------------------------------------

void MetaSdkPlugin::_bind_methods() {
	// Lifecycle
	ClassDB::bind_method(D_METHOD("initialize", "app_id", "client_token", "display_name"), &MetaSdkPlugin::initialize);
	ClassDB::bind_method(D_METHOD("set_auto_log_app_events_enabled", "enabled"), &MetaSdkPlugin::set_auto_log_app_events_enabled);
	ClassDB::bind_method(D_METHOD("set_advertiser_id_collection_enabled", "enabled"), &MetaSdkPlugin::set_advertiser_id_collection_enabled);
	ClassDB::bind_method(D_METHOD("set_log_level", "level"), &MetaSdkPlugin::set_log_level);
	ClassDB::bind_method(D_METHOD("get_log_level"), &MetaSdkPlugin::get_log_level);
	ClassDB::bind_method(D_METHOD("is_initialized"), &MetaSdkPlugin::is_initialized);

	// Login
	ClassDB::bind_method(D_METHOD("login_with_read_permissions", "permissions"), &MetaSdkPlugin::login_with_read_permissions);
	ClassDB::bind_method(D_METHOD("login_with_publish_permissions", "permissions"), &MetaSdkPlugin::login_with_publish_permissions);
	ClassDB::bind_method(D_METHOD("logout"), &MetaSdkPlugin::logout);
	ClassDB::bind_method(D_METHOD("is_logged_in"), &MetaSdkPlugin::is_logged_in);
	ClassDB::bind_method(D_METHOD("get_access_token"), &MetaSdkPlugin::get_access_token);
	ClassDB::bind_method(D_METHOD("get_user_id"), &MetaSdkPlugin::get_user_id);
	ClassDB::bind_method(D_METHOD("get_profile_name"), &MetaSdkPlugin::get_profile_name);
	ClassDB::bind_method(D_METHOD("get_profile_picture_url"), &MetaSdkPlugin::get_profile_picture_url);
	ClassDB::bind_method(D_METHOD("get_profile"), &MetaSdkPlugin::get_profile);

	// Events
	ClassDB::bind_method(D_METHOD("log_event", "event_name", "parameters", "value_to_sum"), &MetaSdkPlugin::log_event, DEFVAL(Dictionary()), DEFVAL(0.0));
	ClassDB::bind_method(D_METHOD("log_purchase", "amount", "currency", "parameters"), &MetaSdkPlugin::log_purchase, DEFVAL(Dictionary()));
	ClassDB::bind_method(D_METHOD("set_user_data", "data"), &MetaSdkPlugin::set_user_data);
	ClassDB::bind_method(D_METHOD("clear_user_data"), &MetaSdkPlugin::clear_user_data);
	ClassDB::bind_method(D_METHOD("flush"), &MetaSdkPlugin::flush);
	ClassDB::bind_method(D_METHOD("get_advertiser_id"), &MetaSdkPlugin::get_advertiser_id);
	ClassDB::bind_method(D_METHOD("is_first_launch"), &MetaSdkPlugin::is_first_launch);
	ClassDB::bind_method(D_METHOD("log_install_event"), &MetaSdkPlugin::log_install_event);

	// Share
	ClassDB::bind_method(D_METHOD("share_link", "url", "quote", "mode"), &MetaSdkPlugin::share_link, DEFVAL("automatic"), DEFVAL(""));
	ClassDB::bind_method(D_METHOD("share_photo", "photo_path", "caption", "mode"), &MetaSdkPlugin::share_photo, DEFVAL("automatic"), DEFVAL(""));
	ClassDB::bind_method(D_METHOD("share_video", "video_path", "caption", "mode"), &MetaSdkPlugin::share_video, DEFVAL("automatic"), DEFVAL(""));
	ClassDB::bind_method(D_METHOD("can_share"), &MetaSdkPlugin::can_share);
	ClassDB::bind_method(D_METHOD("can_show_share_dialog"), &MetaSdkPlugin::can_show_share_dialog);
	ClassDB::bind_method(D_METHOD("message_share_link", "url", "quote"), &MetaSdkPlugin::message_share_link, DEFVAL(""));

	// Ads
	ClassDB::bind_method(D_METHOD("load_banner_ad", "placement_id", "position"), &MetaSdkPlugin::load_banner_ad, DEFVAL(0));
	ClassDB::bind_method(D_METHOD("show_banner_ad"), &MetaSdkPlugin::show_banner_ad);
	ClassDB::bind_method(D_METHOD("hide_banner_ad"), &MetaSdkPlugin::hide_banner_ad);
	ClassDB::bind_method(D_METHOD("destroy_banner_ad"), &MetaSdkPlugin::destroy_banner_ad);
	ClassDB::bind_method(D_METHOD("is_banner_ad_loaded"), &MetaSdkPlugin::is_banner_ad_loaded);
	ClassDB::bind_method(D_METHOD("load_interstitial_ad", "placement_id"), &MetaSdkPlugin::load_interstitial_ad);
	ClassDB::bind_method(D_METHOD("show_interstitial_ad"), &MetaSdkPlugin::show_interstitial_ad);
	ClassDB::bind_method(D_METHOD("is_interstitial_ad_loaded"), &MetaSdkPlugin::is_interstitial_ad_loaded);
	ClassDB::bind_method(D_METHOD("load_rewarded_ad", "placement_id"), &MetaSdkPlugin::load_rewarded_ad);
	ClassDB::bind_method(D_METHOD("show_rewarded_ad"), &MetaSdkPlugin::show_rewarded_ad);
	ClassDB::bind_method(D_METHOD("is_rewarded_ad_loaded"), &MetaSdkPlugin::is_rewarded_ad_loaded);

	// Graph
	ClassDB::bind_method(D_METHOD("graph_request", "graph_path", "parameters", "http_method", "tag"), &MetaSdkPlugin::graph_request, DEFVAL(Dictionary()), DEFVAL("GET"), DEFVAL(""));

	// App Links
	ClassDB::bind_method(D_METHOD("handle_open_url", "url"), &MetaSdkPlugin::handle_open_url);

	// Misc
	ClassDB::bind_method(D_METHOD("get_sdk_version"), &MetaSdkPlugin::get_sdk_version);
	ClassDB::bind_method(D_METHOD("get_ios_version"), &MetaSdkPlugin::get_ios_version);
	ClassDB::bind_method(D_METHOD("get_device_model"), &MetaSdkPlugin::get_device_model);
}
