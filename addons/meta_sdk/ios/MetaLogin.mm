// MetaLogin.mm
//
// Implementation of the Facebook Login bridge.

#include "MetaLogin.h"
#include "MetaSdkPlugin.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

// The login manager is a single instance for the lifetime of the app.
static FBSDKLoginManager *g_login_manager = nil;

@interface MetaLoginDelegate : NSObject <FBSDKLoginManagerDelegate>
@end

@implementation MetaLoginDelegate

- (void)loginManager:(FBSDKLoginManager *)loginManager
	didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
				error:(NSError *)error {
	if (error != nil) {
		NSString *desc = error.localizedDescription ?: @"Unknown error";
		MetaLogin::_emit_login_failed(String::utf8([desc UTF8String]));
		return;
	}
	if (result.isCancelled) {
		MetaLogin::_emit_login_cancelled();
		return;
	}
	if (result.token == nil) {
		MetaLogin::_emit_login_failed(String("No access token returned"));
		return;
	}

	// Fetch the user profile in the background, then emit success.
	NSString *token = result.token.tokenString;
	NSString *userId = result.token.userID;

	NSString *graphPath = @"me?fields=id,name,picture.type(large)";
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/v19.0/%@", graphPath]];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];

	NSURLSessionDataTask *task = [[NSURLSession sharedSession]
		dataTaskWithRequest:req
		  completionHandler:^(NSData *data, NSURLResponse *response, NSError *err) {
			NSString *name = @"";
			NSString *pic = @"";
			if (data != nil && err == nil) {
				NSError *jerr = nil;
				NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jerr];
				if ([dict isKindOfClass:[NSDictionary class]]) {
					id n = dict[@"name"];
					if ([n isKindOfClass:[NSString class]]) name = n;
					id p = dict[@"picture"];
					if ([p isKindOfClass:[NSDictionary class]]) {
						id data2 = p[@"data"];
						if ([data2 isKindOfClass:[NSDictionary class]]) {
							id u = data2[@"url"];
							if ([u isKindOfClass:[NSString class]]) pic = u;
						}
					}
				}
			}
			MetaLogin::_emit_login_completed(
				String::utf8([token UTF8String]),
				String::utf8([userId UTF8String]),
				String::utf8([name UTF8String]),
				String::utf8([pic UTF8String]));
		}];
	[task resume];
}

@end

static MetaLoginDelegate *g_delegate = nil;

namespace godot {

void MetaLogin::login(const PackedStringArray &permissions, bool publish) {
	if (g_login_manager == nil) {
		g_login_manager = [[FBSDKLoginManager alloc] init];
	}
	if (g_delegate == nil) {
		g_delegate = [[MetaLoginDelegate alloc] init];
	}

	// Convert PackedStringArray -> NSArray<NSString*>*.
	NSMutableArray<NSString *> *perms = [NSMutableArray array];
	for (int i = 0; i < permissions.size(); i++) {
		String s = permissions[i];
		[perms addObject:[NSString stringWithUTF8String:s.utf8().get_data()]];
	}
	if (perms.count == 0) {
		[perms addObject:@"public_profile"];
	}

	UIViewController *root = nil;
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (window != nil) {
		root = window.rootViewController;
	}
	[g_loginManager logInFromViewController:root
								permissions:perms
							fromURLScheme:nil
									 handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
		if (error != nil) {
			MetaLogin::_emit_login_failed(String::utf8(error.localizedDescription.UTF8String));
		} else if (result.isCancelled) {
			MetaLogin::_emit_login_cancelled();
		} else {
			[g_delegate loginManager:g_login_manager didCompleteWithResult:result error:nil];
		}
	}];
}

void MetaLogin::logout() {
	if (g_login_manager == nil) {
		g_login_manager = [[FBSDKLoginManager alloc] init];
	}
	[g_login_manager logOut];
}

bool MetaLogin::is_logged_in() {
	return [FBSDKAccessToken currentAccessToken] != nil;
}

String MetaLogin::get_access_token() {
	FBSDKAccessToken *t = [FBSDKAccessToken currentAccessToken];
	return t ? String::utf8(t.tokenString.UTF8String) : String("");
}

String MetaLogin::get_user_id() {
	FBSDKAccessToken *t = [FBSDKAccessToken currentAccessToken];
	return t ? String::utf8(t.userID.UTF8String) : String("");
}

String MetaLogin::get_profile_name() {
	// The profile cache from FBSDKProfile is the cheapest way to get the
	// user's name without doing a network round-trip.
	NSString *name = FBSDKProfile.currentProfile.name;
	return name ? String::utf8(name.UTF8String) : String("");
}

String MetaLogin::get_profile_picture_url() {
	NSString *url = FBSDKProfile.currentProfile.imageURL.absoluteString;
	return url ? String::utf8(url.UTF8String) : String("");
}

Dictionary MetaLogin::get_profile() {
	Dictionary d;
	FBSDKProfile *p = FBSDKProfile.currentProfile;
	if (p != nil) {
		d["user_id"] = String::utf8(p.userID.UTF8String);
		d["name"] = String::utf8(p.name.UTF8String);
		if (p.imageURL != nil) {
			d["picture_url"] = String::utf8(p.imageURL.absoluteString.UTF8String);
		}
	}
	return d;
}

void MetaLogin::_emit_login_completed(const String &token, const String &user_id, const String &name, const String &picture_url) {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s == nullptr) return;
	Callable cb = Callable(s, "emit_signal").bind("login_completed", token, user_id, name, picture_url);
	s->call_deferred("emit_signal", "login_completed", token, user_id, name, picture_url);
	(void)cb;
}

void MetaLogin::_emit_login_failed(const String &error) {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s == nullptr) return;
	s->call_deferred("emit_signal", "login_failed", error);
}

void MetaLogin::_emit_login_cancelled() {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s == nullptr) return;
	s->call_deferred("emit_signal", "login_cancelled");
}

} // namespace godot
