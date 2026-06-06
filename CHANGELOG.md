# Changelog

All notable changes to the Godot Meta SDK plugin are documented in this
file. The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] - 2026-06-06

### Added
- Initial release of the iOS-only Meta SDK plugin for Godot 4.5.1.
- Native iOS install-attribution plugin payload (`MetaInstallPlugin`).
- Meta Core/App Events bridge with `activateApp`, explicit `flush()`, and SDK version reporting.
- ATT-state synchronization via `sync_advertiser_tracking_enabled()`.
- Debug-only Meta App Events and network logging for real-device diagnostics.
- Build flow for debug/release xcframework outputs under `ios/plugins/meta_install_plugin/`.
- Documentation: `README.md`, `INSTALL.md`, `docs/API.md`.

### Notes
- This release documents the supported production payload only.
- Older prototype materials for login/share/ads/graph remain in the repository as reference source, not as supported shipping functionality.
