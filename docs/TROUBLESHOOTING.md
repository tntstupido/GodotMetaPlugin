# Troubleshooting

Legacy prototype reference only.

This page contains issues from the earlier broad-scope Meta SDK prototype. For the current supported production payload, prefer `README.md`, `INSTALL.md`, and `docs/INSTALL_TRACKING.md`.

Common issues and how to fix them.

## "Native bridge not loaded" in the editor

This is expected when running in the Godot editor on a non-iOS
platform. The GDScript singleton still loads so the rest of your code
keeps working; only the methods that need the native side become
no-ops. Nothing to do.

## "FacebookAppID is empty"

You didn't set `meta_sdk/app_id` in **Project Settings → Meta SDK**.
The plugin refuses to initialise without an App ID.

## `pod install` fails with "Unable to find a specification for FBSDKCoreKit"

CocoaPods is using the wrong repo. Run:

```sh
pod repo update
```

## "Undefined symbols for architecture arm64: _FBSDKSettings"

The Xcode project wasn't built with the `xcworkspace` after
`pod install`. Close Xcode, re-run `pod install` and open the
**`.xcworkspace`** (not the `.xcodeproj`).

## `application:openURL:options:` not called

The `CFBundleURLSchemes` plist entry wasn't added. Check the export
log — the `MetaSDK` export plugin emits an `add_ios_plist_content`
call. If you don't see it, the iOS export preset probably doesn't
have the plugin enabled.

## Login dialog doesn't appear

- Make sure you've added the **Facebook** and **FacebookMessenger**
  apps to the LSApplicationQueriesSchemes plist entry. The plugin does
  this automatically.
- Make sure your Facebook App is configured for "iOS" in the
  dashboard, and that you've added the bundle id to the
  "iOS Bundle ID" field.

## Login completes but `login_completed` signal never fires

The native side calls the callback on a background queue and the
GDScript helper bounces it to the main thread via
`call_deferred("emit_signal", ...)`. If your `MetaSdk` singleton
isn't in the scene tree, the deferred call will be lost. Make sure
the autoload was registered and that you haven't removed it.

## Audience Network test ads

When you register your app in the Facebook dashboard, go to
**Audience Network → Property → Ad Space** and create test ad spaces.
Use the test placement ids in your development builds. Real ads
won't be served to your test devices otherwise.

## Build fails on Apple Silicon (M1/M2/M3)

- Make sure you have Xcode 15+ installed.
- Run `sudo gem install --user-install cocoapods` and use the
  user-installed binary if the system one is too old.
- If `pod install` complains about an unsupported architecture,
  delete the `Pods/` directory and the `.xcworkspace` and re-run
  `pod install`.
