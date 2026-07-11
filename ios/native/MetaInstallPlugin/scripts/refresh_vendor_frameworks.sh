#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="${ROOT_DIR}/../../plugins/meta_install_plugin"
PODS_DIR="${ROOT_DIR}/../../pods/Pods"

# Copies the Meta SDK xcframeworks from the local CocoaPods install
# into the distribution payload. The shipped xcframeworks MUST be
# untouched bit-for-bit copies of the CocoaPods originals.
#
# Specifically: do NOT strip _CodeSignature/ from the copied frameworks.
# Godot's iOS exporter and the App Store validation pipeline both rely
# on the framework's code-signing and resource envelope being intact.
# Re-signing downstream fails or App Store submission is rejected if
# _CodeSignature/ is removed. See INSTALL.md ("Build the iOS Native
# Payload") for the full rationale.

copy_framework() {
	local source_dir="$1"
	local dest_dir="$2"

	if [[ ! -d "${source_dir}" ]]; then
		echo "Missing source xcframework: ${source_dir}" >&2
		exit 1
	fi

	rm -rf "${dest_dir}"
	cp -R "${source_dir}" "${dest_dir}"
}

copy_framework \
	"${PODS_DIR}/FBSDKCoreKit/XCFrameworks/FBSDKCoreKit.xcframework" \
	"${PLUGIN_DIR}/FBSDKCoreKit.xcframework"
copy_framework \
	"${PODS_DIR}/FBSDKCoreKit_Basics/XCFrameworks/FBSDKCoreKit_Basics.xcframework" \
	"${PLUGIN_DIR}/FBSDKCoreKit_Basics.xcframework"
copy_framework \
	"${PODS_DIR}/FBAEMKit/XCFrameworks/FBAEMKit.xcframework" \
	"${PLUGIN_DIR}/FBAEMKit.xcframework"

echo "Refreshed Meta vendor xcframeworks into ${PLUGIN_DIR}"
echo "(preserved _CodeSignature/ — do not strip; required for Godot iOS export + App Store)"
