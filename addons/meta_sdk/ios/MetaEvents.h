// MetaEvents.h
//
// Facebook App Events (analytics) wrapper.

#pragma once

#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class MetaEvents {
public:
	static void log_event(const String &event_name, const Dictionary &parameters, double value_to_sum);
	static void log_purchase(double amount, const String &currency, const Dictionary &parameters);
	static void set_user_data(const Dictionary &data);
	static void clear_user_data();
	static void flush();

	// True once we've explicitly recorded an install event this launch.
	// Used by `MetaSdkPlugin::is_first_launch` and `log_install_event`.
	static bool install_event_sent();
	static void mark_install_event_sent();
};

} // namespace godot
