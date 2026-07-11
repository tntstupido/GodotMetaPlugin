# Building the iOS Native Bridge

This document covers rebuilding the production iOS native bridge:
`ios/native/MetaInstallPlugin/` → `ios/plugins/meta_install_plugin/MetaInstallPlugin.{debug,release}.xcframework/`.

The older `addons/meta_sdk/` GDExtension prototype is **not** covered here — it
is a legacy reference, not a supported shipping path.

## When you need to rebuild

- After editing anything in `ios/native/MetaInstallPlugin/src/`
  (the C++/Objective-C++ source).
- After bumping the Meta SDK version in `ios/pods/Podfile`
  (then re-run `pod install` and the refresh step below).
- After bumping the Godot version the plugin targets.
- After bumping the iOS deployment target in `Podfile` and the
  `-miphoneos-version-min` / `-mios-simulator-version-min` flags in
  `ios/native/MetaInstallPlugin/scripts/build_xcframework.sh`.

If you only changed GDScript (e.g. `addons/meta_install_plugin/meta_install_tracker.gd`)
or the `.gdip` template, **you do not need to rebuild** — those don't
ship in the xcframework.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| macOS | 13+ | Required for the iOS build/export workflow |
| Xcode | 15+ | Xcode 26 / iOS SDK 26 confirmed working |
| Godot | 4.5.1 source | **Source tree**, not the editor app. The build needs `core/object/class_db.h` and friends. |
| CocoaPods | 1.16+ | For `pod install` in `ios/pods/` |

The Godot 4.5.1 source checkouts we know about on this machine (any
of these works — pick one that's already present to avoid a fresh
clone):

- `/Users/mladen/Documents/Plugins/GodotAdMobPlugin/third_party/godot-4.5.1-stable`

If none exists, clone it:

```sh
git clone -b 4.5.1-stable https://github.com/godotengine/godot.git /path/to/godot-4.5.1
```

Do **not** point `GODOT_HEADERS_DIR` at `/Applications/Godot.app` — that's
the editor bundle, not the source tree, and the C++ headers live in
the source tree.

## Build sequence

Run all of these from the **main checkout** root (not from a
`.worktrees/...` worktree — the worktree's `ios/pods/` is empty unless
you've also run `pod install` there).

```sh
# 1. Install the Meta SDK xcframeworks via CocoaPods (only needed the
#    first time, or after a Podfile change).
cd ios/pods
pod install
cd ../..

# 2. Copy the Pod-installed Meta SDK xcframeworks into the
#    distribution payload under ios/plugins/meta_install_plugin/.
#    Preserves _CodeSignature/ verbatim — do NOT add a strip step;
#    see "Why we don't strip _CodeSignature" below.
ios/native/MetaInstallPlugin/scripts/refresh_vendor_frameworks.sh

# 3. Build the wrapper xcframework. The build defaults to the
#    Pod-installed FBSDK xcframeworks from ios/pods/Pods/...; override
#    via FBSDK_CORE_XCFRAMEWORK / FBSDK_BASICS_XCFRAMEWORK /
#    FBAEMKIT_XCFRAMEWORK env vars if you want to link against
#    different copies.
GODOT_HEADERS_DIR=/path/to/godot-4.5.1 \
  ios/native/MetaInstallPlugin/scripts/build_xcframework.sh
```

## Output

The build writes two xcframeworks into
`ios/plugins/meta_install_plugin/`:

- `MetaInstallPlugin.debug.xcframework/` — compiled with `-DDEBUG_ENABLED`
  (enables FBSDK App Events + Network logging in Xcode console).
- `MetaInstallPlugin.release.xcframework/` — production binary.

Both ship `ios-arm64` (device) and `ios-arm64_x86_64-simulator` slices
(though the build script only emits arm64 simulator — see "Platform
support" below).

The directory `ios/plugins/meta_install_plugin/MetaInstallPlugin.{debug,release}.xcframework/`
is in `.gitignore` — these are local build artifacts. Rebuild any time;
the repo stays clean.

## Verifying a build

A quick sanity check after the build:

```sh
# Both new error strings from the client_token validation should be
# present in the compiled binary. If "Meta Client Token is empty."
# is missing, the build used a stale .mm.
strings ios/plugins/meta_install_plugin/MetaInstallPlugin.release.xcframework/ios-arm64/libMetaInstallPlugin.a \
  | grep "Meta .* is empty"
# Expected:
#   [MetaInstallPlugin] Meta App ID is empty.
#   [MetaInstallPlugin] Meta Client Token is empty.

# Sanity-check the xcframework structure
xcodebuild -version
file ios/plugins/meta_install_plugin/MetaInstallPlugin.release.xcframework/ios-arm64/libMetaInstallPlugin.a
# Expected: current ar archive, arm64
```

## Why we don't strip `_CodeSignature/`

`refresh_vendor_frameworks.sh` deliberately does a plain `cp -R` and
leaves the `_CodeSignature/` directory of each vendored
`FBSDKCoreKit.xcframework` / `FBSDKCoreKit_Basics.xcframework` /
`FBAEMKit.xcframework` intact. This is load-bearing:

- The Godot iOS exporter and the App Store validation pipeline both
  rely on the framework's code-signing and resource envelope being
  intact.
- Stripping `_CodeSignature/` causes `codesign --verify` to fail
  downstream and App Store submission to be rejected.
- The matching `.gitignore` rule (`**/_CodeSignature/`) keeps the
  working tree clean without modifying the shipped xcframework payload.

If you see untracked `_CodeSignature/` directories after a
`refresh_vendor_frameworks.sh` run, **leave them alone** — they are
expected.

## Platform support

- iOS minimum: 14.0 (matches `Podfile` and the `-miphoneos-version-min` /
  `-mios-simulator-version-min` flags in the build script).
- Simulator slices: arm64 only (Apple Silicon). Intel Macs are not
  supported for in-simulator testing — use a real device or an
  Apple Silicon host. The `.gitignore` rules intentionally drop any
  `*-x86_64-*` slice so x86_64 binaries never end up in the
  distribution payload.

## Integration into a Godot game

Once the xcframeworks are built, copy the entire `ios/plugins/meta_install_plugin/`
directory into the consumer game's iOS plugin folder:

```sh
rsync -a ios/plugins/meta_install_plugin/ /path/to/your_game/ios/plugins/meta_install_plugin/
```

The consumer game also needs:

- `addons/meta_install_plugin/` (the GDScript autoload helper, AARs,
  and `plugin.cfg`) — `rsync -a addons/meta_install_plugin/ /path/to/your_game/addons/meta_install_plugin/`
- `export_presets.cfg` entry enabling the iOS export plugin and
  Android Gradle export.
- `project.godot` autoload entry pointing at
  `res://addons/meta_install_plugin/meta_install_tracker.gd`.
- Per-game `meta_install_plugin.gdip` (copy from
  `ios/plugins/meta_install_plugin/meta_install_plugin.gdip.template`
  and fill in `FacebookAppID` / `FacebookClientToken` /
  `FacebookDisplayName`).

See `INSTALL.md` for the full consumer-side setup.

## Troubleshooting

- **"`Missing required xcframework: .../FBSDKCoreKit.xcframework`"** —
  `pod install` hasn't been run in `ios/pods/`, or the FBSDK xcframework
  was deleted. Re-run steps 1 + 2.
- **"fatal error: 'godot_cpp/...' / 'core/object/class_db.h' file not found"** —
  `GODOT_HEADERS_DIR` is unset, points at the Godot editor app
  (`/Applications/Godot.app`), or the source tree is incomplete.
- **`-framework FBSDKCoreKit: 'linker' input unused` warnings during build** —
  Harmless. The build script does `-c` (compile) only and passes
  `-framework` flags defensively; the warnings don't affect the
  output.
- **Stale prebuilt xcframework in main checkout after a `.mm` change** —
  Re-run step 3. The prebuilt xcframework is gitignored, so it can
  always be deleted and rebuilt without affecting the repo.
- **Build run from a `.worktrees/...` worktree fails with "Missing
  xcframework"** — The worktree's `ios/pods/` is empty. Either:
  - Run `cd ios/pods && pod install` inside the worktree, OR
  - Run the build from the main checkout, OR
  - Point the FBSDK xcframework env vars at the main checkout's
    `ios/pods/Pods/...` paths.
