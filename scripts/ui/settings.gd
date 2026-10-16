extends Control
## Settings: audio, haptics, accessibility, privacy policy and purchase restoration.
## Works as a full screen (from the main menu) or as an overlay on top of the game,
## so opening settings mid-puzzle never loses board state.

signal closed

const PRIVACY_URL_SETTING := "signal_shift/privacy_policy_url"

@onready var _rows: VBoxContainer = %Rows
@onready var _back: Button = %BackButton
@onready var _dialog: ModalDialog = %Dialog

var _restore_button: Button


func _ready() -> void:
	_back.pressed.connect(handle_back)
	var progress := SaveService.progress
	_add_section("Audio")
	_add_toggle("Sound effects", progress.sound_enabled, func(on: bool) -> void: progress.sound_enabled = on)
	_add_toggle("Music", progress.music_enabled, func(on: bool) -> void: progress.music_enabled = on)
	_add_section("Comfort")
	_add_toggle("Haptic feedback", progress.haptics_enabled, func(on: bool) -> void: progress.haptics_enabled = on)
	_add_toggle("Reduced motion", progress.reduced_motion, func(on: bool) -> void: progress.reduced_motion = on,
		"Turns off spins, pulses and screen fades.")
	_add_section("Purchases")
	_restore_button = _add_action("Restore Purchases", _on_restore)
	_add_section("About")
	_add_action("Privacy Policy", _on_privacy)
	var version := Label.new()
	version.theme_type_variation = &"DimLabel"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.text = "Signal Shift v%s\nAll art and audio are original and generated in-game." % ProjectSettings.get_setting("application/config/version", "0.1.0")
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


func _add_section(title: String) -> void:
	var label := Label.new()
	label.theme_type_variation = &"CaptionLabel"
	label.text = title.to_upper()
	_rows.add_child(label)


func _add_toggle(title: String, initial: bool, apply: Callable, description: String = "") -> void:
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	_rows.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_box)
	var label := Label.new()
	label.text = title
	text_box.add_child(label)
	if not description.is_empty():
		var hint := Label.new()
		hint.theme_type_variation = &"DimLabel"
		hint.add_theme_font_size_override("font_size", 22)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.text = description
		text_box.add_child(hint)
	var toggle := ToggleSwitch.new()
	toggle.button_pressed = initial
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggle.toggled.connect(func(on: bool) -> void:
		apply.call(on)
		SaveService.save_progress()
		SignalBus.settings_changed.emit()
		AudioService.play(&"button")
		AudioService.haptic(10))
	row.add_child(toggle)


func _add_action(title: String, action: Callable) -> Button:
	var button: Button = preload("res://scenes/components/secondary_button.tscn").instantiate()
	button.text = title
	button.pressed.connect(action)
	_rows.add_child(button)
	return button


func _on_privacy() -> void:
	var url: String = ProjectSettings.get_setting(PRIVACY_URL_SETTING, "")
	if url.is_empty() or OS.shell_open(url) != OK:
		_message("Privacy Policy", "Signal Shift stores your progress only on this device and collects no personal data.")


func _on_restore() -> void:
	var purchases := get_node_or_null("/root/PurchaseService")
	if purchases == null:
		_message("Restore Purchases", "There are no purchases to restore in this version.")
		return
	_restore_button.disabled = true
	_restore_button.text = "Restoring…"
	var outcome: Dictionary = await purchases.call("restore_purchases")
	_restore_button.disabled = false
	_restore_button.text = "Restore Purchases"
	_message("Restore Purchases", str(outcome.get("message", "Done.")))


func _message(title: String, body: String) -> void:
	_dialog.prepare(title, body)
	_dialog.add_button("OK", Callable(), &"PrimaryButton")
	_dialog.popup()
