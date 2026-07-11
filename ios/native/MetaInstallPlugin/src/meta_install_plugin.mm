#import "meta_install_plugin.h"

#import <Foundation/Foundation.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AuthenticationServices/AuthenticationServices.h>
#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>

#include "core/object/class_db.h"
#include "core/variant/variant.h"

void MetaInstallPlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize", "app_id", "client_token", "display_name", "advertiser_id_collection"), &MetaInstallPlugin::initialize, DEFVAL(true));
	ClassDB::bind_method(D_METHOD("is_initialized"), &MetaInstallPlugin::is_initialized);
	ClassDB::bind_method(D_METHOD("sync_advertiser_tracking_enabled"), &MetaInstallPlugin::sync_advertiser_tracking_enabled);
	ClassDB::bind_method(D_METHOD("flush"), &MetaInstallPlugin::flush);
	ClassDB::bind_method(D_METHOD("get_sdk_version"), &MetaInstallPlugin::get_sdk_version);
}

Error MetaInstallPlugin::initialize(const String &app_id, const String &client_token, const String &display_name, bool advertiser_id_collection) {
	if (initialized) {
		return OK;
	}
	if (app_id.is_empty()) {
		ERR_PRINT("[MetaInstallPlugin] Meta App ID is empty.");
		return ERR_INVALID_PARAMETER;
	}
	if (client_token.is_empty()) {
		ERR_PRINT("[MetaInstallPlugin] Meta Client Token is empty.");
		return ERR_INVALID_PARAMETER;
	}

	FBSDKSettings.sharedSettings.appID = [NSString stringWithUTF8String:app_id.utf8().get_data()];
	FBSDKSettings.sharedSettings.clientToken = [NSString stringWithUTF8String:client_token.utf8().get_data()];
	FBSDKSettings.sharedSettings.displayName = [NSString stringWithUTF8String:display_name.utf8().get_data()];
	FBSDKSettings.sharedSettings.isAutoLogAppEventsEnabled = YES;
	FBSDKSettings.sharedSettings.isAdvertiserIDCollectionEnabled = advertiser_id_collection;
	sync_advertiser_tracking_enabled();
#ifdef DEBUG_ENABLED
	[FBSDKSettings.sharedSettings enableLoggingBehavior:FBSDKLoggingBehaviorAppEvents];
	[FBSDKSettings.sharedSettings enableLoggingBehavior:FBSDKLoggingBehaviorNetworkRequests];
#endif

	[[FBSDKApplicationDelegate sharedInstance] initializeSDK];
	[FBSDKAppEvents.shared activateApp];

	initialized = true;
	print_line("[MetaInstallPlugin] Meta App Events initialized for install attribution.");
	return OK;
}

bool MetaInstallPlugin::is_initialized() const {
	return initialized;
}

bool MetaInstallPlugin::sync_advertiser_tracking_enabled() {
	bool tracking_enabled = false;
	if (@available(iOS 14.0, *)) {
		tracking_enabled = ATTrackingManager.trackingAuthorizationStatus == ATTrackingManagerAuthorizationStatusAuthorized;
	}
	FBSDKSettings.sharedSettings.isAdvertiserTrackingEnabled = tracking_enabled;
	return tracking_enabled;
}

void MetaInstallPlugin::flush() {
	if (initialized) {
		[FBSDKAppEvents.shared flush];
	}
}

String MetaInstallPlugin::get_sdk_version() const {
	NSString *version = FBSDKSettings.sharedSettings.sdkVersion;
	return version == nil ? String() : String::utf8([version UTF8String]);
}
