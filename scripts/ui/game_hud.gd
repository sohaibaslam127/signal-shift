extends Control
## Gameplay screen: binds a PuzzleController to the board view and drives the HUD,
## pause menu, victory and out-of-moves dialogs.

const RESULT_SCENE := preload("res://scenes/game/puzzle_result.tscn")

var controller := PuzzleController.new()

@onready var _board: PuzzleBoard = %Board
@onready var _title: Label = %LevelTitle
@onready var _chapter: Label = %ChapterLabel
@onready var _moves: Label = %MovesLabel
@onready var _par: Label = %ParLabel
@onready var _limit: Label = %LimitLabel
@onready var _pause_button: Button = %PauseButton
@onready var _undo_button: Button = %UndoButton
@onready var _reset_button: Button = %ResetButton
@onready var _hint_button: Button = %HintButton
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

	_title.text = puzzle.name
	_chapter.text = _subtitle_for(puzzle)
	_par.text = "Par %d" % puzzle.par
	controller.start(puzzle)
	_board.bind(controller)
	_update_buttons()


func handle_back() -> void:
	if _dialog.is_open():
		if controller.is_playing():
			_dialog.close()
		return
	_open_pause()


func _subtitle_for(puzzle: PuzzleData) -> String:
	if GameManager.current_mode == GameManager.Mode.DAILY:
		return "Daily Puzzle · %s" % GameManager.current_daily_key
	return GameManager.chapter_title(puzzle)


func _on_moves_changed(moves: int) -> void:
	_moves.text = "Moves %d" % moves
	_limit.visible = controller.puzzle.has_move_limit()
	if _limit.visible:
		_limit.text = "Left %d" % controller.moves_left()
	_update_buttons()


func _update_buttons() -> void:
	var playing := controller.is_playing()
	_undo_button.disabled = not controller.can_undo()
	_reset_button.disabled = not playing or controller.moves == 0
	_hint_button.disabled = not playing
	_hint_button.text = "Hint (%d)" % SaveService.progress.hint_tokens
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
	if progress.hint_tokens <= 0:
		_show_message("No hints left", "Solve today's Daily Puzzle to earn a free hint.")
		return
	_use_hint()


func _use_hint() -> void:
	var progress := SaveService.progress
	progress.add_hint_tokens(-1)
	SaveService.save_progress()
	SignalBus.hint_tokens_changed.emit(progress.hint_tokens)
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
	_dialog.prepare("Paused", controller.puzzle.name)
	_dialog.add_button("Resume", _update_buttons, &"PrimaryButton")
	if controller.is_playing():
		_dialog.add_button("Restart", _on_reset_from_menu)
	if ResourceLoader.exists(SceneRouter.SETTINGS):
		_dialog.add_button("Settings", func() -> void: SceneRouter.open_settings(SceneRouter.GAME))
	_dialog.add_button("Level Select" if ResourceLoader.exists(SceneRouter.LEVEL_SELECT) else "Main Menu", _go_to_levels)
	_open_dialog()


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
	var outcome := GameManager.complete_current(moves, stars)
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
	_dialog.prepare("Out of Moves", "This circuit allows only %d moves. Try a different route." % controller.puzzle.move_limit)
	_dialog.add_button("Try Again", _on_retry, &"PrimaryButton")
	_dialog.add_button("Undo Last Move", _on_undo_after_fail)
	_dialog.add_button("Level Select" if ResourceLoader.exists(SceneRouter.LEVEL_SELECT) else "Main Menu", _go_to_levels)
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
