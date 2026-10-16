class_name LogoMark
extends Control
## Vector logo: a source node, a bent trace and a destination ring, with a soft glow.

@export var animate: bool = true

var _pulse := 0.0

const SHAPE: Array[Vector2] = [Vector2(0.26, 0.69), Vector2(0.45, 0.69), Vector2(0.45, 0.35), Vector2(0.72, 0.35)]


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
	_draw_badge(Rect2(origin, Vector2(s, s)).grow(-s * 0.06))
	var corners := PackedVector2Array()
	for p in SHAPE:
		corners.append(origin + p * s)
	var points := _rounded_path(corners, s * 0.09)
	var width := s * 0.085
	_draw_trace(points, Palette.CIRCUIT_DARK, width * 1.25)
	_draw_trace(points, Palette.CIRCUIT, width)
	_draw_trace(points, Palette.CIRCUIT.lerp(Palette.TEXT, 0.45), width * 0.3)
	# Travelling pulse along the trace.
	if animate:
		var total := 0.0
		for i in points.size() - 1:
			total += points[i].distance_to(points[i + 1])
		var target := _pulse * total
		for i in points.size() - 1:
			var seg := points[i].distance_to(points[i + 1])
			if target <= seg:
				draw_circle(points[i].lerp(points[i + 1], target / maxf(seg, 0.001)), width * 0.7, Palette.TEXT)
				break
			target -= seg
	var source := points[0]
	var target_point := points[-1]
	var halo := s * 0.36
	draw_texture_rect(Palette.glow_texture(), Rect2(source - Vector2(halo, halo) * 0.5, Vector2(halo, halo)), false, Color(Palette.SIGNAL, 0.8))
	draw_texture_rect(Palette.glow_texture(), Rect2(target_point - Vector2(halo, halo) * 0.5, Vector2(halo, halo)), false, Color(Palette.MINT, 0.6))
	draw_circle(source, width * 1.45, Palette.SIGNAL)
	draw_circle(source, width * 0.7, Palette.TEXT)
	draw_circle(target_point, width * 1.75, Palette.MINT)
	draw_circle(target_point, width * 1.05, Palette.PANEL_SHADOW)
	draw_circle(target_point, width * 0.6, Palette.MINT)


## Replaces each interior corner with a short arc of radius `radius`.
func _rounded_path(corners: PackedVector2Array, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array([corners[0]])
	for i in range(1, corners.size() - 1):
		var into := (corners[i] - corners[i - 1]).normalized()
		var out := (corners[i + 1] - corners[i]).normalized()
		var start := corners[i] - into * radius
		var end := corners[i] + out * radius
		for step in 7:
			var t := step / 6.0
			points.append(start.lerp(corners[i], t).lerp(corners[i].lerp(end, t), t))
	points.append(corners[-1])
	return points


## Rounded "app icon" plate with a glowing cyan rim.
func _draw_badge(rect: Rect2) -> void:
	var glow := rect.size.x * 1.9
	draw_texture_rect(Palette.glow_texture(), Rect2(rect.get_center() - Vector2(glow, glow) * 0.5, Vector2(glow, glow)), false, Color(Palette.CIRCUIT, 0.18 + 0.06 * sin(_pulse * TAU)))
	var radius := int(rect.size.x * 0.24)
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("16206a")
	plate.border_color = Palette.CIRCUIT
	plate.set_border_width_all(maxi(4, int(rect.size.x * 0.03)))
	plate.set_corner_radius_all(radius)
	plate.shadow_color = Color(Palette.CIRCUIT, 0.35)
	plate.shadow_size = int(rect.size.x * 0.1)
	plate.anti_aliasing = true
	draw_style_box(plate, rect)
	# Inner bevel: a lighter inset rim and a darker lower half.
	var inner := StyleBoxFlat.new()
	inner.draw_center = false
	inner.border_color = Color(Palette.SIGNAL_GLOW, 0.25)
	inner.set_border_width_all(2)
	inner.set_corner_radius_all(radius - 8)
	inner.anti_aliasing = true
	draw_style_box(inner, rect.grow(-rect.size.x * 0.045))


## Polyline with round joints and caps.
func _draw_trace(points: PackedVector2Array, color: Color, width: float) -> void:
	for i in points.size() - 1:
		draw_line(points[i], points[i + 1], color, width, true)
	for point in points:
		draw_circle(point, width * 0.5, color)
