extends Control
## Gameplay screen: binds a PuzzleController to the board view and drives the HUD,
## pause menu, victory and out-of-moves dialogs.

const RESULT_SCENE := preload("res://scenes/game/puzzle_result.tscn")
const SETTINGS_SCENE := "res://scenes/menus/settings.tscn"
const BONUS_MOVES := 3

var controller := PuzzleController.new()
var _settings_overlay: Control

@onready var _board: PuzzleBoard = %Board
@onready var _title: Label = %LevelTitle
@onready var _chapter: Label = %ChapterLabel
@onready var _moves: Label = %MovesLabel
@onready var _par: Label = %ParLabel
@onready var _limit: Label = %LimitLabel
@onready var _pause_button: IconButton = %PauseButton
@onready var _undo_button: Button = %UndoButton
@onready var _reset_button: Button = %ResetButton
@onready var _hint_button: IconButton = %HintButton
@onready var _dialog: ModalDialog = %Dialog


func _ready() -> void:
	var puzzle := GameManager.current_puzzle
	if puzzle == null:
		# Opened directly (e.g. from the editor): fall back to the continue puzzle.
		if GameManager.campaign_pack() == null:
			GameManager.load_content()
		puzzle = GameManager.continue_puzzle()
		GameManager.current_puzzle = puzzle

	controller.moves_changed.connect(_on_moves_changed)
	controller.won.connect(_on_won)
	controller.failed.connect(_on_failed)
	_pause_button.pressed.connect(_open_pause)
	_undo_button.pressed.connect(_on_undo)
	_reset_button.pressed.connect(_on_reset)
	_hint_button.pressed.connect(_on_hint)
	SignalBus.hint_tokens_changed.connect(func(_tokens: int) -> void: _update_buttons())

	_title.text = "Daily Puzzle" if GameManager.current_mode == GameManager.Mode.DAILY else puzzle.name
	_chapter.text = _subtitle_for(puzzle)
	_par.text = str(puzzle.par)
	GameManager.refresh_daily_hints()
	controller.start(puzzle)
	_board.bind(controller)
	_update_buttons()
	_add_tutorial_tip(puzzle)
	_show_forced_ad_if_pending()


## Onboarding for the first campaign levels: one line, gone once the level is solved.
func _add_tutorial_tip(puzzle: PuzzleData) -> void:
	if puzzle.pack_id != GameManager.CAMPAIGN_PACK_ID or puzzle.pack_index > 2 or SaveService.progress.is_completed(puzzle.id):
		return
	const TIPS := [
		"Tap a tile to rotate it. Connect the glowing source to the ring.",
		"Corners turn the signal. Tiles with corner dots can't rotate.",
		"Aim for par — the fewest taps — to earn three stars.",
	]
	var tip := Label.new()
	tip.theme_type_variation = &"DimLabel"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.text = TIPS[puzzle.pack_index]
	var column := _board.get_parent().get_parent()
	column.add_child(tip)
	column.move_child(tip, _board.get_parent().get_index() + 1)
	controller.won.connect(func(_m: int, _s: int) -> void: tip.queue_free(), CONNECT_ONE_SHOT)


func handle_back() -> void:
	if is_instance_valid(_settings_overlay):
		_settings_overlay.call("handle_back")
		return
	if _dialog.is_open():
		if controller.is_playing():
			_dialog.close()
		return
	_open_pause()


func _pause_footer(puzzle: PuzzleData) -> String:
	if GameManager.current_mode == GameManager.Mode.DAILY:
		return "DAILY PUZZLE · %s" % GameManager.current_daily_key
	var pack := GameManager.catalog.get_pack(puzzle.pack_id)
	var total := pack.puzzles.size() if pack != null else 0
	return ("%s · LEVEL %d / %d" % [GameManager.chapter_title(puzzle), puzzle.pack_index + 1, total]).to_upper()


func _subtitle_for(puzzle: PuzzleData) -> String:
	if GameManager.current_mode == GameManager.Mode.DAILY:
		return "%s · #%d" % [GameManager.current_daily_key, puzzle.pack_index + 1]
	return GameManager.chapter_title(puzzle)


func _on_moves_changed(moves: int) -> void:
	_moves.text = str(moves)
	var limited := controller.move_limit > 0
	_limit.get_parent().visible = limited
	if limited:
		_limit.text = str(controller.moves_left())
	_update_buttons()


func _update_buttons() -> void:
	var playing := controller.is_playing()
	_undo_button.disabled = not controller.can_undo()
	_reset_button.disabled = not playing or controller.moves == 0
	_hint_button.disabled = not playing
	_hint_button.badge = SaveService.progress.hint_tokens
	_hint_button.tooltip_text = "Hint (%d left)" % SaveService.progress.hint_tokens
	_board.interactive = playing and not _dialog.is_open()


func _on_undo() -> void:
	if controller.undo():
		AudioService.play(&"undo")


func _on_reset() -> void:
	controller.reset()
	AudioService.play(&"undo", 0.8)


func _on_hint() -> void:
	if not controller.is_playing():
		return
	if controller.next_hint_cell() < 0:
		_show_message("No hint needed", "Every tile on the route is already in place.")
		return
	var progress := SaveService.progress
	if progress.hint_tokens > 0:
		progress.add_hint_tokens(-1)
		SaveService.save_progress()
		SignalBus.hint_tokens_changed.emit(progress.hint_tokens)
		_apply_hint()
	else:
		_offer_hint_video()


func _offer_hint_video() -> void:
	_dialog.prepare("Out of hints", "Watch a short optional video for one hint, or solve today's Daily Puzzle for a free one.")
	_dialog.add_button("Watch Video for a Hint", _watch_hint_video, &"AccentButton")
	_dialog.add_button("Not Now", _update_buttons)
	_open_dialog()


func _watch_hint_video() -> void:
	_board.interactive = false
	var outcome: Dictionary = await AdsService.request_reward("hint")
	if not is_inside_tree():
		return
	if outcome["granted"] and controller.is_playing():
		_apply_hint()
		_update_buttons()
	else:
		_show_message("No video available", outcome["message"])


## Every 5th rewarded ad (hints + pack unlocks) owes one forced, unrewarded ad break for
## non-Supporter players. It only ever shows here, in a level, never as a surprise elsewhere.
func _show_forced_ad_if_pending() -> void:
	var progress := SaveService.progress
	if not progress.pending_forced_ad or PurchaseService.is_supporter():
		return
	progress.pending_forced_ad = false
	SaveService.save_progress()
	await AdsService.request_reward("forced_break")


func _apply_hint() -> void:
	var index := controller.apply_hint()
	if index >= 0:
		_board.highlight_hint(index)
		AudioService.play(&"rotate", 1.2)


func _show_message(title: String, body: String) -> void:
	_dialog.prepare(title, body)
	_dialog.add_button("OK", _update_buttons, &"PrimaryButton")
	_open_dialog()


func _open_dialog() -> void:
	_dialog.popup()
	_board.interactive = false


func _open_pause() -> void:
	if _dialog.is_open() or SceneRouter.is_transitioning:
		return
	var puzzle := controller.puzzle
	_dialog.prepare("PAUSED", puzzle.name.to_upper(), Palette.CIRCUIT)
	_dialog.set_header_icon(&"pause", Palette.CIRCUIT)
	_dialog.add_button("RESUME", _update_buttons, &"PrimaryButton", &"play")
	if controller.is_playing():
		_dialog.add_button("RESTART", _on_reset_from_menu, &"", &"reset")
	_dialog.add_button("SETTINGS", _open_settings_overlay, &"", &"settings")
	_dialog.add_button("LEVEL SELECT" if ResourceLoader.exists(SceneRouter.LEVEL_SELECT) else "MAIN MENU", _go_to_levels, &"", &"levels")
	_dialog.set_footer(_pause_footer(puzzle))
	_open_dialog()


## Settings open on top of the board so the puzzle state is kept.
func _open_settings_overlay() -> void:
	_settings_overlay = (load(SETTINGS_SCENE) as PackedScene).instantiate()
	add_child(_settings_overlay)
	_board.interactive = false
	_settings_overlay.connect("closed", _open_pause.call_deferred)


func _on_reset_from_menu() -> void:
	_on_reset()
	_update_buttons()


func _go_to_levels() -> void:
	if GameManager.current_mode == GameManager.Mode.DAILY or not ResourceLoader.exists(SceneRouter.LEVEL_SELECT):
		SceneRouter.goto(SceneRouter.MAIN_MENU)
	else:
		SceneRouter.goto(SceneRouter.LEVEL_SELECT)


func _on_won(moves: int, stars: int) -> void:
	_board.interactive = false
	_update_buttons()
	var outcome := GameManager.complete_current(moves, stars, controller.hints_used)
	AudioService.play(&"win")
	AudioService.haptic(40)
	await get_tree().create_timer(0.1 if SaveService.progress.reduced_motion else 0.7).timeout
	_show_victory(moves, stars, outcome)


func _show_victory(moves: int, stars: int, outcome: Dictionary) -> void:
	var is_daily := GameManager.current_mode == GameManager.Mode.DAILY
	_dialog.prepare("Daily Complete!" if is_daily else "Signal Restored!")
	var result: PuzzleResult = RESULT_SCENE.instantiate()
	_dialog.add_content(result)
	result.show_result(controller.puzzle, moves, stars, outcome)
	if is_daily:
		_dialog.add_button("Main Menu", func() -> void: SceneRouter.goto(SceneRouter.MAIN_MENU), &"PrimaryButton")
	else:
		var next := GameManager.next_puzzle()
		if next != null and GameManager.can_play(next):
			_dialog.add_button("Next Level", func() -> void: GameManager.play(next, GameManager.current_mode), &"PrimaryButton")
		elif next != null:
			_dialog.add_button("Unlock More Levels", func() -> void: SceneRouter.goto(SceneRouter.PACK_STORE), &"AccentButton")
	_dialog.add_button("Replay", func() -> void: GameManager.play(controller.puzzle, GameManager.current_mode))
	if not is_daily:
		_dialog.add_button("Level Select" if ResourceLoader.exists(SceneRouter.LEVEL_SELECT) else "Main Menu", _go_to_levels)
	_open_dialog()


func _on_failed() -> void:
	_board.interactive = false
	_update_buttons()
	AudioService.play(&"fail")
	AudioService.haptic(60)
	await get_tree().create_timer(0.1 if SaveService.progress.reduced_motion else 0.4).timeout
	_dialog.prepare("Out of Moves", "This circuit allows only %d moves. Try a different route." % controller.move_limit)
	_dialog.add_button("Try Again", _on_retry, &"PrimaryButton")
	_dialog.add_button("Undo Last Move", _on_undo_after_fail)
	if AdsService.is_available():
		_dialog.add_button("Watch Video for +%d Moves" % BONUS_MOVES, _watch_bonus_video, &"AccentButton")
	_dialog.add_button("Level Select" if ResourceLoader.exists(SceneRouter.LEVEL_SELECT) else "Main Menu", _go_to_levels)
	_open_dialog()


func _watch_bonus_video() -> void:
	var outcome: Dictionary = await AdsService.request_reward("bonus_moves")
	if not is_inside_tree():
		return
	if outcome["granted"] and controller.extend_moves(BONUS_MOVES):
		_update_buttons()
		return
	_dialog.prepare("No video available", outcome["message"])
	_dialog.add_button("Try Again", _on_retry, &"PrimaryButton")
	_dialog.add_button("Undo Last Move", _on_undo_after_fail)
	_open_dialog()


func _on_retry() -> void:
	controller.reset()
	_update_buttons()


func _on_undo_after_fail() -> void:
	controller.undo()
	_update_buttons()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and is_node_ready() and controller.is_playing() and not _dialog.is_open():
		_open_pause()
