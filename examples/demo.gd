extends Control
## Meta SDK plugin demo.
##
## Drop this scene into a Godot project, fill in your Facebook App ID
## in *Project Settings → Meta SDK*, and run on an iOS device.

const LOG_TAG := "[Meta SDK Demo]"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

const _BANNER_PLACEMENT_ID := "YOUR_BANNER_PLACEMENT_ID"
const _INTERSTITIAL_PLACEMENT_ID := "YOUR_INTERSTITIAL_PLACEMENT_ID"
const _REWARDED_PLACEMENT_ID := "YOUR_REWARDED_PLACEMENT_ID"

# ---------------------------------------------------------------------------
# Demo state
# ---------------------------------------------------------------------------

var _logged_in := false


func _ready() -> void:
	# Initialise the Meta SDK. All values fall back to the ones defined
	# in Project Settings, so this call is enough when those are set.
	MetaSdk.initialize()

	# Connect to the signals that we care about. You can connect to
	# `MetaSdk.<signal>` directly or to `MetaSdk.<sub>. <signal>`.
	MetaSdk.login_completed.connect(_on_login_completed)
	MetaSdk.login_failed.connect(_on_login_failed)
	MetaSdk.login_cancelled.connect(_on_login_cancelled)

	MetaSdk.banner_ad_loaded.connect(func(pid): print(LOG_TAG, "banner_loaded", pid))
	MetaSdk.banner_ad_failed.connect(func(pid, err): print(LOG_TAG, "banner_failed", pid, err))

	MetaSdk.interstitial_ad_loaded.connect(func(pid): print(LOG_TAG, "interstitial_loaded", pid))
	MetaSdk.interstitial_ad_failed.connect(func(pid, err): print(LOG_TAG, "interstitial_failed", pid, err))
	MetaSdk.interstitial_ad_closed.connect(func(_pid): print(LOG_TAG, "interstitial_closed"))

	MetaSdk.rewarded_ad_loaded.connect(func(pid): print(LOG_TAG, "rewarded_loaded", pid))
	MetaSdk.rewarded_ad_failed.connect(func(pid, err): print(LOG_TAG, "rewarded_failed", pid, err))
	MetaSdk.rewarded_ad_completed.connect(func(pid): print(LOG_TAG, "rewarded_completed", pid))

	MetaSdk.graph_response.connect(_on_graph_response)

	# Log a sample install event
	MetaSdk.events.log_event("app_opened", {"ts": Time.get_unix_time_from_system()})

	# Wire up the demo UI buttons
	%LoginButton.pressed.connect(_on_login_pressed)
	%LogoutButton.pressed.connect(_on_logout_pressed)
	%ShareLinkButton.pressed.connect(_on_share_link_pressed)
	%LoadInterstitialButton.pressed.connect(_on_load_interstitial_pressed)
	%ShowInterstitialButton.pressed.connect(_on_show_interstitial_pressed)
	%LoadRewardedButton.pressed.connect(_on_load_rewarded_pressed)
	%ShowRewardedButton.pressed.connect(_on_show_rewarded_pressed)
	%GraphMeButton.pressed.connect(_on_graph_me_pressed)
	if has_node("%ReplayInstallButton"):
		%ReplayInstallButton.pressed.connect(_on_replay_install_pressed)
	if has_node("%AdvertiserIdLabel"):
		%AdvertiserIdLabel.text = "Advertiser ID: %s" % MetaSdk.events.get_advertiser_id()
	if has_node("%FirstLaunchLabel"):
		%FirstLaunchLabel.text = "First launch: %s" % ("yes" if MetaSdk.events.is_first_launch() else "no")

	_refresh_login_label()


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

func _on_login_pressed() -> void:
	if _logged_in:
		# Already logged in, behave as logout.
		_on_logout_pressed()
		return
	MetaSdk.login.log_in(["public_profile", "email"])


func _on_logout_pressed() -> void:
	MetaSdk.login.log_out()
	MetaSdk.events.clear_user_data()
	_logged_in = false
	_refresh_login_label()


func _on_login_completed(_access_token: String, user_id: String, name: String, _picture_url: String) -> void:
	_logged_in = true
	print(LOG_TAG, "Login ok:", user_id, name)
	_refresh_login_label()
	# After login, we can attach user data so Meta can stitch the
	# install event to the user.
	MetaSdk.events.set_user_data({
		"email": "player@example.com",
		"first_name": name,
	})


func _on_login_failed(error: String) -> void:
	push_warning("%s Login failed: %s" % [LOG_TAG, error])


func _on_login_cancelled() -> void:
	print(LOG_TAG, "Login cancelled")


func _refresh_login_label() -> void:
	if %LoginLabel:
		if MetaSdk.login.is_logged_in() or _logged_in:
			%LoginLabel.text = "Logged in as %s" % MetaSdk.login.get_user_id()
		else:
			%LoginLabel.text = "Not logged in"


# ---------------------------------------------------------------------------
# Share
# ---------------------------------------------------------------------------

func _on_share_link_pressed() -> void:
	MetaSdk.share.share_link(
		"https://example.com",
		"Check out this awesome game!",
		"automatic",
	)


# ---------------------------------------------------------------------------
# Ads
# ---------------------------------------------------------------------------

func _on_load_interstitial_pressed() -> void:
	MetaSdk.ads.load_interstitial_ad(_INTERSTITIAL_PLACEMENT_ID)


func _on_show_interstitial_pressed() -> void:
	if MetaSdk.ads.is_interstitial_ad_loaded():
		MetaSdk.ads.show_interstitial_ad()
	else:
		print(LOG_TAG, "Interstitial not ready yet")


func _on_load_rewarded_pressed() -> void:
	MetaSdk.ads.load_rewarded_ad(_REWARDED_PLACEMENT_ID)


func _on_show_rewarded_pressed() -> void:
	if MetaSdk.ads.is_rewarded_ad_loaded():
		MetaSdk.ads.show_rewarded_ad()
	else:
		print(LOG_TAG, "Rewarded ad not ready yet")


# ---------------------------------------------------------------------------
# Graph
# ---------------------------------------------------------------------------

func _on_graph_me_pressed() -> void:
	MetaSdk.graph.get_me("id,name,email,picture", "demo_me")


func _on_graph_response(tag: String, response: Dictionary) -> void:
	print(LOG_TAG, "graph_response", tag, response)
	if not bool(response.get("ok", false)):
		push_warning("%s Graph error: %s" % [LOG_TAG, response.get("error", "")])
		return
	# Successful response. You can also log an event for each one.
	MetaSdk.events.log_event("graph_request_completed", {"tag": tag})


# ---------------------------------------------------------------------------
# Install tracking (Meta Ads Manager)
# ---------------------------------------------------------------------------

func _on_replay_install_pressed() -> void:
	# Re-emits fb_mobile_install. The event normally fires only on the
	# first launch of the app; this button lets you verify the
	# install-tracking pipeline in the Events Manager dashboard.
	MetaSdk.events.log_install_event()
	if %AdvertiserIdLabel:
		%AdvertiserIdLabel.text = "Advertiser ID: %s" % MetaSdk.events.get_advertiser_id()
	print(LOG_TAG, "Replayed fb_mobile_install; advertiser_id=%s" % MetaSdk.events.get_advertiser_id())
