class_name LevelButton
extends Button
## Level grid cell: number, earned stars (drawn) and a drawn padlock when locked.

var level_number: int = 1
var stars: int = 0
var locked: bool = false
var completed: bool = false
var current: bool = false


func _ready() -> void:
	theme_type_variation = &"LevelButton"
	custom_minimum_size = Vector2(112, 124)
	focus_mode = Control.FOCUS_NONE
	text = ""
	pressed.connect(func() -> void: AudioService.play(&"button"))


func configure(number: int, earned_stars: int, is_locked: bool, is_completed: bool, is_current: bool) -> void:
	level_number = number
	stars = earned_stars
	locked = is_locked
	completed = is_completed
	current = is_current
	disabled = locked
	theme_type_variation = &"PrimaryButton" if current and not locked else &"LevelButton"
	tooltip_text = "Level %d (locked)" % number if locked else "Level %d" % number
	queue_redraw()


func _draw() -> void:
	var font := get_theme_font(&"font")
	var pressed_now := get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED
	var drop := 6.0 if pressed_now else 0.0
	var center_x := size.x * 0.5
	if locked:
		_draw_lock(Vector2(center_x, size.y * 0.44), size.x * 0.14)
		return
	var font_size := 38
	var number := str(level_number)
	var text_size := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var color := Palette.BACKGROUND_DEEP if current else Palette.TEXT
	draw_string(font, Vector2(center_x - text_size.x * 0.5, size.y * 0.47 + drop), number, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	var star_r := size.x * 0.085
	for i in 3:
		var c := Vector2(center_x + (i - 1) * star_r * 2.5, size.y * 0.7 + drop - (star_r * 0.35 if i == 1 else 0.0))
		var points := _star(c, star_r, star_r * 0.48)
		if i < stars:
			draw_colored_polygon(points, Palette.BACKGROUND_DEEP if current else Palette.WARNING)
		else:
			points.append(points[0])
			draw_polyline(points, Color(Palette.BACKGROUND_DEEP, 0.4) if current else Palette.TEXT_DISABLED, 2.0, true)


func _draw_lock(c: Vector2, r: float) -> void:
	var color := Color(Palette.TEXT_DISABLED, 0.9)
	draw_arc(c + Vector2(0, -r * 0.35), r * 0.62, PI, TAU, 16, color, r * 0.22, true)
	draw_rect(Rect2(c + Vector2(-r, -r * 0.3), Vector2(r * 2.0, r * 1.5)), color)


func _star(c: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		points.append(c + Vector2(cos(angle), sin(angle)) * (outer if i % 2 == 0 else inner))
	return points
