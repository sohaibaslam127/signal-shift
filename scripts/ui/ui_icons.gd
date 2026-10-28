class_name UiIcons
extends RefCounted
## Vector icons drawn with CanvasItem primitives, so the UI needs no image assets.
## `draw_icon` draws `name` centred on `c` inside a circle of radius `r`.


## Per-icon nudge (fraction of r) that puts each drawing's bounding box on the requested centre.
## Measured by rendering every icon and comparing its pixel bounds with the centre point.
## Play and back are left alone: their triangular/arrow shapes read as centred when their mass is.
const OPTICAL_OFFSET := {
	&"music": Vector2(-0.13, 0.12),
	&"gift": Vector2(0.0, 0.08),
	&"star": Vector2(0.0, 0.055),
	&"undo": Vector2(0.115, -0.075),
	&"sound": Vector2(-0.045, 0.0),
	&"reset": Vector2(0.03, -0.02),
	&"hint": Vector2(0.0, 0.035),
	&"chevron": Vector2(-0.07, 0.0),
	&"shield": Vector2(0.0, -0.015),
}


static func draw_icon(ci: CanvasItem, name: StringName, c: Vector2, r: float, color: Color) -> void:
	c += Vector2(OPTICAL_OFFSET.get(name, Vector2.ZERO)) * r
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
			var cell := r * 0.6
			var gap := r * 0.17
			for y in 3:
				for x in 3:
					var origin := c + Vector2((x - 1) * (cell + gap) - cell * 0.5, (y - 1) * (cell + gap) - cell * 0.5)
					rounded_rect(ci, Rect2(origin, Vector2(cell, cell)), cell * 0.3, color)
		&"packs":
			# Three stacked cards, back to front.
			var card := Vector2(r * 1.5, r * 1.1)
			for i in 3:
				var rect := Rect2(c + Vector2(-card.x * 0.5, -card.y * 0.5 + (i - 1) * r * 0.36), card)
				rounded_rect(ci, rect, r * 0.2, Palette.BACKGROUND_DEEP)
				rounded_rect(ci, rect, r * 0.2, Color(color, 0.55 + 0.225 * i), false, w * 0.8)
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
		&"steps":
			# Two footprints: a sole and a heel each, offset diagonally.
			for foot: Array in [[-0.42, -0.1], [0.42, 0.2]]:
				var f := c + Vector2(r * foot[0], r * foot[1])
				ci.draw_circle(f + Vector2(0, -r * 0.3), r * 0.3, color)
				ci.draw_circle(f + Vector2(0, r * 0.5), r * 0.18, color)
		&"target":
			ci.draw_arc(c, r * 0.9, 0.0, TAU, 32, color, w * 0.8, true)
			ci.draw_arc(c, r * 0.52, 0.0, TAU, 28, color, w * 0.8, true)
			ci.draw_circle(c, r * 0.2, color)
		&"check":
			ci.draw_circle(c, r, color)
			poly(ci, [c + Vector2(-r * 0.42, 0.0), c + Vector2(-r * 0.1, r * 0.34), c + Vector2(r * 0.46, -r * 0.34)], Palette.BACKGROUND_DEEP, w * 0.8)
		&"shield":
			var top := c + Vector2(0, -r * 0.9)
			var pts := PackedVector2Array([top, c + Vector2(r * 0.8, -r * 0.55), c + Vector2(r * 0.8, r * 0.1), c + Vector2(0, r * 0.95), c + Vector2(-r * 0.8, r * 0.1), c + Vector2(-r * 0.8, -r * 0.55)])
			ci.draw_colored_polygon(pts, color)
			ci.draw_colored_polygon(PackedVector2Array([top + Vector2(0, r * 0.25), c + Vector2(r * 0.55, -r * 0.4), c + Vector2(r * 0.55, r * 0.05), c + Vector2(0, r * 0.65)]), Palette.BACKGROUND_DEEP)
		&"sound":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.9, -r * 0.35), c + Vector2(-r * 0.4, -r * 0.35), c + Vector2(r * 0.1, -r * 0.8), c + Vector2(r * 0.1, r * 0.8), c + Vector2(-r * 0.4, r * 0.35), c + Vector2(-r * 0.9, r * 0.35)]), color)
			ci.draw_arc(c + Vector2(r * 0.1, 0), r * 0.5, -PI * 0.3, PI * 0.3, 10, color, w * 0.8, true)
			ci.draw_arc(c + Vector2(r * 0.1, 0), r * 0.9, -PI * 0.3, PI * 0.3, 12, color, w * 0.8, true)
		&"music":
			ci.draw_circle(c + Vector2(-r * 0.4, r * 0.55), r * 0.3, color)
			ci.draw_circle(c + Vector2(r * 0.55, r * 0.35), r * 0.3, color)
			ci.draw_line(c + Vector2(-r * 0.12, r * 0.5), c + Vector2(-r * 0.12, -r * 0.75), color, w, true)
			ci.draw_line(c + Vector2(r * 0.83, r * 0.3), c + Vector2(r * 0.83, -r * 0.95), color, w, true)
			ci.draw_line(c + Vector2(-r * 0.12, -r * 0.75), c + Vector2(r * 0.83, -r * 0.95), color, w * 1.3, true)
		&"eye":
			var lens := PackedVector2Array()
			for i in 13:
				var x := lerpf(-1.0, 1.0, i / 12.0)
				lens.append(c + Vector2(x * r, -sqrt(maxf(0.0, 1.0 - x * x)) * r * 0.62))
			for i in 13:
				var x := lerpf(1.0, -1.0, i / 12.0)
				lens.append(c + Vector2(x * r, sqrt(maxf(0.0, 1.0 - x * x)) * r * 0.62))
			lens.append(lens[0])
			ci.draw_polyline(lens, color, w * 0.8, true)
			ci.draw_circle(c, r * 0.3, color)
		&"phone":
			rounded_rect(ci, Rect2(c + Vector2(-r * 0.5, -r * 0.9), Vector2(r, r * 1.8)), r * 0.2, color, false, w * 0.8)
			ci.draw_circle(c + Vector2(0, r * 0.62), r * 0.08, color)
		&"gauge":
			ci.draw_circle(c, r * 0.95, color)
			ci.draw_line(c, c + Vector2(r * 0.4, -r * 0.5), Palette.BACKGROUND_DEEP, w * 0.9, true)
			ci.draw_circle(c, r * 0.14, Palette.BACKGROUND_DEEP)
		&"close":
			ci.draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), color, w, true)
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.6, -r * 0.6), color, w, true)


static func _gear(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	var teeth := 8
	for i in teeth:
		var dir := Vector2.from_angle(i * TAU / teeth)
		ci.draw_line(c + dir * r * 0.62, c + dir * r * 0.9, color, r * 0.34, true)
	ci.draw_circle(c, r * 0.72, color)
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
