extends "res://tests/test_case.gd"
## Daily puzzle selection and reward rules.

const Daily := preload("res://scripts/services/daily_puzzle_service.gd")


func test_date_key_format() -> void:
	assert_eq(Daily.date_key({"year": 2026, "month": 3, "day": 7}), "2026-03-07", "zero padded")


func test_same_date_same_puzzle() -> void:
	assert_eq(Daily.index_for("2026-10-16", 90), Daily.index_for("2026-10-16", 90), "deterministic")
	assert_ne(Daily.index_for("2026-10-16", 90), Daily.index_for("2026-10-17", 90), "next day differs")


func test_day_numbers_are_consecutive() -> void:
	assert_eq(Daily.day_number("1970-01-02"), 1, "epoch + 1")
	assert_eq(Daily.day_number("2026-03-01") - Daily.day_number("2026-02-28"), 1, "month boundary")
	assert_eq(Daily.day_number("2024-03-01") - Daily.day_number("2024-02-28"), 2, "leap day")
	assert_eq(Daily.day_number("2027-01-01") - Daily.day_number("2026-12-31"), 1, "year boundary")


func test_cycle_covers_every_puzzle() -> void:
	var seen := {}
	var start := Daily.day_number("2026-01-01")
	for d in 90:
		var date := Time.get_date_dict_from_unix_time((start + d) * 86400 + 43200)
		seen[Daily.index_for(Daily.date_key(date), 90)] = true
	assert_eq(seen.size(), 90, "90 consecutive days use 90 different puzzles")


func test_malformed_key() -> void:
	assert_eq(Daily.index_for("not-a-date", 90), -1, "malformed")
	assert_eq(Daily.index_for("2026-10-16", 0), -1, "empty pack")


func test_reward_granted_once() -> void:
	var service: Node = Daily.new()
	var progress := ProgressionData.new()
	var before := progress.hint_tokens
	assert_false(service.complete("2026-10-16", progress).is_empty(), "first completion rewards")
	assert_eq(progress.hint_tokens, before + Daily.REWARD_HINTS, "hint granted")
	assert_true(service.complete("2026-10-16", progress).is_empty(), "replay gives no reward")
	assert_eq(progress.hint_tokens, before + Daily.REWARD_HINTS, "no extra hint")
	assert_false(service.complete("2026-10-18", progress).is_empty(), "skipping a day is not punished")
	service.free()


func test_daily_pack_in_catalog() -> void:
	var catalog := LevelCatalog.new()
	catalog.load_manifest()
	var pack := catalog.get_pack("daily")
	assert_true(pack != null and pack.kind == "daily", "daily pack registered")
	assert_eq(pack.puzzles.size(), 90, "90 daily puzzles")
