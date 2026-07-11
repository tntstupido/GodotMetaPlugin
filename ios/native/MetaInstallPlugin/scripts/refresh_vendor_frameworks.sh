#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_DIR="${ROOT_DIR}/../../plugins/meta_install_plugin"
PODS_DIR="${ROOT_DIR}/../../pods/Pods"

copy_framework() {
	local source_dir="$1"
	local dest_dir="$2"

	if [[ ! -d "${source_dir}" ]]; then
		echo "Missing source xcframework: ${source_dir}" >&2
		exit 1
	fi

	rm -rf "${dest_dir}"
	cp -R "${source_dir}" "${dest_dir}"

	# Strip Apple code-signing artifacts so the bundled xcframeworks are
	# usable by other developers without your local signing identity.
	# `cp -R` preserves them, but they are machine-specific and would
	# otherwise be a source of constant untracked noise.
	find "${dest_dir}" -type d -name "_CodeSignature" -prune -exec rm -rf {} +
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

echo "Refreshed signed Meta vendor xcframeworks into ${PLUGIN_DIR}"
