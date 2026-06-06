# App Links / Deep Linking

Legacy prototype reference only.

This document describes the older broad-scope Meta SDK prototype and is not part of the current supported production payload. The current shipping plugin in this repository is install-attribution-only and does not expose active deep-link handling APIs.

The plugin supports two kinds of deep links:

1. **Custom URL scheme** — `fb<app_id>://...` (used by Facebook Login
   to return control to your app)
2. **iOS Universal Links** — `https://<your-domain>/...` (used by Meta
   App Links to deep-link into your app from a Facebook post)

## 1. URL scheme

The `meta_sdk/app_id` and optional `meta_sdk/url_scheme_suffix`
project settings are used to build the `CFBundleURLSchemes` entry
automatically by the export plugin. The scheme is always
`fb<app_id><suffix>`.

When Facebook Login completes it will call
`application:openURL:options:` with a URL of that scheme. The native
plugin forwards it to `MetaSdk.handle_open_url()`, which in turn
emits the `url_opened` signal on the singleton.

```gdscript
MetaSdk.url_opened.connect(func(url: String):
    print("Got URL: ", url)
)
```

## 2. Universal Links / App Links

Set the `meta_sdk/facebook_domain` project setting to your Facebook
App Domain (e.g. `mycoolgame.com`). The export plugin will add the
`FacebookDomain` plist entry.

To make Universal Links work on iOS you also need to:

1. Host an `apple-app-site-association` file on your domain with the
   `applinks:<bundle_id>` entry.
2. Add the Associated Domains entitlement to your Xcode project, e.g.
   `applinks:mycoolgame.com`.
3. Enable the capability in Xcode (Signing & Capabilities → Associated
   Domains).

You can wire those up in the iOS export preset of your Godot project
(Project → Export → iOS → Capabilities → Associated Domains).

## 3. Receiving data from App Links

When the user opens your app via an App Link, iOS will deliver the
URL to your app delegate. The plugin emits `url_opened` with the
incoming URL — the format depends on what your Facebook dashboard
configures for the post. You can pass a query parameter to the
content URL and parse it in your game:

```gdscript
MetaSdk.url_opened.connect(func(url: String):
    var parsed = url.split("?")[1] if "?" in url else ""
    var params = parsed.split("&")
    for p in params:
        var kv = p.split("=")
        if kv.size() == 2 and kv[0] == "reward":
            claim_reward(kv[1])
)
```
