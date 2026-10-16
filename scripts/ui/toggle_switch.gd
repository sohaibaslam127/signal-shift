class_name ToggleSwitch
extends Button
## iOS-style on/off switch drawn in code. State is the Button's `button_pressed` (toggle mode);
## the knob position (not only the colour) shows the state.

const TRACK_SIZE := Vector2(116, 64)
const SLIDE_TIME := 0.14

var _knob: float = 0.0


func _init() -> void:
	toggle_mode = true
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = TRACK_SIZE + Vector2(16, 24)
	toggled.connect(_on_toggled)


func _ready() -> void:
	_knob = 1.0 if button_pressed else 0.0
	_update_tooltip()


func _on_toggled(on: bool) -> void:
	_update_tooltip()
	var target := 1.0 if on else 0.0
	if SaveService.progress.reduced_motion or not is_inside_tree():
		_set_knob(target)
		return
	create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_method(_set_knob, _knob, target, SLIDE_TIME)


func _set_knob(value: float) -> void:
	_knob = value
	queue_redraw()


func _update_tooltip() -> void:
	tooltip_text = "On" if button_pressed else "Off"


func _draw() -> void:
	var track := Rect2((size - TRACK_SIZE) * 0.5, TRACK_SIZE)
	var radius := TRACK_SIZE.y * 0.5
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	box.bg_color = Palette.PANEL_SHADOW.lerp(Palette.CIRCUIT_DARK, _knob)
	box.border_color = Color(Palette.PANEL_BORDER, 1.0 - _knob).lerp(Color(Palette.CIRCUIT, 0.8), _knob)
	box.set_border_width_all(2)
	draw_style_box(box, track)
	var knob_r := radius - 7.0
	var x := lerpf(track.position.x + radius, track.end.x - radius, _knob)
	var center := Vector2(x, track.get_center().y)
	draw_circle(center + Vector2(0, 3), knob_r, Color(0, 0, 0, 0.3))
	draw_circle(center, knob_r, Palette.TEXT.lerp(Palette.TEXT_DIM, 1.0 - _knob))
