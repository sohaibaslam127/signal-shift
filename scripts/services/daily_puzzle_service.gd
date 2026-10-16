extends Node
## Deterministic daily puzzle selection from bundled, pre-verified content.
## The same calendar date always maps to the same puzzle, offline, on every device.
## Completing a day's puzzle grants a small non-premium reward once; missing days costs nothing.

const DAILY_PACK_ID := "daily"
const REWARD_HINTS := 1
## Multiplier coprime with the pack size spreads consecutive days across the pack.
const STRIDE := 37
const OFFSET := 11


## "YYYY-MM-DD" for a date dictionary with year/month/day keys.
static func date_key(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [int(date["year"]), int(date["month"]), int(date["day"])]


## Today's key in the player's local calendar.
static func today_key() -> String:
	return date_key(Time.get_date_dict_from_system())


## Whole days since 1970-01-01 for a date key, or -1 if the key is malformed.
static func day_number(key: String) -> int:
	var parts := key.split("-")
	if parts.size() != 3 or not (parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()):
		return -1
	var unix := Time.get_unix_time_from_datetime_dict({
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]), "hour": 12, "minute": 0, "second": 0,
	})
	return floori(unix / 86400.0)


## Index into a pack of `count` puzzles for the given date key.
static func index_for(key: String, count: int) -> int:
	if count <= 0:
		return -1
	var day := day_number(key)
	if day < 0:
		return -1
	return posmod(day * STRIDE + OFFSET, count)


func puzzle_for(key: String) -> PuzzleData:
	var pack := GameManager.catalog.get_pack(DAILY_PACK_ID)
	if pack == null:
		return null
	var index := index_for(key, pack.puzzles.size())
	return pack.puzzles[index] if index >= 0 else null


func today_puzzle() -> PuzzleData:
	return puzzle_for(today_key())


func is_completed(key: String) -> bool:
	return SaveService.progress.is_daily_completed(key)


## Marks the date completed. Returns the reward text on the first completion, else "".
func complete(key: String, progress: ProgressionData = null) -> String:
	if progress == null:
		progress = SaveService.progress
	if not progress.mark_daily_completed(key):
		return ""
	progress.add_hint_tokens(REWARD_HINTS)
	SignalBus.hint_tokens_changed.emit(progress.hint_tokens)
	return "Daily reward: +%d free hint" % REWARD_HINTS


func total_completed() -> int:
	return SaveService.progress.daily_completed.size()
