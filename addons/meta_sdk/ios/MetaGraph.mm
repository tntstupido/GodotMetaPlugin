// MetaGraph.mm
//
// Implementation of the Facebook Graph API bridge. We use the GraphRequest
// builder so that authentication, error handling and parameter formatting
// match what every other Meta SDK caller expects.

#include "MetaGraph.h"
#include "MetaSdkPlugin.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

namespace godot {

static NSDictionary<NSString *, id> *_dict_from_godot(const Dictionary &d) {
	NSMutableDictionary<NSString *, id> *out = [NSMutableDictionary dictionary];
	Array keys = d.keys();
	for (int i = 0; i < keys.size(); i++) {
		String k = keys[i];
		Variant v = d[k];
		NSString *key = [NSString stringWithUTF8String:k.utf8().get_data()];
		switch (v.get_type()) {
			case Variant::BOOL:    out[key] = @(bool(v)); break;
			case Variant::INT:     out[key] = @(int64_t(v)); break;
			case Variant::FLOAT:   out[key] = @(double(v)); break;
			default: {
				String s = v;
				out[key] = [NSString stringWithUTF8String:s.utf8().get_data()];
				break;
			}
		}
	}
	return out;
}

void MetaGraph::request(const String &graph_path, const Dictionary &parameters, const String &http_method, const String &tag) {
	NSString *path = [NSString stringWithUTF8String:graph_path.utf8().get_data()];
	NSDictionary<NSString *, id> *params = _dict_from_godot(parameters);
	NSString *method = [NSString stringWithUTF8String:http_method.utf8().get_data()];
	if (method.length == 0) {
		method = @"GET";
	}

	FBSDKGraphRequest *req = [[FBSDKGraphRequest alloc]
		initWithGraphPath:path
			   parameters:params
				  HTTPMethod:method];

	NSString *tagStr = tag.is_empty() ? nil : [NSString stringWithUTF8String:tag.utf8().get_data()];
	FBSDKGraphRequestConnection *conn = [[FBSDKGraphRequestConnection alloc] init];
	[conn addRequest:req completionHandler:^(FBSDKGraphRequestConnection *c, id result, NSError *error) {
		MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
		if (s == nullptr) return;

		Dictionary response;
		if (error != nil) {
			response["ok"] = false;
			response["error"] = String::utf8((error.localizedDescription ?: @"unknown").UTF8String);
			response["code"] = (int64_t)error.code;
		} else {
			response["ok"] = true;
			// We only ship back a JSON dictionary for simplicity. If
			// the server returned an array, we wrap it in a dict.
			if ([result isKindOfClass:[NSDictionary class]]) {
				Dictionary inner;
				[(NSDictionary *)result enumerateKeysAndObjectsUsingBlock:^(id k, id v, BOOL *stop) {
					if ([k isKindOfClass:[NSString class]]) {
						inner[String::utf8(((NSString *)k).UTF8String)] =
							[v isKindOfClass:[NSString class]] ? String::utf8(((NSString *)v).UTF8String) :
							[v isKindOfClass:[NSNumber class]] ? String::utf8([((NSNumber *)v) stringValue].UTF8String) :
							String("");
					}
				}];
				response["data"] = inner;
			} else if ([result isKindOfClass:[NSArray class]]) {
				PackedStringArray arr;
				for (id v in (NSArray *)result) {
					if ([v isKindOfClass:[NSString class]]) {
						arr.push_back(String::utf8(((NSString *)v).UTF8String));
					} else if ([v isKindOfClass:[NSNumber class]]) {
						arr.push_back(String::utf8([((NSNumber *)v) stringValue].UTF8String));
					}
				}
				response["data"] = arr;
			} else {
				response["data"] = String("");
			}
		}
		if (tagStr != nil) {
			s->call_deferred("emit_signal", "graph_response", String::utf8(tagStr.UTF8String), response);
		} else {
			s->call_deferred("emit_signal", "graph_response", String(""), response);
		}
	}];
	[conn start];
}

} // namespace godot
