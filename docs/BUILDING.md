# Building the GDExtension

You normally don't need to rebuild the GDExtension; the prebuilt
`GodotMetaSdk.framework` is bundled with the plugin. If you do want
to rebuild it (e.g. after a Meta SDK or Godot version bump), follow
the steps below.

## 1. Check out `godot-cpp`

The build expects `godot-cpp` 4.5 to live next to the
`addons/meta_sdk/ios/` directory:

```sh
git clone -b 4.5 https://github.com/godotengine/godot-cpp.git
```

The directory layout should be:

```
<project_root>/
├── godot-cpp/         ← just cloned
└── addons/
    └── meta_sdk/
        └── ios/       ← has SConstruct, SCsub, *.mm
```

## 2. Build

```sh
cd addons/meta_sdk/ios
scons platform=ios arch=arm64 target=template_release
scons platform=ios arch=arm64 target=template_debug
scons platform=ios arch=x86_64 target=template_release
scons platform=ios arch=x86_64 target=template_debug
```

The output goes to `addons/meta_sdk/ios/bin/`:

```
libgodot_meta_sdk.ios.template_release.framework/
libgodot_meta_sdk.ios.template_debug.framework/
```

These are referenced by the `.gdextension` config file.

## 3. Bumping the Meta SDK version

The Meta SDK is fetched as a CocoaPod by the export plugin, so the
version of `FBSDKCoreKit` etc. is controlled by the
`meta_sdk.podspec` and `Podfile`. To upgrade:

1. Edit `s.dependency "FBSDKCoreKit", "~> 18.0"` (and friends) in
   `addons/meta_sdk/ios/meta_sdk.podspec`.
2. Edit the corresponding `pod 'FBSDKCoreKit', '~> 18.0'` in
   `addons/meta_sdk/ios/Podfile`.
3. Rebuild the GDExtension (steps above).
4. Re-export your Godot project and run `pod update FBSDKCoreKit` in
   the exported Xcode project.

## 4. Bumping godot-cpp

If you upgrade the GDExtension to a new Godot version, also update
`compatibility_minimum` in `GodotMetaSdk.gdextension`.

## 5. Troubleshooting

- **"Framework not found"** when running on device — make sure the
  GDExtension file lists a framework that actually exists on disk.
- **"Undefined symbol: _OBJC_CLASS_$_FBSDKSettings"** — the
  CocoaPods install step was skipped; run `pod install` in the
  exported Xcode project.
- **`#include <godot_cpp/...>` not found** — `godot-cpp/` is not
  next to `addons/meta_sdk/ios/`, or you used the wrong branch.
