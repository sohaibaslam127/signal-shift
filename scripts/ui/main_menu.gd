extends Control
## Main menu: campaign progress and hint pills, continue/play, daily puzzle card with its reward
## row, and a navigation bar for levels, packs and settings.

@onready var _level_pill: MenuPill = %LevelPill
@onready var _hint_pill: MenuPill = %HintPill
@onready var _continue_button: Button = %ContinueButton
@onready var _daily_button: MenuCard = %DailyButton
@onready var _reward_row: MenuCard = %RewardRow
@onready var _levels_button: Button = %LevelsButton
@onready var _packs_button: Button = %PacksButton
@onready var _settings_button: Button = %SettingsButton
@onready var _version: Label = %Version
@onready var _dialog: ModalDialog = %Dialog


func _ready() -> void:
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0")
	_continue_button.text = "Continue" if GameManager.has_progress() else "Play"
	_wire(_continue_button, _on_continue, SceneRouter.GAME)
	_wire(_daily_button, _on_daily, SceneRouter.GAME)
	_reward_row.pressed.connect(_on_hint_pill)
	_wire(_level_pill, _on_levels, SceneRouter.LEVEL_SELECT)
	_hint_pill.pressed.connect(_on_hint_pill)
	_wire(_levels_button, _on_levels, SceneRouter.LEVEL_SELECT)
	_wire(_packs_button, _on_packs, SceneRouter.PACK_STORE)
	_wire(_settings_button, _on_settings, SceneRouter.SETTINGS)
	_refresh_daily()
	_refresh_pills()
	_continue_button.grab_focus.call_deferred()


func handle_back() -> void:
	get_tree().quit()


## Connects a menu button; disables it if its target screen is not part of the build yet.
func _wire(button: Button, handler: Callable, target_scene: String) -> void:
	button.disabled = not ResourceLoader.exists(target_scene)
	button.pressed.connect(handler)


func _refresh_daily() -> void:
	var date := Time.get_date_dict_from_system()
	const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	_daily_button.chip_text = "%s %d" % [MONTHS[int(date["month"]) - 1], int(date["day"])]
	if DailyPuzzleService.today_puzzle() == null:
		_daily_button.disabled = true
		_daily_button.subtitle = "Daily puzzles unavailable"
	elif DailyPuzzleService.is_completed(DailyPuzzleService.today_key()):
		_daily_button.visible = false
	else:
		_daily_button.subtitle = "New puzzle available!"


## Top bar: campaign level and progress; free-hint pill points at the daily reward while it is open.
func _refresh_pills() -> void:
	var campaign := GameManager.campaign_pack()
	var progress := SaveService.progress
	var next := GameManager.continue_puzzle()
	_level_pill.title = "Level %d" % (next.pack_index + 1) if next != null else "Levels"
	var completed := 0
	for puzzle in campaign.puzzles:
		if progress.is_completed(puzzle.id):
			completed += 1
	_level_pill.progress = float(completed) / maxf(1.0, campaign.puzzles.size())
	_level_pill.tooltip_text = "%d of %d levels solved" % [completed, campaign.puzzles.size()]
	_hint_pill.badge = 1
	_hint_pill.visible = _ad_hint_ready()
	_reward_row.visible = _hint_pill.visible


func _ad_hint_ready() -> bool:
	return Time.get_unix_time_from_system() - SaveService.progress.last_ad_hint_time >= ProgressionData.AD_HINT_COOLDOWN


## Free-hint pill: a rewarded video earns one hint, then the pill hides for 24 hours.
func _on_hint_pill() -> void:
	_hint_pill.disabled = true
	_reward_row.disabled = true
	var outcome: Dictionary = await AdsService.request_reward("hint")
	if not is_inside_tree():
		return
	_hint_pill.disabled = false
	_reward_row.disabled = false
	if not outcome["granted"]:
		_dialog.prepare("No video available", outcome["message"])
		_dialog.add_button("OK", Callable(), &"PrimaryButton")
		_dialog.popup()
		return
	var progress := SaveService.progress
	progress.add_hint_tokens(1)
	progress.last_ad_hint_time = int(Time.get_unix_time_from_system())
	SaveService.save_progress()
	SignalBus.hint_tokens_changed.emit(progress.hint_tokens)
	_refresh_pills()


func _on_continue() -> void:
	GameManager.play(GameManager.continue_puzzle())


func _on_daily() -> void:
	GameManager.play_daily(DailyPuzzleService.today_key())


func _on_levels() -> void:
	GameManager.browsing_pack_id = GameManager.CAMPAIGN_PACK_ID
	SceneRouter.goto(SceneRouter.LEVEL_SELECT)


func _on_packs() -> void:
	SceneRouter.goto(SceneRouter.PACK_STORE)


func _on_settings() -> void:
	SceneRouter.open_settings(SceneRouter.MAIN_MENU)
