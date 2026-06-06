// MetaLogin.h
//
// Facebook Login wrapper. Bridges `FBSDKLoginManager` callbacks to
// Godot signals emitted on the main thread.

#pragma once

#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class MetaLogin {
public:
	static void login(const PackedStringArray &permissions, bool publish);
	static void logout();

	static bool is_logged_in();
	static String get_access_token();
	static String get_user_id();
	static String get_profile_name();
	static String get_profile_picture_url();
	static Dictionary get_profile();

private:
	static void _emit_login_completed(const String &token, const String &user_id, const String &name, const String &picture_url);
	static void _emit_login_failed(const String &error);
	static void _emit_login_cancelled();
};

} // namespace godot
