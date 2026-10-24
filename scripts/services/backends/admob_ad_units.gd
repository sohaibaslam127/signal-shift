class_name AdmobAdUnits
extends RefCounted
## Rewarded ad unit IDs for AdMobBackend.
##
## USE_TEST_IDS is on, so every rewarded ad request uses Google's published test ad unit IDs
## below — they always serve clearly-labelled test ads and are safe to ship while developing.
## Once real AdMob ad units exist, fill in REWARDED_ANDROID / REWARDED_IOS and set
## USE_TEST_IDS to false.

const USE_TEST_IDS := true

## Google's public test rewarded ad unit IDs (https://developers.google.com/admob/android/test-ads,
## https://developers.google.com/admob/ios/test-ads). Never ship these as real ad units.
const REWARDED_TEST_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const REWARDED_TEST_IOS := "ca-app-pub-3940256099942544/1712485313"

## TODO: set your real rewarded ad unit IDs here, then flip USE_TEST_IDS to false.
const REWARDED_ANDROID := ""
const REWARDED_IOS := ""


static func rewarded_ad_unit_id() -> String:
	var is_ios := OS.get_name() == "iOS"
	if not USE_TEST_IDS:
		var real := REWARDED_IOS if is_ios else REWARDED_ANDROID
		if not real.is_empty():
			return real
	return REWARDED_TEST_IOS if is_ios else REWARDED_TEST_ANDROID
