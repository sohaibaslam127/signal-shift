extends Control
## Level selection grouped by chapter. Shows locked/unlocked state, completion and stars,
## and restores the scroll position when returning from a level.

const COLUMNS := 5

@onready var _back: Button = %BackButton
@onready var _title: Label = %Title
@onready var _star_total: MenuPill = %StarTotal
@onready var _scroll: ScrollContainer = %Scroll
@onready var _chapters: VBoxContainer = %Chapters

var _pack: LevelCatalog.Pack
var _current_button: Control


func _ready() -> void:
	_pack = GameManager.catalog.get_pack(GameManager.browsing_pack_id)
	if _pack == null:
		_pack = GameManager.campaign_pack()
	_back.pressed.connect(handle_back)
	_title.text = "Levels" if _pack.kind == "campaign" else _pack.title
	var progress := SaveService.progress
	var earned := progress.total_stars(_pack.level_ids())
	_star_total.title = "%d/%d" % [earned, _pack.puzzles.size() * 3]
	_star_total.tooltip_text = "%d of %d stars" % [earned, _pack.puzzles.size() * 3]
	_build()
	_restore_scroll.call_deferred()


func handle_back() -> void:
	_remember_scroll()
	SceneRouter.goto(SceneRouter.MAIN_MENU if _pack.kind == "campaign" else SceneRouter.PACK_STORE)


func _build() -> void:
	var progress := SaveService.progress
	var current := GameManager.continue_puzzle() if _pack.kind == "campaign" else null
	for c in _pack.chapters.size():
		var chapter: Dictionary = _pack.chapters[c]
		var start: int = chapter["start"]
		var count: int = chapter["count"]
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 12)
		_chapters.add_child(section)

		var ids := PackedStringArray()
		for i in range(start, start + count):
			ids.append(_pack.puzzles[i].id)
		var earned := progress.total_stars(ids)
		if _pack.kind == "campaign":
			var caption := Label.new()
			caption.theme_type_variation = &"CaptionLabel"
			caption.text = "CHAPTER %d" % (c + 1)
			section.add_child(caption)
		var heading := HBoxContainer.new()
		section.add_child(heading)
		var title := Label.new()
		title.theme_type_variation = &"HeadingLabel"
		title.add_theme_font_size_override("font_size", 36)
		title.text = str(chapter["title"])
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(title)
		var stars := Label.new()
		stars.theme_type_variation = &"StatLabel"
		stars.add_theme_font_size_override("font_size", 28)
		stars.add_theme_color_override("font_color", Palette.WARNING)
		stars.text = "%d/%d ★" % [earned, count * 3]
		heading.add_child(stars)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 10)
		bar.show_percentage = false
		bar.max_value = count * 3
		bar.value = earned
		section.add_child(bar)

		var grid := GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 14)
		section.add_child(grid)
		for i in range(start, start + count):
			var puzzle := _pack.puzzles[i]
			var button := LevelButton.new()
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(button)
			var unlocked := GameManager.can_play(puzzle)
			button.configure(i + 1, progress.get_stars(puzzle.id), not unlocked, progress.is_completed(puzzle.id), puzzle == current)
			button.pressed.connect(_on_level_pressed.bind(puzzle))
			if puzzle == current:
				_current_button = button


func _on_level_pressed(puzzle: PuzzleData) -> void:
	if not GameManager.can_play(puzzle):
		if _pack.kind == "premium":
			_remember_scroll()
			SceneRouter.goto(SceneRouter.PACK_STORE)
		return
	_remember_scroll()
	GameManager.play(puzzle, GameManager.Mode.CAMPAIGN if _pack.kind == "campaign" else GameManager.Mode.PACK)


func _remember_scroll() -> void:
	GameManager.level_select_scroll[_pack.id] = _scroll.scroll_vertical


func _restore_scroll() -> void:
	# Wait for container layout so scroll limits are known.
	await get_tree().process_frame
	if GameManager.level_select_scroll.has(_pack.id):
		_scroll.scroll_vertical = int(GameManager.level_select_scroll[_pack.id])
	elif _current_button != null:
		_scroll.ensure_control_visible(_current_button)
