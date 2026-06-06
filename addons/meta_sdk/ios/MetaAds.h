// MetaAds.h
//
// Facebook Audience Network ads wrapper (banner, interstitial, rewarded).

#pragma once

#include <godot_cpp/variant/string.hpp>

namespace godot {

class MetaAds {
public:
	// Banner
	static void load_banner(const String &placement_id, int position);
	static void show_banner();
	static void hide_banner();
	static void destroy_banner();
	static bool is_banner_loaded();

	// Interstitial
	static void load_interstitial(const String &placement_id);
	static void show_interstitial();
	static bool is_interstitial_loaded();

	// Rewarded
	static void load_rewarded(const String &placement_id);
	static void show_rewarded();
	static bool is_rewarded_loaded();
};

} // namespace godot
