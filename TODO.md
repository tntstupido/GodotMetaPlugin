# TODO — GodotMetaPlugin

Backlog for `D:\Godot\Plugins\GodotMetaPlugin`. Prioritizovano po consumer-impact.

## High priority — affects every Godot 4.6.x consumer

### [ ] Ship reference GDScript tracker autoload
**Problem:** every consumer project (rule-rings, etc.) has to write their own `_init_meta_sdk_android()` with the candidate-name lookup, ProjectSettings read, and error code mapping. This is identical boilerplate, copy-pasted.

**Fix:** add `addons/meta_install_plugin/meta_install_tracker.gd` (a `Node` autoload) that:
- auto-iterates the singleton candidate list (`MetaInstallPlugin`, `metainstallplugin`, `MetaInstall`, `metainstall`, `MetaInstallPluginDebug`)
- reads `meta_sdk/*` from `ProjectSettings` automatically
- exposes `initialize()`, `is_initialized()`, `flush()`, `get_sdk_version()` as plain methods
- logs structured result via a `tracker_status` signal + return code constants
- documented usage in `INSTALL.md`

This was a ~50-line block in rule-rings `AppController.gd:_init_meta_sdk_android` and will be a ~50-line block in the next project too, unless the plugin ships it.

**Decision (2026-07-10):** Ship as **autoload**. Consumer adds `MetaInstallTracker="*res://addons/meta_install_plugin/meta_install_tracker.gd"` to their `[autoload]` section in `project.godot`. Documented usage in INSTALL.md.

**Files:** new `addons/meta_install_plugin/meta_install_tracker.gd` + matching `meta_install_tracker.gd.uid`; INSTALL.md section rewrite.

### [ ] Document the singleton-name candidate list
**Problem:** `INSTALL.md` line 108 says `Engine.has_singleton("MetaInstallPlugin")` as if it's guaranteed. In practice, the registration name depends on Godot's `GodotAndroidPlugins` registry which can vary by build flavor. The same caveat forced rule-rings to use a 5-element candidate list (only 1 of them matched at runtime).

**Fix:** add a "Singleton name resolution" subsection to `INSTALL.md` showing the candidate list pattern (mirroring `FirebaseManager` in rule-rings' `firebase_plugin`).

**Files:** `INSTALL.md` only.

## Medium priority — doc freshness

### [ ] Bump README to Godot 4.6.x
README.md says **"Godot 4.5.1"** at lines 5, 24, 53. The actual consumers (rule-rings) run Godot 4.6.3. Either:
- replace "4.5.1" with a "4.5.1+" / "4.6.x compatible" note
- or drop the version pin and say "current Godot 4 LTS"

**Files:** `README.md`.

### [ ] Update CHANGELOG with Android bridge + 18.2.3 bump
Current CHANGELOG has only 1.0.0 (2026-06-06) for iOS. Missing entries per git log:
- `1.1.0` — feat: add android meta install attribution bridge (commit 78d1f51)
- `1.1.1` or `1.2.0` — Update Meta SDK to 18.2.3 (latest) (commit 6232418)
- `1.2.1` — Mavis agent team bootstrap (commit b1d111d) — internal-only, can be omitted

**Files:** `CHANGELOG.md`.

### [ ] Refresh TROUBLESHOOTING.md
Current content is "legacy prototype reference only" per its own header, but it's still the page users find when they hit problems. Rewrite to cover the **current** production payload:

- **"Initialize returns 31 ERR_INVALID_PARAMETER"** — `client_token` is empty. Set `meta_sdk/client_token` in Project Settings (not in code).
- **"Initialize returns 49 ERR_UNAVAILABLE"** — `activity?.application` was null. Plugin called too early in app startup, before Godot attached the activity.
- **"Has_singleton returns false"** — singleton name is one of the candidates. Try `Engine.get_singleton(name)` for: `MetaInstallPlugin`, `metainstallplugin`, `MetaInstall`, `metainstall`, `MetaInstallPluginDebug`. Use a fallback loop.
- **"Install event not surfacing in Meta Events Manager"** — `FacebookInitProvider` from `AutoInitEnabled=true` manifest only calls `sdkInitialize`, NOT `activateApp`. The host must call `plugin.initialize(...)` (which internally calls `AppEventsLogger.activateApp(application)`) to fire the install event.
- **"Dashboard 'Test events' is empty but logs show /activities 200"** — Meta dashboard lags. Overview updates later than Test events. Trust device log first.

**Files:** `TROUBLESHOOTING.md` rewrite.

### [ ] API.md — document return codes
Current API.md only lists the `OK` and `ERR_INVALID_PARAMETER` cases. The Kotlin source actually returns:
- `0` (OK)
- `31` (ERR_INVALID_PARAMETER) — when `app_id` OR `client_token` is blank
- `49` (ERR_UNAVAILABLE) — when `activity?.application` is null

Add a "Return codes" subsection.

**Files:** `docs/API.md`.

## Low priority — quality-of-life

### [ ] Link APP_LINKS.md from README
`docs/APP_LINKS.md` exists but is not in the README "Docs" list. Either link it or remove it.

### [ ] AAR source rebuild verification note
The `addons/meta_install_plugin/MetaInstallPlugin-*.aar` files are committed binaries. When the Kotlin source under `android/plugin/src/main/java/...` is edited, `./gradlew assemble` syncs new AARs into `addons/meta_install_plugin/`. Add a CI / build verification step that confirms the AAR hash matches the source. (Optional — only matters if multiple devs rebuild the AAR.)

### [ ] Track `META_DEBUG_LOGGING` in CHANGELOG
The Kotlin source has `BuildConfig.META_DEBUG_LOGGING` (line 60) that enables verbose Meta logging in debug builds. Currently undocumented.

## Out of scope (do not do)

- Facebook Login / Share / Ads / Graph — explicitly out of production scope per README.
- Multi-flavor AAR builds (e.g. flavor per advertiser_id_collection) — overengineering for current use.
- Reintroducing the `addons/meta_sdk/` GDScript surface — README explicitly marks it legacy.
