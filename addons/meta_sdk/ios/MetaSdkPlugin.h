// MetaSdkPlugin.h
//
// Main entry point of the Godot ↔ Meta SDK bridge on iOS.
//
// This class is registered as a Godot singleton (`MetaSdk` from GDScript)
// via the GDExtension initialization callbacks in `register_types.mm`.
// All public methods are bound to Godot using `ClassDB::bind_method` and
// become available from GDScript.

#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/window.hpp>
#include <godot_cpp/core/binder_common.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class MetaSdkPlugin : public Object {
	GDCLASS(MetaSdkPlugin, Object)

public:
	static MetaSdkPlugin *get_singleton();

	// -----------------------------------------------------------------
	// Lifecycle
	// -----------------------------------------------------------------
	void initialize(const String &app_id, const String &client_token, const String &display_name);
	void set_auto_log_app_events_enabled(bool enabled);
	void set_advertiser_id_collection_enabled(bool enabled);
	void set_log_level(int p_level);
	int get_log_level() const;
	bool is_initialized() const;

	// -----------------------------------------------------------------
	// Login (delegated to MetaLogin)
	// -----------------------------------------------------------------
	void login_with_read_permissions(const PackedStringArray &permissions);
	void login_with_publish_permissions(const PackedStringArray &permissions);
	void logout();
	bool is_logged_in() const;
	String get_access_token() const;
	String get_user_id() const;
	String get_profile_name() const;
	String get_profile_picture_url() const;
	Dictionary get_profile() const;

	// -----------------------------------------------------------------
	// Events (delegated to MetaEvents)
	// -----------------------------------------------------------------
	void log_event(const String &event_name, const Dictionary &parameters, double value_to_sum);
	void log_purchase(double amount, const String &currency, const Dictionary &parameters);
	void set_user_data(const Dictionary &data);
	void clear_user_data();
	void flush();
	// Returns the anonymous id (IDFA-derived, empty if ATT denied) used
	// to attribute installs to Meta Ads Manager campaigns.
	String get_advertiser_id() const;
	// Returns true if the Facebook SDK has recorded an install for this
	// device. Useful for the "is this the first launch?" branch.
	bool is_first_launch() const;
	// Forces a re-send of the install event. Call this from a "Replay
	// install" debug menu when you want to verify the wiring in the
	// Events Manager / Ads Manager dashboards.
	void log_install_event();


	// -----------------------------------------------------------------
	// Share (delegated to MetaShare)
	// -----------------------------------------------------------------
	void share_link(const String &url, const String &quote, const String &mode);
	void share_photo(const String &photo_path, const String &caption, const String &mode);
	void share_video(const String &video_path, const String &caption, const String &mode);
	bool can_share() const;
	bool can_show_share_dialog() const;
	void message_share_link(const String &url, const String &quote);

	// -----------------------------------------------------------------
	// Ads (delegated to MetaAds)
	// -----------------------------------------------------------------
	void load_banner_ad(const String &placement_id, int position);
	void show_banner_ad();
	void hide_banner_ad();
	void destroy_banner_ad();
	bool is_banner_ad_loaded() const;

	void load_interstitial_ad(const String &placement_id);
	void show_interstitial_ad();
	bool is_interstitial_ad_loaded();

	void load_rewarded_ad(const String &placement_id);
	void show_rewarded_ad();
	bool is_rewarded_ad_loaded();

	// -----------------------------------------------------------------
	// Graph (delegated to MetaGraph)
	// -----------------------------------------------------------------
	void graph_request(const String &graph_path, const Dictionary &parameters, const String &http_method, const String &tag);

	// -----------------------------------------------------------------
	// App Links (Universal Links / URL scheme)
	// -----------------------------------------------------------------
	bool handle_open_url(const String &url);

	// -----------------------------------------------------------------
	// Misc
	// -----------------------------------------------------------------
	String get_sdk_version() const;
	String get_ios_version() const;
	String get_device_model() const;

	MetaSdkPlugin();
	~MetaSdkPlugin();

protected:
	static void _bind_methods();

private:
	static MetaSdkPlugin *singleton;
	bool initialized = false;
	int log_level = 3; // 0=developer, 1=debug, 2=info, 3=warning, 4=error

	// Internal helpers used by the Obj-C++ wrapper classes to push
	// callbacks back into the Godot main thread.
	void _dispatch_to_main_thread(const Callable &cb);
};

} // namespace godot
