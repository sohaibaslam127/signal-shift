class_name StarRating
extends Control
## Draws 0–3 filled stars out of 3. Filled stars also differ in shape (solid vs outline),
## so the rating is readable without colour.

@export_range(0, 3) var stars: int = 0:
	set(value):
		stars = clampi(value, 0, 3)
		queue_redraw()
@export var filled_color: Color = Palette.WARNING
@export var empty_color: Color = Palette.TEXT_DISABLED


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var star_size := minf(size.y, size.x / 3.4)
	var gap := (size.x - star_size * 3.0) / 2.0
	gap = minf(gap, star_size * 0.25)
	var total := star_size * 3.0 + gap * 2.0
	var x := (size.x - total) * 0.5
	for i in 3:
		var center := Vector2(x + star_size * 0.5, size.y * 0.5)
		var points := _star_points(center, star_size * 0.5, star_size * 0.22)
		if i < stars:
			draw_colored_polygon(points, filled_color)
		else:
			points.append(points[0])
			draw_polyline(points, empty_color, maxf(2.0, star_size * 0.05), true)
		x += star_size + gap


func _star_points(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		var radius := outer if i % 2 == 0 else inner
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
