class_name ModalDialog
extends Control
## Reusable modal: dimmed backdrop that swallows input, a panel with title, body text,
## optional custom content and a vertical list of buttons.

signal closed

const BUTTON_SCENE := preload("res://scenes/components/secondary_button.tscn")

var _title: Label
var _body: Label
var _content: VBoxContainer
var _buttons: VBoxContainer
var _panel: PanelContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var backdrop := ColorRect.new()
	backdrop.color = Color(Palette.BACKGROUND_DEEP, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"DialogPanel"
	_panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	_panel.add_child(column)

	_title = Label.new()
	_title.theme_type_variation = &"HeadingLabel"
	_title.add_theme_font_size_override("font_size", 48)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)

	_body = Label.new()
	_body.theme_type_variation = &"DimLabel"
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(500, 0)
	column.add_child(_body)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	column.add_child(_content)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	column.add_child(_buttons)


## Clears the dialog and sets its text. Add content and buttons, then call `popup()`.
func prepare(title: String, body: String = "") -> ModalDialog:
	_title.text = title
	_body.text = body
	_body.visible = not body.is_empty()
	for container: Control in [_content, _buttons]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	return self


func add_content(control: Control) -> void:
	_content.add_child(control)


## Adds a button that closes the dialog and then runs `action`.
func add_button(text: String, action: Callable, variation: StringName = &"") -> Button:
	var button: Button = BUTTON_SCENE.instantiate()
	button.text = text
	if variation != &"":
		button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(0, 108)
	button.pressed.connect(func() -> void:
		close()
		if action.is_valid():
			action.call())
	_buttons.add_child(button)
	return button


func popup() -> void:
	visible = true
	move_to_front()
	if SaveService.progress.reduced_motion:
		return
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.92, 0.92)
	modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.2)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible
