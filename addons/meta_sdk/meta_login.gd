extends Node
## MetaLogin
##
## GDScript wrapper around the Facebook Login flow. The native side
## emits signals on the `MetaSdk` singleton; this node mirrors them as
## its own signals for convenience.

## Emitted on successful login.
signal login_completed(access_token: String, user_id: String, name: String, picture_url: String)
## Emitted on a failure.
signal login_failed(error: String)
## Emitted when the user cancelled the dialog.
signal login_cancelled

var sdk: Node = null


func on_initialized(_config: Dictionary) -> void:
	# Forward everything from the parent singleton so users can also
	# subscribe to `MetaSdk.login.login_completed`.
	if sdk != null:
		sdk.login_completed.connect(_on_login_completed)
		sdk.login_failed.connect(_on_login_failed)
		sdk.login_cancelled.connect(_on_login_cancelled)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Request a Facebook Login with **read** permissions.
## [codeblock]
## MetaSdk.login.log_in(["public_profile", "email"])
## [/codeblock]
func log_in(permissions: PackedStringArray = PackedStringArray()) -> void:
	if sdk == null or not sdk.is_initialized():
		push_warning("[Meta SDK] Login attempted before MetaSdk.initialize()")
		return
	if sdk._native == null:
		push_warning("[Meta SDK] No native bridge; ignoring login call.")
		return
	sdk._native.call("login_with_read_permissions", permissions)


## Request a Facebook Login with **publish** permissions.
func log_in_for_publish(permissions: PackedStringArray = PackedStringArray()) -> void:
	if sdk == null or not sdk.is_initialized():
		push_warning("[Meta SDK] Login attempted before MetaSdk.initialize()")
		return
	if sdk._native == null:
		return
	sdk._native.call("login_with_publish_permissions", permissions)


## Log the user out and clear the cached token.
func log_out() -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("logout")


## Returns true if a valid access token is cached on disk.
func is_logged_in() -> bool:
	if sdk == null or sdk._native == null:
		return false
	return bool(sdk._native.call("is_logged_in"))


## Returns the current access token (empty string if not logged in).
func get_access_token() -> String:
	if sdk == null or sdk._native == null:
		return ""
	return str(sdk._native.call("get_access_token"))


## Returns the Facebook user id (empty string if not logged in).
func get_user_id() -> String:
	if sdk == null or sdk._native == null:
		return ""
	return str(sdk._native.call("get_user_id"))


## Returns the user's display name (empty string if not logged in).
func get_profile_name() -> String:
	if sdk == null or sdk._native == null:
		return ""
	return str(sdk._native.call("get_profile_name"))


## Returns the URL of the user's profile picture.
func get_profile_picture_url() -> String:
	if sdk == null or sdk._native == null:
		return ""
	return str(sdk._native.call("get_profile_picture_url"))


## Returns a dictionary with `user_id`, `name` and `picture_url`.
func get_profile() -> Dictionary:
	if sdk == null or sdk._native == null:
		return {}
	return sdk._native.call("get_profile")


# ---------------------------------------------------------------------------
# Signal forwarders
# ---------------------------------------------------------------------------

func _on_login_completed(access_token: String, user_id: String, name: String, picture_url: String) -> void:
	emit_signal("login_completed", access_token, user_id, name, picture_url)


func _on_login_failed(error: String) -> void:
	emit_signal("login_failed", error)


func _on_login_cancelled() -> void:
	emit_signal("login_cancelled")
