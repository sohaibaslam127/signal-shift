class_name LogoMark
extends Control
## Vector logo: a source node, a bent trace and a destination ring, with a soft glow.

@export var animate: bool = true

var _pulse := 0.0

const SHAPE: Array[Vector2] = [Vector2(0.18, 0.72), Vector2(0.42, 0.72), Vector2(0.42, 0.3), Vector2(0.82, 0.3)]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	if animate and not SaveService.progress.reduced_motion:
		var tween := create_tween().set_loops()
		tween.tween_method(_set_pulse, 0.0, 1.0, 2.4)


func _set_pulse(value: float) -> void:
	_pulse = value
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var origin := (size - Vector2(s, s)) * 0.5
	var points := PackedVector2Array()
	for p in SHAPE:
		points.append(origin + p * s)
	var width := s * 0.07
	_draw_trace(points, Color(Palette.SIGNAL, 0.18), width * 2.2)
	_draw_trace(points, Palette.CIRCUIT, width)
	# Travelling pulse along the trace.
	if animate:
		var total := 0.0
		for i in points.size() - 1:
			total += points[i].distance_to(points[i + 1])
		var target := _pulse * total
		for i in points.size() - 1:
			var seg := points[i].distance_to(points[i + 1])
			if target <= seg:
				draw_circle(points[i].lerp(points[i + 1], target / maxf(seg, 0.001)), width * 0.75, Palette.SIGNAL_GLOW)
				break
			target -= seg
	draw_circle(points[0], width * 1.25, Palette.SIGNAL)
	draw_circle(points[0], width * 0.6, Palette.TEXT)
	draw_arc(points[-1], width * 1.3, 0.0, TAU, 32, Palette.SUCCESS, width * 0.55, true)


## Polyline with round joints and caps.
func _draw_trace(points: PackedVector2Array, color: Color, width: float) -> void:
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], color, width, true)
	for point in points:
		draw_circle(point, width * 0.5, color)
