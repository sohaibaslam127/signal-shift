extends Control
## Main menu: continue/play, daily puzzle, levels, packs, settings.

@onready var _continue_button: Button = %ContinueButton
@onready var _daily_button: Button = %DailyButton
@onready var _daily_status: Label = %DailyStatus
@onready var _levels_button: Button = %LevelsButton
@onready var _packs_button: Button = %PacksButton
@onready var _settings_button: Button = %SettingsButton
@onready var _version: Label = %Version


func _ready() -> void:
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0")
	_continue_button.text = "Continue" if GameManager.has_progress() else "Play"
	_wire(_continue_button, _on_continue, SceneRouter.GAME)
	_wire(_daily_button, _on_daily, SceneRouter.GAME)
	_wire(_levels_button, _on_levels, SceneRouter.LEVEL_SELECT)
	_wire(_packs_button, _on_packs, SceneRouter.PACK_STORE)
	_wire(_settings_button, _on_settings, SceneRouter.SETTINGS)
	_refresh_daily()
	_continue_button.grab_focus.call_deferred()


func handle_back() -> void:
	get_tree().quit()


## Connects a menu button; disables it if its target screen is not part of the build yet.
func _wire(button: Button, handler: Callable, target_scene: String) -> void:
	button.disabled = not ResourceLoader.exists(target_scene)
	button.pressed.connect(handler)


func _refresh_daily() -> void:
	var key := DailyPuzzleService.today_key()
	var date := Time.get_date_dict_from_system()
	const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	_daily_button.text = "Daily Puzzle · %s %d" % [MONTHS[int(date["month"]) - 1], int(date["day"])]
	if DailyPuzzleService.today_puzzle() == null:
		_daily_button.disabled = true
		_daily_status.text = "Daily puzzles unavailable"
	elif DailyPuzzleService.is_completed(key):
		_daily_status.text = "Solved today ✓ · %d dailies solved" % DailyPuzzleService.total_completed()
	else:
		_daily_status.text = "Solve it for +%d free hint" % DailyPuzzleService.REWARD_HINTS


func _on_continue() -> void:
	GameManager.play(GameManager.continue_puzzle())


func _on_daily() -> void:
	GameManager.play_daily(DailyPuzzleService.today_key())


func _on_levels() -> void:
	GameManager.browsing_pack_id = GameManager.CAMPAIGN_PACK_ID
	SceneRouter.goto(SceneRouter.LEVEL_SELECT)


func _on_packs() -> void:
	pass


func _on_settings() -> void:
	SceneRouter.open_settings(SceneRouter.MAIN_MENU)
