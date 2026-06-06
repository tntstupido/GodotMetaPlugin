// MetaShare.h
//
// Facebook Share dialog wrapper.

#pragma once

#include <godot_cpp/variant/string.hpp>

namespace godot {

class MetaShare {
public:
	static void share_link(const String &url, const String &quote, const String &mode);
	static void share_photo(const String &photo_path, const String &caption, const String &mode);
	static void share_video(const String &video_path, const String &caption, const String &mode);
	static bool can_share();
	static bool can_show_share_dialog();
	static void message_share_link(const String &url, const String &quote);
};

} // namespace godot
