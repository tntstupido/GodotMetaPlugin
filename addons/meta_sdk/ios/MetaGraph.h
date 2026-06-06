// MetaGraph.h
//
// Facebook Graph API wrapper.

#pragma once

#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class MetaGraph {
public:
	static void request(const String &graph_path, const Dictionary &parameters, const String &http_method, const String &tag);
};

} // namespace godot
