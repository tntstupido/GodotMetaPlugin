extends Node
## MetaGraph
##
## GDScript wrapper around the Facebook Graph API.

signal graph_response(tag: String, response: Dictionary)

var sdk: Node = null


func on_initialized(_config: Dictionary) -> void:
	if sdk != null:
		sdk.graph_response.connect(_on_graph_response)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Issue a Graph API request.
## [codeblock]
## MetaSdk.graph.request(
##     "me",
##     {"fields": "id,name,picture"},
##     "GET",
##     "fetch_profile",
## )
## [/codeblock]
## The result is delivered via the `graph_response` signal, with the
## supplied `tag` echoed back so you can correlate the request and
## response.
func request(graph_path: String, parameters: Dictionary = {}, http_method: String = "GET", tag: String = "") -> void:
	if sdk == null or sdk._native == null:
		return
	sdk._native.call("graph_request", graph_path, parameters, http_method, tag)


## Convenience: GET /me?fields=...
func get_me(fields: String = "id,name,email,picture", tag: String = "get_me") -> void:
	request("me", {"fields": fields}, "GET", tag)


## Convenience: POST /me/permissions (logout-style)
## Note: this is just a generic Graph call. The actual logout is on the
## login helper.
func post(graph_path: String, parameters: Dictionary = {}, tag: String = "") -> void:
	request(graph_path, parameters, "POST", tag)


# ---------------------------------------------------------------------------
# Signal forwarders
# ---------------------------------------------------------------------------

func _on_graph_response(tag: String, response: Dictionary) -> void:
	emit_signal("graph_response", tag, response)
