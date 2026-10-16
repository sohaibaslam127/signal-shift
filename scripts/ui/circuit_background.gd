class_name CircuitBackground
extends Control
## Static decorative background: deep navy with faint circuit traces. Redraws only on resize.

const GRID := 90.0
const TRACE_SEED := 7


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.BACKGROUND)
	var grid_color := Color(Palette.CIRCUIT_IDLE, 0.06)
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
		x += GRID
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
		y += GRID

	# A few deterministic traces with node dots.
	var rng := RandomNumberGenerator.new()
	rng.seed = TRACE_SEED
	var trace_color := Color(Palette.CIRCUIT, 0.09)
	var columns := int(size.x / GRID) + 1
	var rows := int(size.y / GRID) + 1
	for i in 9:
		var point := Vector2(rng.randi_range(0, columns), rng.randi_range(0, rows)) * GRID
		for step in rng.randi_range(2, 5):
			var horizontal := rng.randf() < 0.5
			var length := rng.randi_range(1, 3) * GRID * (1.0 if rng.randf() < 0.5 else -1.0)
			var next := point + (Vector2(length, 0) if horizontal else Vector2(0, length))
			draw_line(point, next, trace_color, 3.0, true)
			point = next
		draw_circle(point, 6.0, Color(Palette.CIRCUIT, 0.14))
