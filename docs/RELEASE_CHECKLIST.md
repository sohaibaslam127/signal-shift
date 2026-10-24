# Release Checklist

Items marked **(needs owner)** require accounts, credentials or hardware that are not in this repository.

## Before every build

- [ ] `./tools/run_tests.sh` passes (tests + headless boot smoke run).
- [ ] `godot --headless --path . -s res://tools/generate_levels.gd` produces no diff (content is stable).
- [ ] Bump `application/config/version`, Android `version/code` + `version/name`, iOS `short_version` + `version`.
- [ ] Play through levels 1–5, one move-limit level, the daily puzzle and the pack preview on a phone.

## One-time setup

- [ ] Install export templates for Godot 4.7.2 (Editor → Manage Export Templates). **(needs owner)**
- [ ] Android: install the Android build template; set Android SDK / JDK paths in Editor Settings. **(needs owner)**
- [ ] Android: create an upload keystore and set it in the export preset (stored in `.godot/export_credentials.cfg`, git-ignored). Back it up offline. **(needs owner)**
- [ ] iOS: set `application/app_store_team_id`, signing identity and provisioning in the iOS preset; archive from Xcode. **(needs owner)**
- [ ] Confirm `package/unique_name` / `bundle_identifier` (`com.sohaibaslam.signalshift` placeholder) before the first upload — it cannot change later.
- [ ] Launcher icons: export `icon.svg` to 192×192, 432×432 adaptive foreground/background, 1024×1024 (no alpha) for iOS.

## Store consoles **(needs owner)**

- [ ] Play Console: app created, content rating questionnaire, target audience, Data safety form
	  ("no data collected" while no ad SDK is integrated).
- [ ] App Store Connect: app record, age rating, App Privacy ("Data Not Collected" while no ad SDK).
- [ ] Privacy policy URL: host `docs/PRIVACY_POLICY.md` publicly and set `signal_shift/privacy_policy_url`.
- [ ] Store listing text and graphics from `docs/STORE_LISTING.md`.
- [ ] In-app products `pack_overclock` and `supporter` (non-consumable) — only once a billing adapter ships (see `docs/PLUGIN_INTEGRATION.md`).

## Build

- [ ] Android: Project → Export → Android → Export Project (`.aab`) with release, signed.
- [ ] iOS: export Xcode project → archive → upload with Xcode Organizer.
- [ ] Internal testing track / TestFlight on at least one low-end Android phone and one iPhone.
- [ ] Verify: portrait lock, notch/safe-area margins, back button behaviour (Android), pause/resume
	  saves progress, audio mutes when the app is backgrounded.
