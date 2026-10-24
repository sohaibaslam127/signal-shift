class_name AdMobBackend
extends AdsBackend
## Wraps the Poing Studios AdMob plugin (addons/admob) behind AdsService's AdsBackend contract.
## Only rewarded ads are used; the ad unit ID comes from AdmobAdUnits (test IDs until that
## file's real ones are filled in). Selected per platform in project.godot
## ([signal_shift] ads_backend_script.android / .ios); never the active backend on desktop.
##
## GDPR/UMP consent is not wired up yet — required before an EEA/UK release.
## See docs/PLUGIN_INTEGRATION.md step 5 and addons/admob/gdscript/src/ump.

var _initialized := false
var _initializing := false
var _loaded_ad: RewardedAd
var _loader := RewardedAdLoader.new()


func _init() -> void:
	_ensure_initialized(Callable())


func is_available() -> bool:
	return _initialized


func is_rewarded_ready() -> bool:
	return _loaded_ad != null


func load_rewarded(placement: String) -> void:
	if not _initialized:
		_ensure_initialized(load_rewarded.bind(placement))
		return
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loaded_ad = ad
		rewarded_loaded.emit()
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		rewarded_load_failed.emit(error.message)
	_loader.load(AdmobAdUnits.rewarded_ad_unit_id(), AdRequest.new(), callback)


func show_rewarded(_placement: String) -> void:
	var ad := _loaded_ad
	if ad == null:
		rewarded_show_failed.emit("No ad is loaded.")
		return
	_loaded_ad = null

	var content_callback := FullScreenContentCallback.new()
	content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad.destroy()
		rewarded_closed.emit()
	content_callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		ad.destroy()
		rewarded_show_failed.emit(error.message)
	ad.full_screen_content_callback = content_callback

	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		reward_earned.emit()
	ad.show(reward_listener)


func backend_name() -> String:
	return "admob"


## The Mobile Ads SDK must finish initialising before the first load; later calls are no-ops.
func _ensure_initialized(resume: Callable) -> void:
	if _initialized:
		if resume.is_valid():
			resume.call()
		return
	if _initializing:
		return
	_initializing = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_initializing = false
		_initialized = true
		if resume.is_valid():
			resume.call()
	MobileAds.initialize(listener)
