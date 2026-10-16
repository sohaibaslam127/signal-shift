class_name UiIcons
extends RefCounted
## Vector icons drawn with CanvasItem primitives, so the UI needs no image assets.
## `draw_icon` draws `name` centred on `c` inside a circle of radius `r`.


static func draw_icon(ci: CanvasItem, name: StringName, c: Vector2, r: float, color: Color) -> void:
	var w := maxf(3.0, r * 0.26)
	match name:
		&"back":
			poly(ci, [c + Vector2(r * 0.35, -r * 0.8), c + Vector2(-r * 0.45, 0), c + Vector2(r * 0.35, r * 0.8)], color, w)
		&"chevron":
			poly(ci, [c + Vector2(-r * 0.3, -r * 0.75), c + Vector2(r * 0.45, 0), c + Vector2(-r * 0.3, r * 0.75)], color, w)
		&"pause":
			for x in [-0.38, 0.38]:
				ci.draw_line(c + Vector2(r * x, -r * 0.75), c + Vector2(r * x, r * 0.75), color, w * 1.25, true)
				ci.draw_circle(c + Vector2(r * x, -r * 0.75), w * 0.62, color)
				ci.draw_circle(c + Vector2(r * x, r * 0.75), w * 0.62, color)
		&"undo":
			var start := -PI
			ci.draw_arc(c + Vector2(0, r * 0.1), r * 0.72, start, PI * 0.4, 28, color, w, true)
			arrow_head(ci, c + Vector2(0, r * 0.1) + Vector2(cos(start), sin(start)) * r * 0.72, Vector2(0, 1), r * 0.42, color, w)
		&"reset":
			var from := -PI * 0.5 + 0.55
			var to := from + TAU * 0.82
			ci.draw_arc(c, r * 0.78, from, to, 32, color, w, true)
			arrow_head(ci, c + Vector2(cos(to), sin(to)) * r * 0.78, Vector2(-sin(to), cos(to)), r * 0.42, color, w)
		&"hint":
			var bulb := c + Vector2(0, -r * 0.25)
			var from := PI * 0.75
			var to := PI * 2.25
			ci.draw_arc(bulb, r * 0.6, from, to, 28, color, w, true)
			var left_end := bulb + Vector2(cos(from), sin(from)) * r * 0.6
			var right_end := bulb + Vector2(cos(to), sin(to)) * r * 0.6
			poly(ci, [left_end, c + Vector2(-r * 0.3, r * 0.42), c + Vector2(r * 0.3, r * 0.42), right_end], color, w)
			ci.draw_line(c + Vector2(-r * 0.24, r * 0.78), c + Vector2(r * 0.24, r * 0.78), color, w, true)
		&"settings":
			_gear(ci, c, r, color)
		&"levels":
			var cell := r * 0.82
			var gap := r * 0.16
			for y in 2:
				for x in 2:
					var origin := c + Vector2(x * (cell + gap) - cell - gap * 0.5, y * (cell + gap) - cell - gap * 0.5)
					rounded_rect(ci, Rect2(origin, Vector2(cell, cell)), cell * 0.25, color)
		&"packs":
			var body := Rect2(c + Vector2(-r * 0.9, -r * 0.42), Vector2(r * 1.8, r * 1.3))
			rounded_rect(ci, body, r * 0.22, color, false, w)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.36, -r * 0.82), Vector2(r * 0.72, r * 0.4)), color, false, w)
			ci.draw_line(c + Vector2(-r * 0.12, r * 0.02), c + Vector2(r * 0.12, r * 0.02), color, w, true)
		&"daily":
			var body := Rect2(c + Vector2(-r * 0.88, -r * 0.62), Vector2(r * 1.76, r * 1.6))
			rounded_rect(ci, body, r * 0.25, color, false, w)
			ci.draw_line(c + Vector2(-r * 0.88, -r * 0.18), c + Vector2(r * 0.88, -r * 0.18), color, w, true)
			for x in [-0.42, 0.42]:
				ci.draw_line(c + Vector2(r * x, -r * 0.95), c + Vector2(r * x, -r * 0.5), color, w, true)
			ci.draw_colored_polygon(star_points(c + Vector2(0, r * 0.38), r * 0.36, r * 0.16), color)
		&"play":
			var points := PackedVector2Array([c + Vector2(-r * 0.55, -r * 0.85), c + Vector2(r * 0.85, 0), c + Vector2(-r * 0.55, r * 0.85)])
			ci.draw_colored_polygon(points, color)
			poly(ci, [points[0], points[1], points[2], points[0]], color, w * 0.8)
		&"star":
			ci.draw_colored_polygon(star_points(c + Vector2(0, r * 0.08), r, r * 0.48), Palette.WARNING_DARK)
			ci.draw_colored_polygon(star_points(c, r, r * 0.48), color)
			ci.draw_colored_polygon(star_points(c - Vector2(r * 0.12, r * 0.18), r * 0.35, r * 0.16), Color(1, 1, 1, 0.35))
		&"gift":
			var box := Rect2(c + Vector2(-r * 0.82, -r * 0.2), Vector2(r * 1.64, r * 1.05))
			rounded_rect(ci, box, r * 0.15, color)
			rounded_rect(ci, Rect2(c + Vector2(-r * 0.95, -r * 0.5), Vector2(r * 1.9, r * 0.36)), r * 0.1, color)
			var ribbon := Color(color.darkened(0.45), 1.0)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.12, -r * 0.5), Vector2(r * 0.24, r * 1.35)), ribbon)
			ci.draw_arc(c + Vector2(-r * 0.3, -r * 0.68), r * 0.24, 0.0, TAU, 16, color, w * 0.7, true)
			ci.draw_arc(c + Vector2(r * 0.3, -r * 0.68), r * 0.24, 0.0, TAU, 16, color, w * 0.7, true)
		&"close":
			ci.draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), color, w, true)
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.6, -r * 0.6), color, w, true)


static func _gear(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	var teeth := 8
	for i in teeth * 4:
		var angle := (i - 0.5) * TAU / (teeth * 4)
		var outer := (i % 4) < 2
		points.append(c + Vector2(cos(angle), sin(angle)) * r * (0.98 if outer else 0.74))
	ci.draw_colored_polygon(points, color)
	ci.draw_circle(c, r * 0.3, Palette.BACKGROUND_DEEP)


## Open polyline with round joints and caps.
static func poly(ci: CanvasItem, points: Array, color: Color, width: float) -> void:
	for i in points.size() - 1:
		ci.draw_line(points[i], points[i + 1], color, width, true)
	for point: Vector2 in points:
		ci.draw_circle(point, width * 0.5, color)


## Two strokes forming an arrow tip at `tip`, pointing along `direction`.
static func arrow_head(ci: CanvasItem, tip: Vector2, direction: Vector2, length: float, color: Color, width: float) -> void:
	var back := -direction.normalized() * length
	poly(ci, [tip + back.rotated(0.75), tip, tip + back.rotated(-0.75)], color, width)


static func rounded_rect(ci: CanvasItem, rect: Rect2, radius: float, color: Color, filled: bool = true, width: float = 2.0) -> void:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	if filled:
		box.bg_color = color
	else:
		box.draw_center = false
		box.border_color = color
		box.set_border_width_all(int(width))
	ci.draw_style_box(box, rect)


static func star_points(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * (outer if i % 2 == 0 else inner))
	return points
