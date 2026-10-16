extends Node
## Owns app-wide game state: the puzzle catalog, which puzzle is being played,
## campaign unlocking, and saving on pause/quit.

enum Mode { CAMPAIGN, DAILY, PACK }

const CAMPAIGN_PACK_ID := "campaign"

var catalog: LevelCatalog = LevelCatalog.new()
var current_puzzle: PuzzleData
var current_mode: Mode = Mode.CAMPAIGN
## Date key of the daily puzzle being played (Mode.DAILY only).
var current_daily_key: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Loads bundled content. Returns an empty string on success or a player-facing error.
func load_content() -> String:
	catalog.load_manifest()
	for error in catalog.errors:
		push_error("Content: %s" % error)
	var campaign := campaign_pack()
	if campaign == null or campaign.puzzles.is_empty():
		return "Could not load puzzles. Please reinstall the game."
	return ""


func campaign_pack() -> LevelCatalog.Pack:
	return catalog.get_pack(CAMPAIGN_PACK_ID)


func has_progress() -> bool:
	return not SaveService.progress.level_records.is_empty()


func is_campaign_level_unlocked(index: int) -> bool:
	return index >= 0 and index < SaveService.progress.unlocked_campaign_levels


## The puzzle "Continue" should open: the last played campaign level if unfinished,
## otherwise the first unlocked level that is not completed yet.
func continue_puzzle() -> PuzzleData:
	var campaign := campaign_pack()
	var progress := SaveService.progress
	var last := catalog.get_puzzle(progress.last_played_level_id)
	if last != null and last.pack_id == CAMPAIGN_PACK_ID and not progress.is_completed(last.id):
		return last
	var unlocked := mini(progress.unlocked_campaign_levels, campaign.puzzles.size())
	for i in unlocked:
		if not progress.is_completed(campaign.puzzles[i].id):
			return campaign.puzzles[i]
	return campaign.puzzles[unlocked - 1]


func play(puzzle: PuzzleData, mode: Mode = Mode.CAMPAIGN) -> void:
	current_puzzle = puzzle
	current_mode = mode
	if mode != Mode.DAILY:
		current_daily_key = ""
		SaveService.progress.last_played_level_id = puzzle.id
	SceneRouter.goto(SceneRouter.GAME)


## Records a win, unlocks the next campaign level and saves.
## Returns { first_clear, new_best, best_moves, reward } for the result screen.
func complete_current(moves: int, stars: int) -> Dictionary:
	var progress := SaveService.progress
	var first_clear := not progress.is_completed(current_puzzle.id)
	var previous_best := progress.get_best_moves(current_puzzle.id)
	progress.record_completion(current_puzzle.id, moves, stars)
	if current_mode == Mode.CAMPAIGN and current_puzzle.pack_id == CAMPAIGN_PACK_ID:
		var campaign := campaign_pack()
		progress.unlocked_campaign_levels = clampi(
			maxi(progress.unlocked_campaign_levels, current_puzzle.pack_index + 2), 1, campaign.puzzles.size())
	var outcome := {
		"first_clear": first_clear,
		"new_best": previous_best > 0 and moves < previous_best,
		"best_moves": progress.get_best_moves(current_puzzle.id),
		"reward": "",
	}
	SaveService.save_progress()
	SignalBus.progress_changed.emit()
	return outcome


## Next puzzle in the same pack, or null at the end of the pack.
func next_puzzle() -> PuzzleData:
	if current_puzzle == null or current_mode == Mode.DAILY:
		return null
	var pack := catalog.get_pack(current_puzzle.pack_id)
	if pack == null or current_puzzle.pack_index + 1 >= pack.puzzles.size():
		return null
	return pack.puzzles[current_puzzle.pack_index + 1]


func can_play(puzzle: PuzzleData) -> bool:
	if puzzle == null:
		return false
	if puzzle.pack_id == CAMPAIGN_PACK_ID:
		return is_campaign_level_unlocked(puzzle.pack_index)
	return true


func chapter_title(puzzle: PuzzleData) -> String:
	var pack := catalog.get_pack(puzzle.pack_id)
	if pack == null:
		return ""
	var chapter := pack.chapter_of(puzzle.pack_index)
	if chapter < 0:
		return pack.title
	return "%s · %s" % [pack.title if pack.kind != "campaign" else "Chapter %d" % (chapter + 1), pack.chapters[chapter]["title"]]


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT:
			SaveService.save_progress()
