extends Control
## Settings: audio, haptics, accessibility, privacy policy and purchase restoration.
## Works as a full screen (from the main menu) or as an overlay on top of the game,
## so opening settings mid-puzzle never loses board state.

signal closed

const PRIVACY_URL_SETTING := "signal_shift/privacy_policy_url"
const TERMS_URL_SETTING := "signal_shift/terms_url"

@onready var _rows: VBoxContainer = %Rows
@onready var _back: Button = %BackButton
@onready var _dialog: ModalDialog = %Dialog

var _restore_button: Button


func _ready() -> void:
	_back.pressed.connect(handle_back)
	var progress := SaveService.progress
	var audio := _add_section("Audio", &"sound", Palette.CIRCUIT)
	_add_toggle(audio, &"sound", Palette.CIRCUIT, "Sound Effects", "UI feedback & signal connections", progress.sound_enabled, func(on: bool) -> void: progress.sound_enabled = on)
	_add_toggle(audio, &"music", Palette.ACCENT.lightened(0.3), "Music", "Ambient synth background tracks", progress.music_enabled, func(on: bool) -> void: progress.music_enabled = on)
	var comfort := _add_section("Comfort & Accessibility", &"eye", Palette.ACCENT.lightened(0.3))
	_add_toggle(comfort, &"phone", Palette.DANGER, "Haptic Feedback", "Vibrations on tile snaps & solves", progress.haptics_enabled, func(on: bool) -> void: progress.haptics_enabled = on)
	_add_toggle(comfort, &"gauge", Palette.WARNING, "Reduced Motion", "Turns off spins, pulses and screen fades", progress.reduced_motion, func(on: bool) -> void: progress.reduced_motion = on)
	var purchases := _add_section("Purchases", &"packs", Palette.WARNING)
	_restore_button = _add_action(purchases, &"reset", Palette.WARNING, "Restore Purchases", "Re-sync previous unlocks & Supporter status", _on_restore)
	var about := _add_section("About", &"shield", Palette.SUCCESS)
	_add_action(about, &"shield", Palette.SUCCESS, "Privacy Policy", "How Signal Shift handles your data", _on_privacy)
	_add_action(about, &"check", Palette.ACCENT.lightened(0.3), "Terms & Conditions", "The rules for playing, ads & purchases", _on_terms)
	var version := Label.new()
	version.theme_type_variation = &"DimLabel"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.text = "Signal Shift v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0")
	version.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(version)


func is_overlay() -> bool:
	return get_tree().current_scene != self


func handle_back() -> void:
	if _dialog.is_open():
		_dialog.close()
		return
	SaveService.save_progress()
	if is_overlay():
		closed.emit()
		queue_free()
	else:
		SceneRouter.goto(SceneRouter.settings_return_scene)


## Adds a coloured section heading and returns the card that holds its rows.
func _add_section(title: String, icon: StringName, color: Color) -> VBoxContainer:
	if _rows.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 8)
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rows.add_child(gap)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	heading.alignment = BoxContainer.ALIGNMENT_BEGIN
	_rows.add_child(heading)
	heading.add_child(_glyph(icon, color, 30))
	var label := Label.new()
	label.theme_type_variation = &"CaptionLabel"
	label.add_theme_color_override("font_color", color)
	label.text = title.to_upper()
	heading.add_child(label)
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	_rows.add_child(card)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 18)
	card.add_child(list)
	return list


func _glyph(icon: StringName, color: Color, size: float) -> IconGlyph:
	var glyph := IconGlyph.new()
	glyph.custom_minimum_size = Vector2(size, size)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.icon_name = icon
	glyph.color = color
	return glyph


## One settings row: tinted icon tile, title and description, plus an optional trailing control.
## Rows after the first in a card get a divider above them.
func _add_row(card: VBoxContainer, icon: StringName, color: Color, title: String, description: String, trailing: Control = null) -> Label:
	if card.get_child_count() > 0:
		var divider := ColorRect.new()
		divider.custom_minimum_size = Vector2(0, 2)
		divider.color = Color(Palette.PANEL_BORDER, 0.45)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(divider)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	card.add_child(row)
	var tile := PanelContainer.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.custom_minimum_size = Vector2(84, 84)
	# Stay square when a two-line description makes the row taller.
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.14)
	style.border_color = Color(color, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(20)
	tile.add_theme_stylebox_override("panel", style)
	tile.add_child(_glyph(icon, color, 40))
	row.add_child(tile)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)
	var label := Label.new()
	label.text = title
	text_box.add_child(label)
	var hint := Label.new()
	hint.theme_type_variation = &"DimLabel"
	hint.add_theme_font_size_override("font_size", 22)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = description
	text_box.add_child(hint)
	if trailing != null:
		row.add_child(trailing)
	return label


func _add_toggle(card: VBoxContainer, icon: StringName, color: Color, title: String, description: String, initial: bool, apply: Callable) -> void:
	var toggle := ToggleSwitch.new()
	toggle.button_pressed = initial
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggle.toggled.connect(func(on: bool) -> void:
		apply.call(on)
		SaveService.save_progress()
		SignalBus.settings_changed.emit()
		AudioService.play(&"button")
		AudioService.haptic(10))
	_add_row(card, icon, color, title, description, toggle)


## A tappable row: a transparent button covers it, so the whole row is the touch target.
func _add_action(card: VBoxContainer, icon: StringName, color: Color, title: String, description: String, action: Callable) -> Button:
	_add_row(card, icon, color, title, description)
	var row := card.get_child(card.get_child_count() - 1) as Control
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(action)
	row.add_child(button)
	return button


func _on_privacy() -> void:
	_open_page(PRIVACY_URL_SETTING, "Privacy Policy", "Signal Shift stores your progress only on this device and collects no personal data.")


func _on_terms() -> void:
	_open_page(TERMS_URL_SETTING, "Terms & Conditions", "The Terms & Conditions are available at techbolic.com/games/signal-shift/terms when you are online.")


func _open_page(setting: String, title: String, fallback: String) -> void:
	var url: String = ProjectSettings.get_setting(setting, "")
	if url.is_empty() or OS.shell_open(url) != OK:
		_message(title, fallback)


func _on_restore() -> void:
	var purchases := get_node_or_null("/root/PurchaseService")
	if purchases == null:
		_message("Restore Purchases", "There are no purchases to restore in this version.")
		return
	_restore_button.disabled = true
	var outcome: Dictionary = await purchases.call("restore_purchases")
	_restore_button.disabled = false
	_message("Restore Purchases", str(outcome.get("message", "Done.")))


func _message(title: String, body: String) -> void:
	_dialog.prepare(title, body)
	_dialog.add_button("OK", Callable(), &"PrimaryButton")
	_dialog.popup()
