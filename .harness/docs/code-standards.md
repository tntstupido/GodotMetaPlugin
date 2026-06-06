# Code Standards

## GDScript

- Prefer typed variables: `var plugin: Object` over `var plugin`
- Use `@tool` for editor-only scripts, `@export` for exposed fields
- Singleton name: `MetaInstallPlugin` (matches the native exposed singleton)
- Keep scripts short; move complex logic into dedicated classes

## Objective-C++ / C

- Brace-on-new-line, 4-space indent (match existing `ios/native/MetaInstallPlugin/src/`)
- Prefix Godot-exposed methods with `meta_install_plugin_`
- Wrap all Godot <→ Obj-C++ bridging in `meta_install_plugin_bootstrap.mm`
- Never expose raw pointer returns to GDScript — wrap in `String` or typed `Variant`

## iOS / CocoaPods

- Podfile lives at `ios/pods/Podfile`
- After any `Podfile` change: `pod install` inside `ios/pods/`
- xcframework build expects FBSDK xcframeworks in `ios/plugins/meta_install_plugin/`

## ATT ownership

The plugin **never** triggers the ATT prompt. This is the host game's responsibility. The plugin only mirrors the authorization state via `sync_advertiser_tracking_enabled()`.

## No secrets

App IDs, client tokens, and display names are runtime parameters passed from the host game — never hardcoded in the plugin.