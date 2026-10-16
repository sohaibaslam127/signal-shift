# Mobile Plugin Integration (Milestone 8)

Status: **seams ready, plugins not installed.** The game runs with the built-in no-SDK
backends (`AdsBackend`, `PurchaseBackend`): ads report "unavailable", the store shows
"Store unavailable", and the free campaign + daily puzzles are fully playable.

Plugin code was deliberately not written ahead of time: each plugin's API differs by version,
and the spec requires verifying APIs against the exact plugin version in the project. Do the
steps below once a plugin version is chosen, then test on physical devices.

## How backends are selected

`AdsService._detect_backend()` and `PurchaseService._detect_backend()` read these project settings:

| Setting | Meaning |
| --- | --- |
| `signal_shift/ads_backend_script` | Script extending `AdsBackend` |
| `signal_shift/purchase_backend_script` | Script extending `PurchaseBackend` |

Use feature overrides so each platform gets its own adapter, for example in `project.godot`:

```ini
[signal_shift]
purchase_backend_script.android="res://scripts/services/backends/play_billing_backend.gd"
purchase_backend_script.ios="res://scripts/services/backends/storekit_backend.gd"
ads_backend_script.android="res://scripts/services/backends/admob_backend.gd"
ads_backend_script.ios="res://scripts/services/backends/admob_backend.gd"
```

If the script is missing, fails to load, or is not the right type, the no-SDK backend is used.

## Adapter contract

### `AdsBackend`
- `is_available()` → true once the SDK is initialised (and consent obtained, see below).
- `load_rewarded(placement)` → emit `rewarded_loaded` or `rewarded_load_failed(message)`.
- `show_rewarded(placement)` → emit `reward_earned` **only** from the SDK's
  "user earned reward" callback, then `rewarded_closed` when dismissed; or
  `rewarded_show_failed(message)`.
- Emit signals asynchronously (from plugin callbacks or `call_deferred`).

### `PurchaseBackend`
- `query_products(ids)` → `products_received([{id, title, price}])` with localised prices.
- `query_owned()` / `restore()` → `owned_products_received(ids)` from the store's purchase list.
- `purchase(id)` → `purchase_succeeded(id)` after the store confirms **and** the purchase is
  acknowledged/finished; `purchase_cancelled(id)` on user cancel; `purchase_failed(id, msg)` otherwise.
- Never emit success without a store transaction. Tests use fakes in `tests/fakes/`; the game never does.

Products (non-consumable), configured in Play Console and App Store Connect with identical IDs:

| Product ID | Content |
| --- | --- |
| `pack_overclock` | Overclock puzzle pack (20 levels) |
| `supporter` | Unlimited hints without optional videos |

## Candidate plugins (verify current versions before installing)

- Google Play Billing — official Godot SDK integration, Godot 4.2+, MIT:
  https://github.com/godot-sdk-integrations/godot-google-play-billing
  (Godot docs: https://docs.godotengine.org/en/stable/tutorials/platform/android/android_in_app_purchases.html).
  The docs' API changed between versions (`querySkuDetails` vs `BillingClient.query_product_details`) —
  write the adapter against the installed version only.
- StoreKit (iOS) — godot-sdk-integrations iOS plugins: https://github.com/godot-sdk-integrations
- AdMob (Android + iOS) — Poing Studios plugin, Godot 4.2+, MIT:
  https://godotengine.org/asset-library/asset/2063 and https://github.com/poingstudios/godot-admob-ios

## Steps

1. Install the plugin into `addons/` and enable it (Project → Project Settings → Plugins).
2. Android: Project → Install Android Build Template; enable *Use Gradle Build* in the Android export preset.
3. Write the adapter in `scripts/services/backends/`, mapping plugin callbacks to the signals above.
4. Set the project settings shown above.
5. AdMob: add the AdMob app ID per platform; use Google's **test ad unit IDs** until release.
   Integrate the UMP consent flow before `is_available()` returns true (required in the EEA/UK).
6. Billing: create the products, add license testers (Play) / sandbox testers (App Store).
7. Device test matrix (physical devices):
   - Rewarded hint: watch to the end → hint applied; close early → no hint; airplane mode → friendly message.
   - Bonus moves after "Out of Moves".
   - Buy pack: success → levels unlock; cancel → nothing charged, still locked; declined card → message.
   - Restore on a second device / after reinstall.
   - Kill the app mid-purchase, relaunch → ownership comes back from `query_owned()`.
   - Supporter: hints work with zero tokens and no video prompt.
8. Update `docs/PRIVACY_POLICY.md` and store data-safety forms: AdMob collects device identifiers.
