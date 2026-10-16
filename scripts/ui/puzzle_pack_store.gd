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

	var campaign := GameManager.campaign_pack()
	var campaign_card := _card("CardPanel")
	var campaign_box := _text_column(campaign_card)
	_label(campaign_box, "Campaign", &"HeadingLabel")
	_label(campaign_box, "Free · %d levels · %d/%d ★" % [campaign.puzzles.size(), progress.total_stars(campaign.level_ids()), campaign.puzzles.size() * 3], &"DimLabel")
	_button(campaign_box, "Open", _open_pack.bind(campaign.id), &"")

	for pack in GameManager.catalog.packs_of_kind("premium"):
		_add_pack_card(pack)

	var supporter := PurchaseService.product_info(PurchaseService.SUPPORTER_ID)
	var supporter_card := _card("AccentCard")
	var supporter_box := _text_column(supporter_card)
	_label(supporter_box, str(supporter["title"]), &"HeadingLabel")
	_label(supporter_box, str(supporter["description"]), &"DimLabel")
	if PurchaseService.is_supporter():
		_label(supporter_box, "Active — thank you for your support!", &"StatLabel")
	else:
		_buy_button(supporter_box, PurchaseService.SUPPORTER_ID)

	var restore := _button(_rows, "Restore Purchases", _on_restore, &"")
	restore.disabled = PurchaseService.is_busy()
	var note := Label.new()
	note.theme_type_variation = &"DimLabel"
	note.add_theme_font_size_override("font_size", 22)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.text = "Payments are processed by Google Play or the App Store. The full campaign and daily puzzles are free and never require a purchase."
	_rows.add_child(note)


func _add_pack_card(pack: LevelCatalog.Pack) -> void:
	var owned := PurchaseService.owns(pack.product_id)
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
	box.add_theme_constant_override("separation", 10)
	row.add_child(box)
	_label(box, pack.title, &"HeadingLabel")
	_label(box, pack.description, &"DimLabel")
	_label(box, "%d levels%s" % [pack.puzzles.size(), " · Owned" if owned else ""], &"StatLabel")
	if owned:
		_button(box, "Play", _open_pack.bind(pack.id), &"PrimaryButton")
	else:
		_button(box, "Try Level 1 Free", func() -> void: GameManager.play(pack.puzzles[0], GameManager.Mode.PACK), &"")
		_buy_button(box, pack.product_id)


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
	_rows.add_child(card)
	return card


func _text_column(card: PanelContainer) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	return box


func _label(parent: Control, text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
