extends Node
## MetaAds
##
## GDScript wrapper around Facebook Audience Network (banner,
## interstitial and rewarded video ads).

# Banner
signal banner_ad_loaded(placement_id: String)
signal banner_ad_failed(placement_id: String, error: String)
signal banner_ad_clicked(placement_id: String)
signal banner_ad_clicked_finished(placement_id: String)

# Interstitial
signal interstitial_ad_loaded(placement_id: String)
signal interstitial_ad_failed(placement_id: String, error: String)
signal interstitial_ad_impression(placement_id: String)
signal interstitial_ad_clicked(placement_id: String)
signal interstitial_ad_closing(placement_id: String)
signal interstitial_ad_closed(placement_id: String)

# Rewarded
signal rewarded_ad_loaded(placement_id: String)
signal rewarded_ad_failed(placement_id: String, error: String)
signal rewarded_ad_impression(placement_id: String)
signal rewarded_ad_clicked(placement_id: String)
signal rewarded_ad_completed(placement_id: String)
signal rewarded_ad_closing(placement_id: String)
signal rewarded_ad_closed(placement_id: String)
signal rewarded_ad_server_reward(placement_id: String)
signal rewarded_ad_server_reward_failed(placement_id: String)

enum BannerPosition {
	TOP = 0,
	BOTTOM = 1,
}

var sdk: Node = null


func on_initialized(_config: Dictionary) -> void:
	if sdk == null:
		return
	# Re-emit every ad-related signal so users can use either
	# `MetaSdk.ads.rewarded_ad_completed` or `MetaSdk.rewarded_ad_completed`.
	var list := [
		"banner_ad_loaded", "banner_ad_failed", "banner_ad_clicked", "banner_ad_clicked_finished",
		"interstitial_ad_loaded", "interstitial_ad_failed", "interstitial_ad_impression",
		"interstitial_ad_clicked", "interstitial_ad_closing", "interstitial_ad_closed",
		"rewarded_ad_loaded", "rewarded_ad_failed", "rewarded_ad_impression",
		"rewarded_ad_clicked", "rewarded_ad_completed", "rewarded_ad_closing",
		"rewarded_ad_closed", "rewarded_ad_server_reward", "rewarded_ad_server_reward_failed",
	]
	for sig in list:
		sdk.connect(sig, _on_ad_event.bind(sig))


func _on_ad_event(args: Array, sig: String) -> void:
	emit_signal(sig, *args)


# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

func load_banner_ad(placement_id: String, position: int = BannerPosition.BOTTOM) -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("load_banner_ad", placement_id, position)


func show_banner_ad() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("show_banner_ad")


func hide_banner_ad() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("hide_banner_ad")


func destroy_banner_ad() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("destroy_banner_ad")


func is_banner_ad_loaded() -> bool:
	if sdk == null or sdk._native == null:
		return false
	return bool(sdk._native.call("is_banner_ad_loaded"))


# ---------------------------------------------------------------------------
# Interstitial
# ---------------------------------------------------------------------------

func load_interstitial_ad(placement_id: String) -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("load_interstitial_ad", placement_id)


func show_interstitial_ad() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("show_interstitial_ad")


func is_interstitial_ad_loaded() -> bool:
	if sdk == null or sdk._native == null:
		return false
	return bool(sdk._native.call("is_interstitial_ad_loaded"))


# ---------------------------------------------------------------------------
# Rewarded video
# ---------------------------------------------------------------------------

func load_rewarded_ad(placement_id: String) -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("load_rewarded_ad", placement_id)


func show_rewarded_ad() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("show_rewarded_ad")


func is_rewarded_ad_loaded() -> bool:
	if sdk == null or sdk._native == null:
		return false
	return bool(sdk._native.call("is_rewarded_ad_loaded"))
