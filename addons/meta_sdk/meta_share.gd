extends Node
## MetaShare
##
## GDScript wrapper around the Facebook Share dialog. Supports links,
## photos and videos.

signal share_opened(type: String, payload: String)
signal share_completed(type: String)
signal share_failed(type: String, error: String)

var sdk: Node = null


func on_initialized(_config: Dictionary) -> void:
	if sdk != null:
		sdk.share_opened.connect(_on_share_opened)
		sdk.share_completed.connect(_on_share_completed)
		sdk.share_failed.connect(_on_share_failed)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Open the Facebook Share dialog with a link and an optional quote.
## `mode` can be "automatic", "native", "web" or "feed".
func share_link(url: String, quote: String = "", mode: String = "automatic") -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("share_link", url, quote, mode)


## Share a single photo. The path can be an absolute path or a
## `res://` / `user://` path; the file must be a readable image.
func share_photo(photo_path: String, caption: String = "", mode: String = "automatic") -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("share_photo", photo_path, caption, mode)


## Share a single video. Same path rules as `share_photo`.
func share_video(video_path: String, caption: String = "", mode: String = "automatic") -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("share_video", video_path, caption, mode)


## Returns true if the device can present a share dialog.
func can_show_share_dialog() -> bool:
	if sdk == null or sdk._native == null:
		return false
	return bool(sdk._native.call("can_show_share_dialog"))


## Send a link via the iOS Messages app. Falls back to the regular
## share dialog on devices without messaging capabilities.
func message_share_link(url: String, quote: String = "") -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("message_share_link", url, quote)


# ---------------------------------------------------------------------------
# Signal forwarders
# ---------------------------------------------------------------------------

func _on_share_opened(type: String, payload: String) -> void:
	emit_signal("share_opened", type, payload)


func _on_share_completed(type: String) -> void:
	emit_signal("share_completed", type)


func _on_share_failed(type: String, error: String) -> void:
	emit_signal("share_failed", type, error)
