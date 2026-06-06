// register_types.h
//
// GDExtension entry-point declarations. The functions below are
// referenced by name from the `.gdextension` config file.

#pragma once

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void initialize_meta_sdk_module(ModuleInitializationLevel p_level);
void uninitialize_meta_sdk_module(ModuleInitializationLevel p_level);
