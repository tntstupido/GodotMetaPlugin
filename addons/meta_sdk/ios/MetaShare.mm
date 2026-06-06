// MetaShare.mm
//
// Implementation of the Facebook Share bridge.

#include "MetaShare.h"
#include "MetaSdkPlugin.h"

#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

static UIViewController *_root_vc() {
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	return window ? window.rootViewController : nil;
}

static void _emit(const char *sig, const String &a = String(""), const String &b = String("")) {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s == nullptr) return;
	s->call_deferred("emit_signal", sig, a, b);
}

namespace godot {

void MetaShare::share_link(const String &url, const String &quote, const String &mode) {
	FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
	content.contentURL = [NSURL URLWithString:[NSString stringWithUTF8String:url.utf8().get_data()]];
	if (!quote.is_empty()) {
		content.quote = [NSString stringWithUTF8String:quote.utf8().get_data()];
	}

	FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
	dialog.fromViewController = _root_vc();
	dialog.shareContent = content;
	dialog.mode = (mode == "native" ? FBSDKShareDialogModeNative
					: mode == "web" ? FBSDKShareDialogModeWeb
					: mode == "feed" ? FBSDKShareDialogModeFeedWeb
					: FBSDKShareDialogModeAutomatic);
	[dialog show];

	// No completion handler in the Obj-C block-based API; users should
	// rely on the `share_completed` / `share_failed` signals emitted
	// by the application delegate if they wire those up.
	_emit("share_opened", String::utf8("share_link"), url);
}

void MetaShare::share_photo(const String &photo_path, const String &caption, const String &mode) {
	NSString *p = [NSString stringWithUTF8String:photo_path.utf8().get_data()];
	UIImage *image = nil;
	if ([p hasPrefix:@"file://"]) {
		image = [UIImage imageWithContentsOfFile:[p substringFromIndex:7]];
	} else {
		image = [UIImage imageWithContentsOfFile:p];
	}
	if (image == nil) {
		_emit("share_failed", String::utf8("share_photo"), String::utf8("Could not load image"));
		return;
	}

	FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] initWithImage:image userGenerated:YES];
	FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
	content.photos = @[ photo ];
	if (!caption.is_empty()) {
		content.contentURL = [NSURL URLWithString:[NSString stringWithUTF8String:caption.utf8().get_data()]];
	}

	FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
	dialog.fromViewController = _root_vc();
	dialog.shareContent = content;
	dialog.mode = FBSDKShareDialogModeAutomatic;
	[dialog show];
	_emit("share_opened", String::utf8("share_photo"), photo_path);
}

void MetaShare::share_video(const String &video_path, const String &caption, const String &mode) {
	NSString *p = [NSString stringWithUTF8String:video_path.utf8().get_data()];
	NSString *cleanPath = [p hasPrefix:@"file://"] ? [p substringFromIndex:7] : p;
	NSURL *videoUrl = [NSURL fileURLWithPath:cleanPath];
	if (videoUrl == nil) {
		_emit("share_failed", String::utf8("share_video"), String::utf8("Invalid path"));
		return;
	}

	FBSDKShareVideo *video = [[FBSDKShareVideo alloc] initWithVideoURL:videoUrl];
	FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
	content.video = video;
	if (!caption.is_empty()) {
		content.contentURL = [NSURL URLWithString:[NSString stringWithUTF8String:caption.utf8().get_data()]];
	}

	FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
	dialog.fromViewController = _root_vc();
	dialog.shareContent = content;
	dialog.mode = FBSDKShareDialogModeAutomatic;
	[dialog show];
	_emit("share_opened", String::utf8("share_video"), video_path);
}

bool MetaShare::can_share() {
	return [FBSDKShareDialog class] != nil;
}

bool MetaShare::can_show_share_dialog() {
	FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
	FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
	content.contentURL = [NSURL URLWithString:@"https://example.com/"];
	dialog.shareContent = content;
	return [dialog canShow];
}

void MetaShare::message_share_link(const String &url, const String &quote) {
	if (![MFMessageComposeViewController canSendText]) {
		_emit("share_failed", String::utf8("message_share_link"), String::utf8("Messaging not available"));
		return;
	}
	MFMessageComposeViewController *vc = [[MFMessageComposeViewController alloc] init];
	if (!quote.is_empty()) {
		vc.body = [NSString stringWithUTF8String:quote.utf8().get_data()];
	}
	// Append URL to the message body.
	if (vc.body == nil) {
		vc.body = [NSString stringWithUTF8String:url.utf8().get_data()];
	} else {
		vc.body = [vc.body stringByAppendingFormat:@"\n%@", [NSString stringWithUTF8String:url.utf8().get_data()]];
	}
	vc.messageComposeDelegate = (id<MFMessageComposeViewControllerDelegate>)_root_vc();
	[_root_vc() presentViewController:vc animated:YES completion:nil];
}

} // namespace godot
