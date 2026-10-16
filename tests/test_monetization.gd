extends "res://tests/test_case.gd"
## Rewarded ads grant only on the SDK reward event; purchases come only from the store backend.

const AdsServiceScript := preload("res://scripts/services/ads_service.gd")
const PurchaseServiceScript := preload("res://scripts/services/purchase_service.gd")
const FakeAds := preload("res://tests/fakes/fake_ads_backend.gd")
const FakeStore := preload("res://tests/fakes/fake_purchase_backend.gd")

var _ads: Node
var _store: Node
var _saved_cache: PackedStringArray


func before_each() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	_ads = AdsServiceScript.new()
	root.add_child(_ads)
	_saved_cache = SaveService.progress.entitlement_cache.duplicate()
	_store = PurchaseServiceScript.new()
	root.add_child(_store)


func after_each() -> void:
	_ads.queue_free()
	_store.queue_free()
	SaveService.progress.entitlement_cache = _saved_cache


func _frames(count: int = 3) -> void:
	for i in count:
		await (Engine.get_main_loop() as SceneTree).process_frame


func test_no_sdk_means_no_reward() -> void:
	assert_false(_ads.is_available(), "default backend has no ads")
	var outcome: Dictionary = await _ads.request_reward("hint")
	assert_false(outcome["granted"], "nothing granted")
	assert_false(str(outcome["message"]).is_empty(), "friendly message")


func test_reward_after_reward_event() -> void:
	var fake := FakeAds.new()
	_ads.set_backend(fake)
	var outcome: Dictionary = await _ads.request_reward("hint")
	assert_true(outcome["granted"], "granted after reward_earned")
	assert_eq(fake.shows, 1, "shown once")


func test_closed_early_grants_nothing() -> void:
	var fake := FakeAds.new()
	fake.mode = "close"
	_ads.set_backend(fake)
	var outcome: Dictionary = await _ads.request_reward("hint")
	assert_false(outcome["granted"], "closing early does not reward")


func test_load_and_show_failures_grant_nothing() -> void:
	for mode in ["load_fail", "show_fail"]:
		var fake := FakeAds.new()
		fake.mode = mode
		_ads.set_backend(fake)
		var outcome: Dictionary = await _ads.request_reward("hint")
		assert_false(outcome["granted"], "%s grants nothing" % mode)
		assert_false(_ads.is_busy(), "%s leaves service idle" % mode)


func test_no_billing_owns_nothing_even_with_cached_flag() -> void:
	SaveService.progress.entitlement_cache = PackedStringArray(["pack_overclock", "supporter"])
	_store.set_backend(PurchaseBackend.new())
	assert_false(_store.owns("pack_overclock"), "local cache is not proof of purchase")
	assert_false(_store.is_supporter(), "no supporter without store")
	var outcome: Dictionary = await _store.purchase("pack_overclock")
	assert_false(outcome["success"], "purchase fails without billing")
	var restore: Dictionary = await _store.restore_purchases()
	assert_eq(restore["restored"], 0, "nothing restored")


func test_purchase_success_from_store() -> void:
	var fake := FakeStore.new()
	_store.set_backend(fake)
	await _frames()
	assert_eq(_store.price_of("pack_overclock"), "$1.99", "price from store")
	var outcome: Dictionary = await _store.purchase("pack_overclock")
	assert_true(outcome["success"], "store confirmed")
	assert_true(_store.owns("pack_overclock"), "entitled")


func test_purchase_cancel_and_fail() -> void:
	var fake := FakeStore.new()
	_store.set_backend(fake)
	fake.mode = "cancel"
	var cancelled: Dictionary = await _store.purchase("supporter")
	assert_true(cancelled["cancelled"], "cancelled flagged")
	assert_false(_store.owns("supporter"), "not owned after cancel")
	fake.mode = "fail"
	var failed: Dictionary = await _store.purchase("supporter")
	assert_false(failed["success"], "failed")
	assert_false(_store.owns("supporter"), "not owned after failure")
	assert_false(_store.is_busy(), "idle afterwards")


func test_restore_reads_store_ownership() -> void:
	var fake := FakeStore.new()
	fake.store_owned = PackedStringArray(["supporter", "unknown_sku"])
	_store.set_backend(fake)
	var outcome: Dictionary = await _store.restore_purchases()
	assert_eq(outcome["restored"], 1, "only known products count")
	assert_true(_store.is_supporter(), "restored entitlement")
	assert_false(_store.owns("unknown_sku"), "unknown products ignored")


func test_unknown_product_rejected() -> void:
	_store.set_backend(FakeStore.new())
	var outcome: Dictionary = await _store.purchase("free_money")
	assert_false(outcome["success"], "unknown product")


func test_extend_moves_only_after_failure() -> void:
	var controller := PuzzleController.new()
	controller.start(PuzzleData.from_dict({"id": "t", "rows": ["S1* I0 I0 D3*", ". . . ."], "solution": ["1113", "0000"], "par": 2, "move_limit": 2}))
	assert_false(controller.extend_moves(3), "cannot extend while playing")
	controller.tap(1)
	controller.tap(1)
	assert_eq(controller.state, PuzzleController.State.FAILED, "failed")
	assert_true(controller.extend_moves(3), "bonus moves")
	assert_eq(controller.moves_left(), 3, "three more moves")
	assert_eq(controller.puzzle.move_limit, 2, "catalog puzzle unchanged")


func test_backend_detection_falls_back_safely() -> void:
	ProjectSettings.set_setting("signal_shift/purchase_backend_script", "res://does/not/exist.gd")
	ProjectSettings.set_setting("signal_shift/ads_backend_script", "res://tests/test_case.gd")  # wrong type
	assert_false(_store.call("_detect_backend").is_available(), "missing adapter -> no billing")
	assert_false(_ads.call("_detect_backend").is_available(), "wrong type -> no ads")
	ProjectSettings.set_setting("signal_shift/ads_backend_script", "res://tests/fakes/fake_ads_backend.gd")
	assert_true(_ads.call("_detect_backend").is_available(), "valid adapter is picked up")
	ProjectSettings.set_setting("signal_shift/purchase_backend_script", "")
	ProjectSettings.set_setting("signal_shift/ads_backend_script", "")
