#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/src"
BUILD_DIR="${ROOT_DIR}/build"
OUTPUT_DIR="${ROOT_DIR}/../../plugins/meta_install_plugin"

: "${GODOT_HEADERS_DIR:?Set GODOT_HEADERS_DIR to the Godot 4.5.1 source directory}"
: "${FBSDK_CORE_XCFRAMEWORK:?Set FBSDK_CORE_XCFRAMEWORK}"
: "${FBSDK_BASICS_XCFRAMEWORK:?Set FBSDK_BASICS_XCFRAMEWORK}"
: "${FBAEMKIT_XCFRAMEWORK:?Set FBAEMKIT_XCFRAMEWORK}"

IOS_SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
SIM_SDK_PATH="$(xcrun --sdk iphonesimulator --show-sdk-path)"
COMMON_GODOT_INCLUDES=(
	-I"${GODOT_HEADERS_DIR}"
	-I"${GODOT_HEADERS_DIR}/platform/ios"
	-I"${GODOT_HEADERS_DIR}/drivers/apple_embedded"
)

rm -rf "${BUILD_DIR}"
mkdir -p \
	"${BUILD_DIR}/debug/iphoneos" \
	"${BUILD_DIR}/debug/iphonesimulator" \
	"${BUILD_DIR}/release/iphoneos" \
	"${BUILD_DIR}/release/iphonesimulator" \
	"${OUTPUT_DIR}"
rm -rf "${OUTPUT_DIR}/MetaInstallPlugin.debug.xcframework" "${OUTPUT_DIR}/MetaInstallPlugin.release.xcframework"

framework_slice() {
	local framework="$1"
	local platform_slice="$2"
	local name="$3"
	echo "${framework}/${platform_slice}/${name}.framework"
}

build_static_lib() {
	local sdk_path="$1"
	local arch="$2"
	local platform_slice="$3"
	local slice_dir="$4"
	local min_flag="$5"
	local debug_define="$6"

	local core_slice
	local basics_slice
	local aem_slice
	core_slice="$(framework_slice "${FBSDK_CORE_XCFRAMEWORK}" "${platform_slice}" "FBSDKCoreKit")"
	basics_slice="$(framework_slice "${FBSDK_BASICS_XCFRAMEWORK}" "${platform_slice}" "FBSDKCoreKit_Basics")"
	aem_slice="$(framework_slice "${FBAEMKIT_XCFRAMEWORK}" "${platform_slice}" "FBAEMKit")"

	for source in meta_install_plugin.mm meta_install_plugin_bootstrap.mm; do
		xcrun clang++ \
			-std=c++17 \
			-fobjc-arc \
			-fobjc-weak \
			${debug_define:+${debug_define}} \
			-arch "${arch}" \
			-isysroot "${sdk_path}" \
			"${min_flag}" \
			"${COMMON_GODOT_INCLUDES[@]}" \
			-F"$(dirname "${core_slice}")" \
			-F"$(dirname "${basics_slice}")" \
			-F"$(dirname "${aem_slice}")" \
			-framework Foundation \
			-framework UIKit \
			-framework FBSDKCoreKit \
			-framework FBSDKCoreKit_Basics \
			-framework FBAEMKit \
			-c "${SRC_DIR}/${source}" \
			-o "${slice_dir}/${source%.mm}.o"
	done

	libtool -static \
		-o "${slice_dir}/libMetaInstallPlugin.a" \
		"${slice_dir}/meta_install_plugin.o" \
		"${slice_dir}/meta_install_plugin_bootstrap.o"
}

build_static_lib "${IOS_SDK_PATH}" "arm64" "ios-arm64" "${BUILD_DIR}/debug/iphoneos" "-miphoneos-version-min=14.0" "-DDEBUG_ENABLED"
build_static_lib "${SIM_SDK_PATH}" "arm64" "ios-arm64_x86_64-simulator" "${BUILD_DIR}/debug/iphonesimulator" "-mios-simulator-version-min=14.0" "-DDEBUG_ENABLED"
build_static_lib "${IOS_SDK_PATH}" "arm64" "ios-arm64" "${BUILD_DIR}/release/iphoneos" "-miphoneos-version-min=14.0" ""
build_static_lib "${SIM_SDK_PATH}" "arm64" "ios-arm64_x86_64-simulator" "${BUILD_DIR}/release/iphonesimulator" "-mios-simulator-version-min=14.0" ""

xcodebuild -create-xcframework \
	-library "${BUILD_DIR}/debug/iphoneos/libMetaInstallPlugin.a" \
	-headers "${SRC_DIR}" \
	-library "${BUILD_DIR}/debug/iphonesimulator/libMetaInstallPlugin.a" \
	-headers "${SRC_DIR}" \
	-output "${OUTPUT_DIR}/MetaInstallPlugin.debug.xcframework"

xcodebuild -create-xcframework \
	-library "${BUILD_DIR}/release/iphoneos/libMetaInstallPlugin.a" \
	-headers "${SRC_DIR}" \
	-library "${BUILD_DIR}/release/iphonesimulator/libMetaInstallPlugin.a" \
	-headers "${SRC_DIR}" \
	-output "${OUTPUT_DIR}/MetaInstallPlugin.release.xcframework"

echo "Built Meta install plugin xcframeworks in ${OUTPUT_DIR}"
