class_name SafeAreaContainer
extends MarginContainer
## Full-screen margin container that keeps content clear of notches, rounded corners and
## system bars on mobile, plus a constant base gutter on every platform.

@export var base_margin: int = 28


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_update_margins)
	_update_margins()


func _update_margins() -> void:
	var insets := _safe_insets()
	add_theme_constant_override("margin_left", base_margin + int(insets.position.x))
	add_theme_constant_override("margin_top", base_margin + int(insets.position.y))
	add_theme_constant_override("margin_right", base_margin + int(insets.size.x))
	add_theme_constant_override("margin_bottom", base_margin + int(insets.size.y))


## Returns left/top in position and right/bottom in size, in viewport units.
func _safe_insets() -> Rect2:
	if not OS.has_feature("mobile"):
		return Rect2()
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Rect2()
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var scale := get_viewport().get_visible_rect().size / window_size
	var left := safe.position.x * scale.x
	var top := safe.position.y * scale.y
	var right := maxf(0.0, (window_size.x - safe.end.x) * scale.x)
	var bottom := maxf(0.0, (window_size.y - safe.end.y) * scale.y)
	return Rect2(left, top, right, bottom)
