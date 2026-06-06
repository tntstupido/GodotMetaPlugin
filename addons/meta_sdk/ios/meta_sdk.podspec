Pod::Spec.new do |s|
  s.name             = "GodotMetaSdk"
  s.version          = "1.0.0"
  s.summary          = "Godot 4.5.1 GDExtension that bridges the Meta (Facebook) SDK."
  s.description      = <<-DESC
                       Provides Facebook Login, App Events, Share, Audience
                       Network ads (banner / interstitial / rewarded) and the
                       Graph API as a Godot 4.5.1 singleton.
                       DESC
  s.homepage         = "https://github.com/example/GodotMetaPlugin"
  s.license          = { :type => "MIT", :file => "../../../LICENSE" }
  s.author           = { "GodotMetaPlugin contributors" => "noreply@example.com" }
  s.platform         = :ios, "14.0"
  s.ios.deployment_target = "14.0"
  s.swift_version    = "5.0"

  # Source files
  s.source_files = [
    "MetaSdkPlugin.h",
    "MetaSdkPlugin.mm",
    "MetaLogin.h",
    "MetaLogin.mm",
    "MetaShare.h",
    "MetaShare.mm",
    "MetaEvents.h",
    "MetaEvents.mm",
    "MetaAds.h",
    "MetaAds.mm",
    "MetaGraph.h",
    "MetaGraph.mm",
    "register_types.h",
    "register_types.mm",
  ]

  s.public_header_files = [
    "MetaSdkPlugin.h",
    "MetaLogin.h",
    "MetaShare.h",
    "MetaEvents.h",
    "MetaAds.h",
    "MetaGraph.h",
    "register_types.h",
  ]

  # The Meta SDK pods we depend on. These are pulled in transitively
  # from this podspec.
  s.dependency "FBSDKCoreKit", "~> 18.0"
  s.dependency "FBSDKLoginKit", "~> 18.0"
  s.dependency "FBSDKShareKit", "~> 18.0"
  s.dependency "FBAudienceNetwork", "~> 6.15"

  # godot-cpp
  s.dependency "godot-cpp", "~> 4.5"

  s.frameworks = "Foundation", "UIKit", "Security", "SafariServices", "WebKit", "StoreKit", "AdServices", "AppTrackingTransparency", "SystemConfiguration", "CoreGraphics"

  s.pod_target_xcconfig = {
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) GODOT_META_SDK=1",
    "OTHER_CPLUSPLUSFLAGS" => "-std=c++17 -fobjc-arc",
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++17",
    "CLANG_CXX_LIBRARY" => "libc++",
  }
end
