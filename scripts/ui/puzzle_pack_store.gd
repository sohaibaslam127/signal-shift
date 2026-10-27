extends Control
## Puzzle pack store: free campaign, premium packs with previews and level counts,
## the Supporter upgrade, and purchase restoration. All purchases go through PurchaseService.

@onready var _rows: VBoxContainer = %Rows
@onready var _back: Button = %BackButton
@onready var _dialog: ModalDialog = %Dialog


func _ready() -> void:
	_back.pressed.connect(handle_back)
	SignalBus.entitlements_changed.connect(_rebuild)
	_rebuild()


func handle_back() -> void:
	if _dialog.is_open():
		_dialog.close()
		return
	SceneRouter.goto(SceneRouter.MAIN_MENU)


func _rebuild() -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var progress := SaveService.progress

	_add_supporter_card()

	var campaign := GameManager.campaign_pack()
	var campaign_card := _card("CardPanel")
	var campaign_box := _text_column(campaign_card)
	var title_row := HBoxContainer.new()
	campaign_box.add_child(title_row)
	var title := _label(title_row, "Campaign", &"HeadingLabel", false)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chip(title_row, "FREE INCLUDED", Palette.SUCCESS)
	var stats := HBoxContainer.new()
	campaign_box.add_child(stats)
	var levels := _label(stats, "%d Levels" % campaign.puzzles.size(), &"DimLabel", false)
	levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stars := _label(stats, "%d / %d ★" % [progress.total_stars(campaign.level_ids()), campaign.puzzles.size() * 3], &"StatLabel", false)
	stars.add_theme_color_override("font_color", Palette.WARNING)
	_button(campaign_box, "Continue Playing", _open_pack.bind(campaign.id), &"")

	for pack in GameManager.catalog.packs_of_kind("premium"):
		_add_pack_card(pack)

	var restore := _button(_rows, "Restore Purchases", _on_restore, &"")
	restore.disabled = PurchaseService.is_busy()
	var note := Label.new()
	note.theme_type_variation = &"DimLabel"
	note.add_theme_font_size_override("font_size", 22)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.text = "Payments are processed by Google Play or the App Store. The full campaign and daily puzzles are free and never require a purchase."
	_rows.add_child(note)


## Pulses the button and bobs a pointer at its right edge to draw the eye.
func _attract(button: Button) -> void:
	if button.disabled:
		return
	var pointer := Control.new()
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bob := [0.0]
	pointer.draw.connect(func() -> void:
		UiIcons.draw_icon(pointer, &"back", Vector2(pointer.size.x - 56.0 + bob[0], pointer.size.y * 0.5 - 4.0), 20.0, Palette.TEXT))
	button.add_child(pointer)
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	var tween := button.create_tween().set_loops()
	tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(button, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	var nudge := button.create_tween().set_loops()
	nudge.tween_method(func(v: float) -> void:
		bob[0] = v
		pointer.queue_redraw(), 0.0, 14.0, 0.5).set_trans(Tween.TRANS_SINE)
	nudge.tween_method(func(v: float) -> void:
		bob[0] = v
		pointer.queue_redraw(), 14.0, 0.0, 0.5).set_trans(Tween.TRANS_SINE)


## Supporter Pass hero card: badge and price, benefit list, and the unlock button.
func _add_supporter_card() -> void:
	var info := PurchaseService.product_info(PurchaseService.SUPPORTER_ID)
	var box := _text_column(_card("AccentCard"))
	var top := HBoxContainer.new()
	box.add_child(top)
	var badge := _chip(top, "BEST VALUE", Palette.CIRCUIT)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var price_box := VBoxContainer.new()
	price_box.add_theme_constant_override("separation", 0)
	top.add_child(price_box)
	var once := _label(price_box, "ONE-TIME UNLOCK", &"CaptionLabel", false)
	once.add_theme_color_override("font_color", Palette.CIRCUIT)
	once.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var price := PurchaseService.price_of(PurchaseService.SUPPORTER_ID)
	var price_label := _label(price_box, "%s Lifetime" % price if not price.is_empty() else "Lifetime", &"StatValue", false)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(box, "%s Pass" % info["title"], &"HeadingLabel")
	var perks: Array = [
		[&"check", "%d Daily Hints (instead of %d)" % [GameManager.SUPPORTER_DAILY_HINTS, GameManager.FREE_DAILY_HINTS]],
		[&"shield", "100% Ad-Free (no forced ad breaks)"],
		[&"gift", "1 Premium Pack Free of your choice"],
		[&"star", "Bigger No-Hint Bonus (+%d, up to %d times a day)" % [GameManager.SUPPORTER_HINT_SOLVE_BONUS, GameManager.SUPPORTER_HINT_SOLVE_BONUS_EVENTS]],
	]
	for perk: Array in perks:
		_perk_row(box, perk[0], perk[1])
	if PurchaseService.is_supporter():
		_label(box, "Active — thank you for your support!", &"StatLabel")
	else:
		_attract(_buy_button(box, PurchaseService.SUPPORTER_ID))


func _perk_row(parent: Control, icon: StringName, text: String) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.BACKGROUND_DEEP, 0.5)
	style.set_corner_radius_all(18)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var glyph := IconGlyph.new()
	glyph.custom_minimum_size = Vector2(34, 34)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.icon_name = icon
	glyph.color = Palette.WARNING if icon == &"gift" or icon == &"star" else Palette.CIRCUIT
	row.add_child(glyph)
	var label := _label(row, text, &"DimLabel")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Palette.TEXT)


## Small rounded tag with coloured text, e.g. "FREE INCLUDED".
func _chip(parent: Control, text: String, color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.16)
	style.border_color = Color(color, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	chip.add_theme_stylebox_override("panel", style)
	var label := _label(chip, text, &"CaptionLabel", false)
	label.add_theme_color_override("font_color", color)
	parent.add_child(chip)
	return chip


func _add_pack_card(pack: LevelCatalog.Pack) -> void:
	var progress := SaveService.progress
	var supporter := PurchaseService.is_supporter()
	var chosen_free := supporter and pack.id == progress.premium_bonus_pack_id
	var owned := PurchaseService.owns(pack.product_id) or chosen_free
	var unlocked_count := progress.free_levels_unlocked(pack.id, GameManager.FREE_PREVIEW_LEVELS)
	var ad_unlocked_all := unlocked_count >= pack.puzzles.size()
	var card := _card("AccentCard")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	card.add_child(row)
	var preview := PuzzlePreview.new()
	preview.custom_minimum_size = Vector2(170, 210)
	preview.accent = pack.accent
	preview.puzzle = pack.puzzles[0] if not pack.puzzles.is_empty() else null
	row.add_child(preview)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	row.add_child(box)
	_label(box, pack.title, &"HeadingLabel")
	_label(box, pack.description, &"DimLabel")
	var status := " · Owned" if owned else (" · Fully unlocked" if ad_unlocked_all else "")
	_label(box, "%d levels%s" % [pack.puzzles.size(), status], &"StatLabel")
	if owned or ad_unlocked_all:
		_button(box, "Play", _open_pack.bind(pack.id), &"PrimaryButton")
	else:
		_button(box, "Try %d Levels Free" % mini(GameManager.FREE_PREVIEW_LEVELS, pack.puzzles.size()), func() -> void: GameManager.play(pack.puzzles[0], GameManager.Mode.PACK), &"")
		if AdsService.is_available():
			_button(box, "Watch Ad to Unlock Level %d" % (unlocked_count + 1), _on_watch_pack_ad.bind(pack.id), &"AccentButton")
		_buy_button(box, pack.product_id)
		if supporter and progress.premium_bonus_pack_id.is_empty():
			_button(box, "Unlock Free as Supporter", _choose_free_pack.bind(pack.id), &"PrimaryButton")


func _on_watch_pack_ad(pack_id: String) -> void:
	var outcome: Dictionary = await AdsService.request_reward("pack_unlock")
	if not is_inside_tree():
		return
	if outcome["granted"]:
		GameManager.unlock_next_pack_level_via_ad(pack_id)
		_rebuild()
	else:
		_message("No video available", outcome["message"])


## One premium pack, chosen once, unlocked in full as a Supporter-purchase perk.
func _choose_free_pack(pack_id: String) -> void:
	SaveService.progress.premium_bonus_pack_id = pack_id
	SaveService.save_progress()
	_rebuild()


func _buy_button(parent: Control, product_id: String) -> Button:
	var price := PurchaseService.price_of(product_id)
	var available := PurchaseService.is_available()
	var text := ("Buy · %s" % price if not price.is_empty() else "Buy") if available else "Store unavailable"
	var button := _button(parent, text, _on_buy.bind(product_id), &"PrimaryButton")
	button.disabled = not available or PurchaseService.is_busy()
	return button


func _open_pack(pack_id: String) -> void:
	GameManager.browsing_pack_id = pack_id
	SceneRouter.goto(SceneRouter.LEVEL_SELECT)


func _on_buy(product_id: String) -> void:
	var outcome: Dictionary = await PurchaseService.purchase(product_id)
	if not is_inside_tree():
		return
	_rebuild()
	_message("Thank you!" if outcome["success"] else ("Cancelled" if outcome["cancelled"] else "Purchase not completed"), outcome["message"])


func _on_restore() -> void:
	var outcome: Dictionary = await PurchaseService.restore_purchases()
	if not is_inside_tree():
		return
	_rebuild()
	_message("Restore Purchases", outcome["message"])


func _message(title: String, body: String) -> void:
	_dialog.prepare(title, body)
	_dialog.add_button("OK", Callable(), &"PrimaryButton")
	_dialog.popup()


func _card(variation: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = StringName(variation)
	# Cards must not swallow touch drags, or the ScrollContainer never scrolls on mobile.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_child(card)
	return card


func _text_column(card: PanelContainer) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	card.add_child(box)
	return box


func _label(parent: Control, text: String, variation: StringName, wrap: bool = true) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, action: Callable, variation: StringName) -> Button:
	var button: Button = preload("res://scenes/components/secondary_button.tscn").instantiate()
	button.text = text
	if variation != &"":
		button.theme_type_variation = variation
	button.pressed.connect(action)
	parent.add_child(button)
	return button
