// MetaEvents.mm
//
// Implementation of the Facebook App Events bridge.

#include "MetaEvents.h"
#include "MetaSdkPlugin.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKAppEvents.h>

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

static NSDictionary<NSString *, id> *_dictionary_from_godot(const Dictionary &d) {
	NSMutableDictionary<NSString *, id> *out = [NSMutableDictionary dictionary];
	Array keys = d.keys();
	for (int i = 0; i < keys.size(); i++) {
		String k = keys[i];
		Variant v = d[k];
		// We only ship scalar / string values; everything else is
		// converted to a string for safety.
		NSString *key = [NSString stringWithUTF8String:k.utf8().get_data()];
		switch (v.get_type()) {
			case Variant::BOOL: {
				bool b = v;
				out[key] = @(b);
				break;
			}
			case Variant::INT: {
				int64_t i = v;
				out[key] = @(i);
				break;
			}
			case Variant::FLOAT: {
				double d = v;
				out[key] = @(d);
				break;
			}
			default: {
				String s = v;
				out[key] = [NSString stringWithUTF8String:s.utf8().get_data()];
				break;
			}
		}
	}
	return out;
}

namespace godot {

void MetaEvents::log_event(const String &event_name, const Dictionary &parameters, double value_to_sum) {
	NSString *name = [NSString stringWithUTF8String:event_name.utf8().get_data()];
	NSDictionary<NSString *, id> *params = _dictionary_from_godot(parameters);
	if (value_to_sum != 0.0) {
		[FBSDKAppEvents.shared logEvent:name
							 valueToSum:value_to_sum
							   parameters:params
								  accessToken:nil];
	} else {
		[FBSDKAppEvents.shared logEvent:name
							   parameters:params
								  accessToken:nil];
	}
}

void MetaEvents::log_purchase(double amount, const String &currency, const Dictionary &parameters) {
	NSString *cur = [NSString stringWithUTF8String:currency.utf8().get_data()];
	NSDictionary<NSString *, id> *params = _dictionary_from_godot(parameters);
	[FBSDKAppEvents.shared logPurchase:amount
							   currency:cur
							 parameters:params
						   accessToken:nil];
}

void MetaEvents::set_user_data(const Dictionary &data) {
	// Map common keys to the canonical FBSDKAppEvents fields.
	NSDictionary<NSString *, id> *params = _dictionary_from_godot(data);
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeEmail];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeFirstName];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeLastName];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypePhone];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeDateOfBirth];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeGender];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeCity];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeState];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeZip];
	[FBSDKAppEvents.shared setUserData:params forType:FBSDKAppEventUserDataTypeCountry];
}

void MetaEvents::clear_user_data() {
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeEmail];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeFirstName];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeLastName];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypePhone];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeDateOfBirth];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeGender];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeCity];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeState];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeZip];
	[FBSDKAppEvents.shared clearUserDataForType:FBSDKAppEventUserDataTypeCountry];
}

void MetaEvents::flush() {
	[FBSDKAppEvents.shared flush];
}

static bool g_install_event_sent = false;

bool MetaEvents::install_event_sent() {
	return g_install_event_sent;
}

void MetaEvents::mark_install_event_sent() {
	g_install_event_sent = true;
}

} // namespace godot
