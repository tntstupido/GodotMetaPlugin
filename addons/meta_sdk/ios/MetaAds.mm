// MetaAds.mm
//
// Implementation of the Facebook Audience Network bridge.

#include "MetaAds.h"
#include "MetaSdkPlugin.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <UIKit/UIKit.h>

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------

@interface MetaBannerDelegate : NSObject <FBAdViewDelegate>
@property (nonatomic, copy) NSString *placement;
@end

@implementation MetaBannerDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "banner_ad_loaded", String::utf8(self.placement.UTF8String));
}
- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "banner_ad_failed",
		String::utf8(self.placement.UTF8String),
		String::utf8((error.localizedDescription ?: @"unknown").UTF8String));
}
- (void)adViewDidClick:(FBAdView *)adView {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "banner_ad_clicked", String::utf8(self.placement.UTF8String));
}
- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "banner_ad_clicked_finished", String::utf8(self.placement.UTF8String));
}

@end

static FBAdView *g_banner = nil;
static MetaBannerDelegate *g_banner_delegate = nil;
static BOOL g_banner_loaded = NO;

static UIViewController *_root_vc() {
	UIWindow *w = [UIApplication sharedApplication].keyWindow;
	return w ? w.rootViewController : nil;
}

// ---------------------------------------------------------------------------
// Interstitial
// ---------------------------------------------------------------------------

@interface MetaInterstitialDelegate : NSObject <FBInterstitialAdDelegate>
@property (nonatomic, copy) NSString *placement;
@end

@implementation MetaInterstitialDelegate

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "interstitial_ad_loaded", String::utf8(self.placement.UTF8String));
}
- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "interstitial_ad_failed",
		String::utf8(self.placement.UTF8String),
		String::utf8((error.localizedDescription ?: @"unknown").UTF8String));
}
- (void)interstitialAdDidLogImpression:(FBInterstitialAd *)interstitialAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "interstitial_ad_impression", String::utf8(self.placement.UTF8String));
}
- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "interstitial_ad_clicked", String::utf8(self.placement.UTF8String));
}
- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "interstitial_ad_closing", String::utf8(self.placement.UTF8String));
}
- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "interstitial_ad_closed", String::utf8(self.placement.UTF8String));
}

@end

static FBInterstitialAd *g_interstitial = nil;
static MetaInterstitialDelegate *g_interstitial_delegate = nil;

// ---------------------------------------------------------------------------
// Rewarded
// ---------------------------------------------------------------------------

@interface MetaRewardedDelegate : NSObject <FBRewardedVideoAdDelegate>
@property (nonatomic, copy) NSString *placement;
@end

@implementation MetaRewardedDelegate

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_loaded", String::utf8(self.placement.UTF8String));
}
- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_failed",
		String::utf8(self.placement.UTF8String),
		String::utf8((error.localizedDescription ?: @"unknown").UTF8String));
}
- (void)rewardedVideoAdDidLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_impression", String::utf8(self.placement.UTF8String));
}
- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_clicked", String::utf8(self.placement.UTF8String));
}
- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_completed", String::utf8(self.placement.UTF8String));
}
- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_closing", String::utf8(self.placement.UTF8String));
}
- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_closed", String::utf8(self.placement.UTF8String));
}
- (void)rewardedVideoAdServerRewardDidSucceed:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_server_reward", String::utf8(self.placement.UTF8String));
}
- (void)rewardedVideoAdServerRewardDidFail:(FBRewardedVideoAd *)rewardedVideoAd {
	MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
	if (s) s->call_deferred("emit_signal", "rewarded_ad_server_reward_failed", String::utf8(self.placement.UTF8String));
}

@end

static FBRewardedVideoAd *g_rewarded = nil;
static MetaRewardedDelegate *g_rewarded_delegate = nil;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

namespace godot {

// Banner ------------------------------------------------------------------

void MetaAds::load_banner(const String &placement_id, int position) {
	if (g_banner != nil) {
		[g_banner removeFromSuperview];
		g_banner = nil;
	}
	NSString *pid = [NSString stringWithUTF8String:placement_id.utf8().get_data()];
	g_banner = [[FBAdView alloc] initWithPlacementID:pid
									  adSize:kFBAdSize320x50
							rootViewController:_root_vc()];
	[g_banner disableAutoRefresh];

	FBAdViewPosition p = (FBAdViewPosition)position;
	g_banner.frame = CGRectMake(0, 0, g_banner.frame.size.width, g_banner.frame.size.height);
	g_banner_delegate = [[MetaBannerDelegate alloc] init];
	g_banner_delegate.placement = pid;
	g_banner.delegate = g_banner_delegate;

	g_banner_loaded = NO;
	[g_banner loadAd];
}

void MetaAds::show_banner() {
	if (g_banner == nil || _root_vc() == nil) return;
	UIView *v = _root_vc().view;
	CGRect frame = g_banner.frame;
	CGFloat bottom = v.bounds.size.height - frame.size.height;
	CGFloat top = 0;
	// Naive position handling: 0 = top, 1 = bottom. (Real options
	// include a 4-mode enum but two are by far the most common.)
	frame.origin.y = (g_banner.frame.origin.y == 0) ? top : bottom;
	frame.origin.x = (v.bounds.size.width - frame.size.width) / 2.0;
	g_banner.frame = frame;
	[v addSubview:g_banner];
	(void)p;
}

void MetaAds::hide_banner() {
	if (g_banner != nil) {
		[g_banner removeFromSuperview];
	}
}

void MetaAds::destroy_banner() {
	if (g_banner != nil) {
		[g_banner removeFromSuperview];
		g_banner.delegate = nil;
		g_banner = nil;
	}
	g_banner_delegate = nil;
	g_banner_loaded = NO;
}

bool MetaAds::is_banner_loaded() {
	return g_banner_loaded;
}

// Interstitial ------------------------------------------------------------

void MetaAds::load_interstitial(const String &placement_id) {
	NSString *pid = [NSString stringWithUTF8String:placement_id.utf8().get_data()];
	g_interstitial = [[FBInterstitialAd alloc] initWithPlacementID:pid];
	g_interstitial_delegate = [[MetaInterstitialDelegate alloc] init];
	g_interstitial_delegate.placement = pid;
	g_interstitial.delegate = g_interstitial_delegate;
	[g_interstitial loadAd];
}

void MetaAds::show_interstitial() {
	if (g_interstitial == nil || !g_interstitial.isAdValid) {
		MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
		if (s) s->call_deferred("emit_signal", "interstitial_ad_failed",
			String(""), String("not_loaded"));
		return;
	}
	[g_interstitial showAdFromRootViewController:_root_vc()];
}

bool MetaAds::is_interstitial_loaded() {
	return g_interstitial != nil && g_interstitial.isAdValid;
}

// Rewarded ----------------------------------------------------------------

void MetaAds::load_rewarded(const String &placement_id) {
	NSString *pid = [NSString stringWithUTF8String:placement_id.utf8().get_data()];
	g_rewarded = [[FBRewardedVideoAd alloc] initWithPlacementID:pid];
	g_rewarded_delegate = [[MetaRewardedDelegate alloc] init];
	g_rewarded_delegate.placement = pid;
	g_rewarded.delegate = g_rewarded_delegate;
	[g_rewarded loadAd];
}

void MetaAds::show_rewarded() {
	if (g_rewarded == nil || !g_rewarded.isAdValid) {
		MetaSdkPlugin *s = MetaSdkPlugin::get_singleton();
		if (s) s->call_deferred("emit_signal", "rewarded_ad_failed",
			String(""), String("not_loaded"));
		return;
	}
	[g_rewarded showAdFromRootViewController:_root_vc()];
}

bool MetaAds::is_rewarded_loaded() {
	return g_rewarded != nil && g_rewarded.isAdValid;
}

} // namespace godot
