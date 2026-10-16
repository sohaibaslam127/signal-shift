extends "res://tests/test_case.gd"
## Save/load round trips, corruption recovery and sanitising of untrusted save data.

const SaveServiceScript := preload("res://scripts/services/save_service.gd")
const TEST_PATH := "user://test_save.json"

var _service: Node


func before_each() -> void:
	_service = SaveServiceScript.new()
	_service.save_path = TEST_PATH
	_service.delete_save()


func after_each() -> void:
	_service.delete_save()
	_service.free()


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_missing_save_gives_defaults() -> void:
	var progress: ProgressionData = _service.load_progress()
	assert_eq(_service.last_load_status, "missing", "status")
	assert_eq(progress.unlocked_campaign_levels, 1, "first level unlocked")
	assert_eq(progress.hint_tokens, ProgressionData.STARTING_HINT_TOKENS, "starting hints")
	assert_true(progress.sound_enabled, "sound on by default")


func test_round_trip() -> void:
	var progress: ProgressionData = _service.progress
	progress.unlocked_campaign_levels = 7
	progress.record_completion("c001", 5, 3)
	progress.record_completion("c002", 9, 2)
	progress.mark_daily_completed("2026-10-16")
	progress.hint_tokens = 4
	progress.music_enabled = false
	progress.reduced_motion = true
	progress.last_played_level_id = "c003"
	assert_true(_service.save_progress(), "saved")
	var loaded: ProgressionData = _service.load_progress()
	assert_eq(_service.last_load_status, "ok", "status")
	assert_eq(loaded.unlocked_campaign_levels, 7, "unlocked")
	assert_eq(loaded.get_stars("c001"), 3, "stars")
	assert_eq(loaded.get_best_moves("c002"), 9, "best moves")
	assert_true(loaded.is_completed("c002"), "completed")
	assert_true(loaded.is_daily_completed("2026-10-16"), "daily")
	assert_eq(loaded.hint_tokens, 4, "hints")
	assert_false(loaded.music_enabled, "music setting")
	assert_true(loaded.reduced_motion, "reduced motion")
	assert_eq(loaded.last_played_level_id, "c003", "last played")
	assert_eq(loaded.version, ProgressionData.CURRENT_VERSION, "version")


func test_best_record_kept() -> void:
	var progress := ProgressionData.new()
	progress.record_completion("c001", 8, 2)
	progress.record_completion("c001", 12, 1)
	assert_eq(progress.get_best_moves("c001"), 8, "lowest moves kept")
	assert_eq(progress.get_stars("c001"), 2, "highest stars kept")
	assert_true(progress.record_completion("c001", 5, 3), "improvement reported")
	assert_eq(progress.get_best_moves("c001"), 5, "new best")


func test_corrupted_save_restores_backup() -> void:
	_service.progress.unlocked_campaign_levels = 4
	_service.save_progress()
	_service.progress.unlocked_campaign_levels = 5
	_service.save_progress()  # previous valid save becomes the backup
	_write(TEST_PATH, "{ this is not json")
	var loaded: ProgressionData = _service.load_progress()
	assert_eq(_service.last_load_status, "restored_from_backup", "status")
	assert_eq(loaded.unlocked_campaign_levels, 4, "backup content")


func test_corrupted_without_backup_resets() -> void:
	_write(TEST_PATH, "[1, 2, 3]")
	var loaded: ProgressionData = _service.load_progress()
	assert_eq(_service.last_load_status, "corrupted_reset", "status")
	assert_eq(loaded.unlocked_campaign_levels, 1, "defaults")


func test_untrusted_values_are_sanitised() -> void:
	var loaded := ProgressionData.from_dict({
		"version": 99,
		"unlocked_campaign_levels": -5,
		"hint_tokens": 100000,
		"level_records": {"c001": {"completed": "yes", "stars": 12, "best_moves": -3}, "bad": 7},
		"daily_completed": ["2026-10-16", "not-a-date", 42, "2026-10-16"],
		"settings": {"sound_enabled": "off"},
		"entitlement_cache": ["pack_overclock", 5],
	})
	assert_eq(loaded.unlocked_campaign_levels, 1, "clamped unlocked")
	assert_eq(loaded.hint_tokens, ProgressionData.MAX_HINT_TOKENS, "clamped hints")
	assert_eq(loaded.get_stars("c001"), 3, "clamped stars")
	assert_eq(loaded.get_best_moves("c001"), 0, "clamped moves")
	assert_false(loaded.is_completed("c001"), "non-bool completed ignored")
	assert_false(loaded.level_records.has("bad"), "bad record dropped")
	assert_eq(loaded.daily_completed.size(), 1, "only valid unique dates")
	assert_true(loaded.sound_enabled, "invalid setting falls back to default")
	assert_eq(loaded.entitlement_cache, PackedStringArray(["pack_overclock"]), "cache strings only")


func test_settings_and_level_select_scenes_load() -> void:
	for path in ["res://scenes/menus/settings.tscn", "res://scenes/menus/level_select.tscn", "res://scenes/game/game.tscn"]:
		var scene: PackedScene = load(path)
		assert_true(scene != null and scene.can_instantiate(), "%s loads" % path)
