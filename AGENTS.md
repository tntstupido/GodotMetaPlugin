# AGENTS.md

Godot 4.5.1 iOS plugin providing Meta (Facebook) install-attribution via a native xcframework bridge for Meta Ads campaigns.

## Setup commands

- Install deps: `cd ios/pods && pod install`
- Refresh signed vendor frameworks: `ios/native/MetaInstallPlugin/scripts/refresh_vendor_frameworks.sh`
- Build xcframework: `GODOT_HEADERS_DIR=/path/to/godot-4.5.1 ios/native/MetaInstallPlugin/scripts/build_xcframework.sh`
- Create the per-game export plugin config: `cp ios/plugins/meta_install_plugin/meta_install_plugin.gdip.template ios/plugins/meta_install_plugin/meta_install_plugin.gdip` and fill in `FacebookAppID`, `FacebookClientToken`, `FacebookDisplayName` (the `.gdip` itself is gitignored — local config per machine)
- Test GDScript: open in Godot 4.5.1 editor and run the demo scene (`examples/demo.tscn`)
- Lint GDScript: no automated linter — review manually; prefer typed GDScript (`@tool`, `@export`, typed variables)
- No automated test suite — see Testing instructions

## Project layout

- `addons/meta_sdk/` — Godot plugin GDScript + iOS Objective-C++ source (legacy prototype; do not modify for current production path)
- `addons/meta_install_plugin/` — production plugin: GDScript autoload helper (`meta_install_tracker.gd`) + Android AAR + plugin config
- `ios/plugins/meta_install_plugin/` — distribution payload: pre-built xcframeworks + bundled Meta SDK xcframeworks refreshed from CocoaPods + per-game `.gdip` (gitignored) and `.gdip.template`
- `ios/native/MetaInstallPlugin/` — native source for the Godot iOS plugin bridge (Objective-C++ / C) + build/refresh scripts
- `ios/pods/` — CocoaPods working directory (FBSDKCoreKit, FBAEMKit, FBSDKCoreKit_Basics)
- `examples/` — demo scene and script for runtime integration
- `docs/` — integration guides, API reference, and troubleshooting

## Platform support

- iOS minimum: 14.0 (matches `Podfile` and `xcrun -miphoneos-version-min`)
- Simulator slices: arm64 only (Apple Silicon). Intel Macs are not supported for in-simulator testing — use a real device or an Apple Silicon host. The `.gitignore` rules intentionally drop any `*-x86_64-*` slice so x86_64 binaries never end up in the distribution payload.
- Vendor xcframework integrity: the bundled Meta SDK xcframeworks under `ios/plugins/meta_install_plugin/` are bit-for-bit copies of what `pod install` produces, including `_CodeSignature/`. The Godot iOS exporter and the App Store validation pipeline both rely on the code-signing and resource envelope being intact — `refresh_vendor_frameworks.sh` deliberately does NOT strip `_CodeSignature/`. The `.gitignore` ignores `_CodeSignature/` directories so the working tree stays clean without modifying the shipped xcframework payloads.

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
