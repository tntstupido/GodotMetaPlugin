# AGENTS.md

Godot 4.5.1 iOS plugin providing Meta (Facebook) install-attribution via a native xcframework bridge for Meta Ads campaigns.

## Setup commands

- Install deps: `cd ios/pods && pod install`
- Build xcframework: `GODOT_HEADERS_DIR=/path/to/godot-4.5.1 FBSDK_CORE_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBSDKCoreKit.xcframework" FBSDK_BASICS_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBSDKCoreKit_Basics.xcframework" FBAEMKIT_XCFRAMEWORK="$PWD/ios/plugins/meta_install_plugin/FBAEMKit.xcframework" ios/native/MetaInstallPlugin/scripts/build_xcframework.sh`
- Test GDScript: open in Godot 4.5.1 editor and run the demo scene (`examples/demo.tscn`)
- Lint GDScript: no automated linter — review manually; prefer typed GDScript (`@tool`, `@export`, typed variables)
- No automated test suite — see Testing instructions

## Project layout

- `addons/meta_sdk/` — Godot plugin GDScript + iOS Objective-C++ source (legacy prototype; do not modify for current production path)
- `ios/plugins/meta_install_plugin/` — distribution payload: pre-built xcframeworks + bundled Meta SDK xcframeworks
- `ios/native/MetaInstallPlugin/` — native source for the Godot iOS plugin bridge (Objective-C++ / C)
- `ios/pods/` — CocoaPods working directory (FBSDKCoreKit, FBAEMKit, FBSDKCoreKit_Basics)
- `examples/` — demo scene and script for runtime integration
- `docs/` — integration guides, API reference, and troubleshooting

## Code style

- GDScript: typed variables (`var plugin: Object`) preferred over untyped; use `@tool`, `@export` annotations
- Objective-C++: match the existing style in `ios/native/MetaInstallPlugin/src/` — brace-on-new-line, 4-space indent
- No formatter config — follow surrounding code
- Run no linter — manual review only

## Testing instructions

- Manual test: build the game for iOS (real device), run through Meta Events Manager to confirm `activateApp` and `App installs` appear
- Xcode/device logs are authoritative over Meta dashboard latency
- Test both debug and release xcframeworks
- ATT flow: verify `sync_advertiser_tracking_enabled()` mirrors the OS authorization state

## PR & commit conventions

- No automated CI yet — user manages branches manually
- Branch from `main`; never push directly to it
- Commit message: conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`)
- No PR tooling configured — open PRs manually in GitHub UI

## Security

- Never commit secrets — `.env` and credentials are not in this repo
- App IDs / client tokens live in the host game's export config, not in this plugin
- Meta SDK itself is governed by Meta's platform terms (not this repo's MIT license)
- Report vulnerabilities via `security@example.com` (see SECURITY.md)