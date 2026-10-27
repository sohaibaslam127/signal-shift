class_name ProgressionData
extends RefCounted
## Versioned player progress and settings. Pure data: (de)serialisation and validation only.

const CURRENT_VERSION := 1
const STARTING_HINT_TOKENS := 3
const MAX_HINT_TOKENS := 99
const MAX_DAILY_HISTORY := 400
## Seconds between free hints earned from the main-menu video.
const AD_HINT_COOLDOWN := 86400

var version: int = CURRENT_VERSION
## Number of campaign levels the player may open (always at least 1).
var unlocked_campaign_levels: int = 1
## level_id -> { "completed": bool, "stars": int, "best_moves": int }
var level_records: Dictionary = {}
var last_played_level_id: String = ""
var hint_tokens: int = STARTING_HINT_TOKENS
## ISO date of the last daily hint-pool reset ("" if never reset yet).
var hints_reset_date: String = ""
## Hint-less-solve bonus grants already used since the last reset (see grant_hint_solve_bonus).
var bonus_hint_events_today: int = 0
## ISO dates ("YYYY-MM-DD") of completed daily puzzles.
var daily_completed: PackedStringArray = PackedStringArray()
## Unix time of the last free hint earned from the main-menu video (0 = never).
var last_ad_hint_time: int = 0

## Lifetime count of rewarded ads watched for a hint or a pack-level unlock (not other placements).
var rewarded_ad_count: int = 0
## Set every 5th countable rewarded ad for a non-Supporter player; cleared once shown in a level.
var pending_forced_ad: bool = false
## pack_id -> number of levels unlocked beyond the free preview by watching ads, one level per ad.
var pack_ad_unlocks: Dictionary = {}
## The single premium pack granted free on a Supporter purchase ("" if not chosen yet).
var premium_bonus_pack_id: String = ""

var sound_enabled: bool = true
var music_enabled: bool = true
var haptics_enabled: bool = true
var reduced_motion: bool = false

## Last entitlements reported by the purchase backend. A cache for display only:
## it is never treated as proof of purchase (see PurchaseService).
var entitlement_cache: PackedStringArray = PackedStringArray()


func is_completed(level_id: String) -> bool:
	var record: Dictionary = level_records.get(level_id, {})
	return bool(record.get("completed", false))


func get_stars(level_id: String) -> int:
	var record: Dictionary = level_records.get(level_id, {})
	return int(record.get("stars", 0))


func get_best_moves(level_id: String) -> int:
	var record: Dictionary = level_records.get(level_id, {})
	return int(record.get("best_moves", 0))


## Records a completion. Keeps the best stars and the lowest move count.
## Returns true if this improved the stored record.
func record_completion(level_id: String, moves: int, stars: int) -> bool:
	var record: Dictionary = level_records.get(level_id, {})
	var improved := not bool(record.get("completed", false))
	var best := int(record.get("best_moves", 0))
	if best <= 0 or moves < best:
		best = moves
		improved = true
	var best_stars := int(record.get("stars", 0))
	if stars > best_stars:
		best_stars = stars
		improved = true
	level_records[level_id] = {"completed": true, "stars": clampi(best_stars, 0, 3), "best_moves": best}
	return improved


func is_daily_completed(date_key: String) -> bool:
	return daily_completed.has(date_key)


## Marks a daily puzzle as completed. Returns true only the first time for that date.
func mark_daily_completed(date_key: String) -> bool:
	if daily_completed.has(date_key):
		return false
	daily_completed.append(date_key)
	while daily_completed.size() > MAX_DAILY_HISTORY:
		daily_completed.remove_at(0)
	return true


func add_hint_tokens(amount: int) -> void:
	hint_tokens = clampi(hint_tokens + amount, 0, MAX_HINT_TOKENS)


## Resets the daily hint pool to `baseline` once per calendar day. Any hints left over from
## today (free top-ups included) are lost at the reset, matching the "never more than the
## daily allowance carries over" rule. Returns true the first time this runs for `today_key`.
func reset_daily_hints_if_needed(today_key: String, baseline: int) -> bool:
	if hints_reset_date == today_key:
		return false
	hints_reset_date = today_key
	hint_tokens = clampi(baseline, 0, MAX_HINT_TOKENS)
	bonus_hint_events_today = 0
	return true


## Rewards solving a level without using a hint. Limited to `max_events` grants per day
## (separate for free/Supporter players). Returns true if the bonus was granted.
func grant_hint_solve_bonus(amount: int, max_events: int) -> bool:
	if bonus_hint_events_today >= max_events:
		return false
	bonus_hint_events_today += 1
	add_hint_tokens(amount)
	return true


## Levels of `pack_id` playable for free: the preview plus whatever has been ad-unlocked.
func free_levels_unlocked(pack_id: String, preview_levels: int) -> int:
	return preview_levels + maxi(0, int(pack_ad_unlocks.get(pack_id, 0)))


## Unlocks exactly one more level of `pack_id` (the reward for watching a rewarded ad).
func unlock_pack_level_via_ad(pack_id: String) -> void:
	pack_ad_unlocks[pack_id] = int(pack_ad_unlocks.get(pack_id, 0)) + 1


func total_stars(level_ids: PackedStringArray) -> int:
	var total := 0
	for level_id in level_ids:
		total += get_stars(level_id)
	return total


func to_dict() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"unlocked_campaign_levels": unlocked_campaign_levels,
		"level_records": level_records.duplicate(true),
		"last_played_level_id": last_played_level_id,
		"hint_tokens": hint_tokens,
		"hints_reset_date": hints_reset_date,
		"bonus_hint_events_today": bonus_hint_events_today,
		"daily_completed": Array(daily_completed),
		"last_ad_hint_time": last_ad_hint_time,
		"rewarded_ad_count": rewarded_ad_count,
		"pending_forced_ad": pending_forced_ad,
		"pack_ad_unlocks": pack_ad_unlocks.duplicate(),
		"premium_bonus_pack_id": premium_bonus_pack_id,
		"settings": {
			"sound_enabled": sound_enabled,
			"music_enabled": music_enabled,
			"haptics_enabled": haptics_enabled,
			"reduced_motion": reduced_motion,
		},
		"entitlement_cache": Array(entitlement_cache),
	}


## Builds progression from untrusted data. Invalid or missing fields fall back to defaults,
## so a partially corrupted save never crashes the game or grants impossible values.
static func from_dict(data: Variant) -> ProgressionData:
	var result := ProgressionData.new()
	if typeof(data) != TYPE_DICTIONARY:
		return result
	var dict: Dictionary = data
	var source_version := _read_int(dict, "version", 0)
	result.version = CURRENT_VERSION
	if source_version > CURRENT_VERSION:
		push_warning("Save data is from a newer version (%d); reading known fields only." % source_version)

	result.unlocked_campaign_levels = maxi(1, _read_int(dict, "unlocked_campaign_levels", 1))
	result.last_played_level_id = _read_string(dict, "last_played_level_id", "")
	result.hint_tokens = clampi(_read_int(dict, "hint_tokens", STARTING_HINT_TOKENS), 0, MAX_HINT_TOKENS)
	var reset_date := _read_string(dict, "hints_reset_date", "")
	result.hints_reset_date = reset_date if reset_date.is_empty() or _is_date_key(reset_date) else ""
	result.bonus_hint_events_today = maxi(0, _read_int(dict, "bonus_hint_events_today", 0))
	result.last_ad_hint_time = maxi(0, _read_int(dict, "last_ad_hint_time", 0))
	result.rewarded_ad_count = maxi(0, _read_int(dict, "rewarded_ad_count", 0))
	result.pending_forced_ad = _read_bool(dict, "pending_forced_ad", false)
	result.premium_bonus_pack_id = _read_string(dict, "premium_bonus_pack_id", "")

	var ad_unlocks: Variant = dict.get("pack_ad_unlocks", {})
	if typeof(ad_unlocks) == TYPE_DICTIONARY:
		for key: Variant in ad_unlocks:
			if typeof(key) == TYPE_STRING:
				result.pack_ad_unlocks[key] = maxi(0, _read_int(ad_unlocks, String(key), 0))

	var records: Variant = dict.get("level_records", {})
	if typeof(records) == TYPE_DICTIONARY:
		for key: Variant in records:
			var raw: Variant = records[key]
			if typeof(key) != TYPE_STRING or typeof(raw) != TYPE_DICTIONARY:
				continue
			var stars := clampi(_read_int(raw, "stars", 0), 0, 3)
			var best := maxi(0, _read_int(raw, "best_moves", 0))
			var completed := _read_bool(raw, "completed", false)
			result.level_records[key] = {"completed": completed, "stars": stars, "best_moves": best}

	var dailies: Variant = dict.get("daily_completed", [])
	if typeof(dailies) == TYPE_ARRAY or typeof(dailies) == TYPE_PACKED_STRING_ARRAY:
		for entry: Variant in dailies:
			if typeof(entry) == TYPE_STRING and _is_date_key(entry) and not result.daily_completed.has(entry):
				result.daily_completed.append(entry)

	var settings: Variant = dict.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY:
		result.sound_enabled = _read_bool(settings, "sound_enabled", true)
		result.music_enabled = _read_bool(settings, "music_enabled", true)
		result.haptics_enabled = _read_bool(settings, "haptics_enabled", true)
		result.reduced_motion = _read_bool(settings, "reduced_motion", false)

	var cache: Variant = dict.get("entitlement_cache", [])
	if typeof(cache) == TYPE_ARRAY or typeof(cache) == TYPE_PACKED_STRING_ARRAY:
		for entry: Variant in cache:
			if typeof(entry) == TYPE_STRING and not result.entitlement_cache.has(entry):
				result.entitlement_cache.append(entry)
	return result


static func _read_int(dict: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = dict.get(key, fallback)
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_FLOAT and is_finite(value):
		return int(value)
	return fallback


static func _read_bool(dict: Dictionary, key: String, fallback: bool) -> bool:
	var value: Variant = dict.get(key, fallback)
	return value if typeof(value) == TYPE_BOOL else fallback


static func _read_string(dict: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = dict.get(key, fallback)
	return value if typeof(value) == TYPE_STRING else fallback


static func _is_date_key(value: String) -> bool:
	if value.length() != 10 or value[4] != "-" or value[7] != "-":
		return false
	return value.substr(0, 4).is_valid_int() and value.substr(5, 2).is_valid_int() and value.substr(8, 2).is_valid_int()
