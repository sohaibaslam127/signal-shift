# Store Listing — Signal Shift

Single source for everything pasted into Google Play Console and App Store Connect.
Items marked **(owner)** need an account, a decision or a value that is not in this repository.
Character limits are the stores' limits at time of writing; re-check in the console before submitting.

## 1. Identity (both stores)

| Field | Value |
| --- | --- |
| App name (≤30) | Signal Shift |
| Package / bundle ID | `com.sohaibaslam.signalshift` (cannot change after first upload) |
| Version | 0.1.0 (Android `version/code` 1, iOS build `1`) |
| Category | Games → Puzzle |
| iOS secondary category | Games → Strategy |
| Price | Free, with in-app purchases and ads |
| Orientation | Portrait only |
| Devices | Android phones/tablets; iPhone only (`targeted_device_family=0`, so no iPad screenshots) |
| Min OS | iOS 15.0; Android per Godot 4.7.2 export default |
| Languages | English (US) |
| Privacy policy URL | https://techbolic.com/games/signal-shift/privacy/ (site source in `marketing/`; keep in sync with `PRIVACY_POLICY.md`) |
| Terms URL / marketing URL | https://techbolic.com/games/signal-shift/terms/ · https://techbolic.com/games/signal-shift/ |
| Support / contact | https://github.com/sohaibaslam127/signal-shift/issues · **(owner)** support email, required by both stores |
| Copyright (iOS) | © 2026 Sohaib Aslam **(owner: confirm legal name)** |

## 2. Text

### Subtitle / short description

| Store | Field | Text |
| --- | --- | --- |
| App Store | Subtitle (≤30) | `Connect the signal` (18) |
| Google Play | Short description (≤80) | `Rotate circuit tiles to connect the signal. Calm, clever logic puzzles.` (71) |

### Promotional text (App Store, ≤170, editable without a new build)

> 100 free handcrafted levels, a fresh Daily Puzzle every day and four expert packs. Tap, rotate, connect. Works offline.

(119 characters)

### Full description (App Store ≤4000, Google Play ≤4000)

```text
Connect the signal. Outsmart the grid.

Tap to rotate circuit tiles and route power from the source to every receiver. Easy to learn in seconds, hard to put down. Signal Shift is a calm, minimalist logic puzzle with a glowing circuit look and no timers.

FREE TO PLAY
• 100 handcrafted campaign levels across 10 chapters, free forever
• A new Daily Puzzle every day, playable offline
• Earn up to three stars by matching par
• Undo, reset and hints whenever you are stuck

PUZZLES THAT KEEP GROWING
• Branching circuits and misleading routes
• Fixed tiles, blocked cells and move limits
• Every level is verified solvable, so a stuck board is always your move, never a bug

EXPERT PUZZLE PACKS
Four optional packs of 60 circuits each. Try the first levels of each pack for free.
• Overclock: dense, multi-branch circuits for experts
• Logic Gates: wire both inputs before an AND gate lets the signal through
• Circuit Breaker: repair broken wires and avoid the red fault terminal
• Quantum Protocol: splitters and relays that make every move count

MADE FOR MOBILE
• One-handed portrait play, big touch targets
• Plays fully offline, no account needed
• Reduced-motion mode, haptics, sound and music toggles
• Original sound design and music

ADS AND PURCHASES
Signal Shift is free to play and contains ads. Videos are optional: watch one when you want an extra hint. After several watched videos, free players may see an occasional ad break between puzzles. The one-time Supporter Pass removes ad breaks, raises your daily hints from 3 to 6, boosts the no-hint bonus and includes one premium pack of your choice. You never need to buy anything to finish the 100-level campaign.

Connect the signal. Can you light every receiver?
```

(1,730 characters.)

### Keywords (App Store, ≤100 characters including commas)

```text
puzzle,logic,circuit,connect,pipes,rotate,brain,daily,offline,minimal,wire,path,electric,relax,gates
```

(100 characters, the maximum.) Do not repeat words already in the name or subtitle. Google Play has no keyword field: it indexes
the title, short and full description, so those words are already woven into the text above.

### What's new (first release, both stores)

```text
Welcome to Signal Shift! 100 free levels, a Daily Puzzle and four expert packs. Connect the signal.
```

## 3. Graphics

All files are in [`docs/store/`](store/). Regenerate screenshots with the dev capture tool (see section 8).

| Asset | Store | Spec | File |
| --- | --- | --- | --- |
| App icon | Play | 512×512 PNG, ≤1 MB | `graphics/icon_play_512.png` |
| App icon | App Store | 1024×1024 PNG, no alpha, square (the OS rounds it) | `graphics/icon_appstore_1024.png` |
| Feature graphic | Play (required) | 1024×500 PNG/JPEG, no alpha | `graphics/feature_graphic_1024x500.png` |
| Phone screenshots (6) | Play | 2–8 images, each side 320–3840 px, long side ≤ 2× short side. Supplied at 1080×1920 | `screenshots/play/` |
| iPhone screenshots (6) | App Store | 1–10 images; 6.9" set accepts 1290×2796. Supplied at 1290×2796 | `screenshots/appstore/` |

Not needed: iPad screenshots (iPhone-only build), Play tablet screenshots (optional), promo video (optional).

### The 6 screenshots, in order

| # | File | Shows | Suggested caption overlay (optional) |
| --- | --- | --- | --- |
| 1 | `01_main_menu` | Title, Continue, bottom navigation | Connect the signal |
| 2 | `02_mid_solve` | Early level, glowing source, move counter and par | Tap to rotate. Light the grid. |
| 3 | `03_solved` | "Signal Restored!" with three stars | Earn three stars |
| 4 | `04_level_select` | Chapters with stars and progress | 100 free levels |
| 5 | `05_daily` | Daily Puzzle on a larger branching board | A new puzzle every day |
| 6 | `06_pack_level` | Quantum Protocol level with the AND gate | Expert packs with new mechanics |

Caveats: these are **desktop renders of the real game scenes**, not device captures, and they reflect the capturing
machine's save (for example "Level 3", 9/300 stars, a free-hint badge). Store policies require screenshots to show
the actual app, which these do. For the final submission, either re-capture on a clean install or on devices
(**owner**), and avoid any screen that shows "Store unavailable" in place of prices.

## 4. In-app products

Create these **non-consumable** products with identical IDs in Play Console (In-app products) and App Store Connect
(In-App Purchases). Prices are **(owner)** decisions; the tiers below are suggestions only.

| Product ID | Display name | Description (≤ store limit) | Suggested tier |
| --- | --- | --- | --- |
| `supporter` | Supporter Pass | Lifetime upgrade: no ad breaks, 6 daily hints, bigger no-hint bonus and one premium pack of your choice free. | $4.99 |
| `pack_overclock` | Overclock Pack | 60 dense, multi-branch circuits for experts. | $1.99 |
| `pack_logic_gates` | Logic Gates Pack | 60 circuits built around the AND gate. | $1.99 |
| `pack_circuit_breaker` | Circuit Breaker Pack | 60 repair circuits with broken wires and fault terminals. | $1.99 |
| `pack_quantum_protocol` | Quantum Protocol Pack | 60 advanced circuits with splitters and relays. | $1.99 |

App Store only: each product needs a review screenshot (the Packs screen showing the price) and review notes.
The game has a **Restore Purchases** button in Settings, which App Review requires.

## 5. Declarations and questionnaires

### Google Play Console

| Section | Answer |
| --- | --- |
| App or game | Game |
| Free or paid | Free |
| Contains ads | **Yes** (AdMob rewarded ads and an occasional unrewarded break) |
| In-app purchases | **Yes** |
| Target audience | 13 and over (**owner**). The game is family-friendly, but declaring a children's audience triggers the Families policy and certified-ad-SDK rules. If you want under-13s, review that policy first. |
| Content rating (IARC questionnaire) | Violence none · sexual content none · profanity none · controlled substances none · user interaction none · shares location no · digital purchases yes. Expected: Everyone / PEGI 3 |
| News app / COVID app / government | No |
| Data safety | See below |
| Advertising ID declaration | **Yes**: AdMob uses the advertising ID. Add `com.google.android.gms.permission.AD_ID` (the AdMob plugin may add it; check the merged manifest) |
| App signing | Use Play App Signing; upload an `.aab` signed with the upload key |
| Closed testing | New personal developer accounts must run a closed test with the required number of testers for the required period before production access (**owner**: check current rules) |
| Target API | Meet Play's current target API requirement for new apps (**owner**: verify the level in Play Console before upload) |

**Data safety form** (the policy text in `PRIVACY_POLICY.md` must match):

| Question | Answer |
| --- | --- |
| Collects or shares data | Yes (through Google AdMob) |
| Data types | Device or other IDs (advertising ID); App activity / diagnostics as disclosed in Google's AdMob data-disclosure page. Verify the exact list for the installed plugin and SDK version. |
| Purpose | Advertising; analytics/fraud prevention per AdMob's disclosure |
| Shared with third parties | Yes: Google (ad network) |
| Data encrypted in transit | Yes |
| Users can request deletion | No account exists; uninstalling removes local data. Advertising data is governed by Google's controls |
| Purchases | Handled by Google Play; the developer receives no payment data |

### App Store Connect

| Section | Answer |
| --- | --- |
| Platform / SKU | iOS · `signalshift` **(owner: any unique SKU)** |
| Primary category | Games → Puzzle · secondary Games → Strategy |
| Age rating | Answer "None" or "No" for every content question (violence, sexual content, profanity, gambling, horror, mature themes, medical, user-generated content, unrestricted web). Expected result: 4+. Ads present: yes. In-app purchases: yes. |
| Price | Free (Tier 0) |
| Availability | All territories, or restrict **(owner)** |
| Export compliance | Uses no encryption beyond standard HTTPS from the OS and the ad SDK. Set `ITSAppUsesNonExemptEncryption` accordingly in the iOS preset (**owner** confirms with the installed SDKs) |
| Content rights | Original artwork, audio and puzzles. Outfit font is SIL OFL (`assets/fonts/OFL.txt`). |
| App Privacy ("nutrition label") | Data **used to track you** and **linked/not linked** follow Google's current "AdMob and Apple App Privacy" guidance for the installed SDK. Typical: Identifiers (Device ID) and Usage Data for Third-Party Advertising. Not collected by the developer: no accounts, no analytics. |
| App Tracking Transparency | If the ad SDK reads the IDFA, add `NSUserTrackingUsageDescription` and show the ATT prompt before ad requests. Without ATT, the SDK serves non-personalized ads (**owner decides**). |
| Privacy policy URL | required, see section 1 |
| Sign-in required for review | No; **no demo account** needed |

**App Review notes** (paste into the review information box):

```text
Signal Shift is a single-player offline logic puzzle. No account or login is needed.
Tap tiles to rotate them and connect the glowing source to every receiver.
Ads: optional rewarded videos (hint button -> "Watch video") using Google AdMob.
Purchases: non-consumable packs and a Supporter Pass on the Packs tab; Restore Purchases is in Settings.
```

## 6. Release blockers found while writing this (read before submitting)

1. **No billing plugin is installed.** `project.godot` sets `purchase_backend_script=""`, so every purchase button
   shows "Store unavailable". Do not submit with in-app purchases declared until a Google Play Billing and a
   StoreKit adapter are in (see `PLUGIN_INTEGRATION.md`), or remove the purchase text from the listing and declare
   "no in-app purchases" for that build.
2. **AdMob is on test ad unit IDs.** `scripts/services/backends/admob_ad_units.gd` has `USE_TEST_IDS := true` and
   empty real IDs. Create ad units in AdMob, fill them in, and flip the flag before release. Also set the real
   AdMob app IDs for Android and iOS, and integrate the UMP consent flow (required in the EEA/UK).
3. **Privacy policy was stale.** It said "no ads"; it now names AdMob. Re-read it once the SDK list is final.
4. **The old listing text promised "no forced ads"**, but non-Supporters get an unrewarded ad break after every 5th
   rewarded ad (`FORCED_BREAK_EVERY` in `ads_service.gd`). The text above discloses this. If you remove the break,
   update the description and the "contains ads" answers together.
5. Signing needs your keystore (Android) and Apple team/provisioning (iOS); see `RELEASE_CHECKLIST.md`.

## 7. Submission order

1. Fix the blockers above; bump versions; run `./tools/run_tests.sh`.
2. Build a signed `.aab` and an iOS archive (`RELEASE_CHECKLIST.md`).
3. Play Console: create app → store listing (sections 2–3) → declarations (section 5) → upload to internal/closed
   testing → production.
4. App Store Connect: create app → version page (sections 2–3) → App Privacy and age rating → in-app purchases →
   upload build with Xcode Organizer → TestFlight → submit for review.

## 8. Regenerating the screenshots

Needs a desktop window (not `--headless`). `--size` renders offscreen at the exact store resolution.

```sh
godot --path . res://tools/capture.tscn -- --size=1290x2796 --scene=res://scenes/menus/main_menu.tscn --out=/path/01_main_menu.png
godot --path . res://tools/capture.tscn -- --size=1290x2796 --scene=res://scenes/game/game.tscn --level=c012 --out=/path/02_mid_solve.png
godot --path . res://tools/capture.tscn -- --size=1290x2796 --scene=res://scenes/game/game.tscn --level=c045 --solve --out=/path/03_solved.png
godot --path . res://tools/capture.tscn -- --size=1290x2796 --scene=res://scenes/menus/level_select.tscn --out=/path/04_level_select.png
godot --path . res://tools/capture.tscn -- --size=1290x2796 --scene=res://scenes/game/game.tscn --daily --out=/path/05_daily.png
godot --path . res://tools/capture.tscn -- --size=1290x2796 --scene=res://scenes/game/game.tscn --level=q12 --out=/path/06_pack_level.png
```

Use `--size=1080x1920` for the Play set. The icon exports were made from `icon.svg` with the corner radius removed
(square, opaque for the App Store).
