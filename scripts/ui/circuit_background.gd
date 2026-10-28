class_name CircuitBackground
extends Control
## Decorative background: vertical night gradient, two soft colour glows, faint circuit grid and
## traces. The static layer redraws only on resize; slow drifting motes live on a child layer
## (disabled with reduced motion).

const GRID := 90.0
const TRACE_SEED := 7
const MOTE_COUNT := 26

## Menu-only scenery: distant hills, floating tiles and coloured waves in the corners.
@export var scenic: bool = false
## Draws the pattern and colours of PackTheme.current (the in-game screen).
@export var pack_themed: bool = false

var _motes: Control
var _mote_data: Array[Vector4] = []  # x, y (0..1), speed, radius
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	if not SaveService.progress.reduced_motion:
		_setup_motes()


func _setup_motes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TRACE_SEED * 31
	for i in MOTE_COUNT:
		_mote_data.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.006, 0.02), rng.randf_range(1.5, 4.0)))
	_motes = Control.new()
	_motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_motes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_motes.draw.connect(_draw_motes)
	add_child(_motes)


func _process(delta: float) -> void:
	if _motes == null:
		set_process(false)
		return
	_time += delta
	_motes.queue_redraw()


func _draw_motes() -> void:
	for mote in _mote_data:
		var y := fposmod(mote.y - _time * mote.z, 1.0)
		var x := mote.x + sin(_time * 0.4 + mote.y * 12.0) * 0.015
		var fade := sin(y * PI)
		var center := Vector2(x * size.x, y * size.y)
		_motes.draw_circle(center, mote.w * 2.6, Color(Palette.CIRCUIT, 0.05 * fade))
		_motes.draw_circle(center, mote.w, Color(Palette.SIGNAL_GLOW, 0.35 * fade))


func _draw() -> void:
	if pack_themed and PackTheme.current.id != "default":
		_draw_pack_theme(PackTheme.current)
		return
	var corners := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	var colors := PackedColorArray([Palette.BACKGROUND_TOP, Palette.BACKGROUND_TOP, Palette.BACKGROUND_DEEP, Palette.BACKGROUND_DEEP])
	draw_polygon(corners, colors)

	# Soft ambient glows: violet upper-left, cyan lower-right.
	var glow_size := size.x * 1.5
	draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-glow_size * 0.45, -glow_size * 0.35), Vector2(glow_size, glow_size)), false, Color(Palette.ACCENT, 0.22))
	draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(size.x - glow_size * 0.5, size.y - glow_size * 0.6), Vector2(glow_size, glow_size)), false, Color(Palette.CIRCUIT, 0.12))

	var grid_color := Color(Palette.SIGNAL_GLOW, 0.035)
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
	var trace_color := Color(Palette.CIRCUIT, 0.07)
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
		draw_circle(point, 9.0, Color(Palette.CIRCUIT, 0.05))
		draw_circle(point, 5.0, Color(Palette.CIRCUIT, 0.16))

	if scenic:
		_draw_scenery()


func _draw_scenery() -> void:
	_draw_hills(size.y * 0.36, size.y * 0.05, 1.3, Color("23338f", 0.5))
	_draw_hills(size.y * 0.41, size.y * 0.04, 2.1, Color("1a2672", 0.65))

	# Floating tiles around the logo.
	for tile: Vector3 in [Vector3(0.27, 0.14, 26), Vector3(0.12, 0.23, 34), Vector3(0.74, 0.21, 22), Vector3(0.93, 0.34, 30), Vector3(0.84, 0.08, 18)]:
		var center := Vector2(tile.x * size.x, tile.y * size.y)
		UiIcons.rounded_rect(self, Rect2(center - Vector2(tile.z, tile.z) * 0.5, Vector2(tile.z, tile.z)), tile.z * 0.25, Color(Palette.SIGNAL, 0.35))
	for dot: Vector2 in [Vector2(0.3, 0.17), Vector2(0.78, 0.24), Vector2(0.16, 0.31)]:
		draw_circle(dot * size, 5.0, Color(Palette.SIGNAL, 0.45))

	# Corner waves: dark swell top-left, cyan bottom-left, violet bottom-right.
	_draw_wave(Vector2(0, 0), Vector2(size.x * 0.32, size.y * 0.11), Color(Palette.BACKGROUND_DEEP, 0.0), Color(Palette.BACKGROUND_DEEP, 0.55), true)
	_draw_wave(Vector2(0, size.y), Vector2(size.x * 0.38, size.y * 0.13), Color(Palette.CIRCUIT, 0.0), Color(Palette.MINT, 0.55), false)
	_draw_wave(Vector2(size.x, size.y), Vector2(-size.x * 0.34, size.y * 0.1), Color(Palette.ACCENT, 0.0), Color(Palette.ACCENT, 0.6), false)


## A soft range of hills whose fill fades out downwards.
func _draw_hills(base: float, height: float, frequency: float, color: Color) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var steps := 32
	for i in steps + 1:
		var t := float(i) / steps
		var y := base - height * (0.55 + 0.45 * sin(t * TAU * frequency + frequency)) * (0.6 + 0.4 * sin(t * PI * 3.0 + 1.0))
		points.append(Vector2(t * size.x, y))
		colors.append(color)
	var fade := Color(color, 0.0)
	points.append(Vector2(size.x, base + size.y * 0.2))
	colors.append(fade)
	points.append(Vector2(0, base + size.y * 0.2))
	colors.append(fade)
	draw_polygon(points, colors)
	# Thin highlight along the ridge.
	draw_polyline(points.slice(0, steps + 1), Color(Palette.SIGNAL, 0.12), 2.0, true)


## Curved blob anchored at `corner`, spanning `extent` (signs give the direction).
func _draw_wave(corner: Vector2, extent: Vector2, inner: Color, outer: Color, from_top: bool) -> void:
	var points := PackedVector2Array([corner])
	var colors := PackedColorArray([outer])
	var steps := 20
	var y_dir := 1.0 if from_top else -1.0
	for i in steps + 1:
		var t := float(i) / steps
		# Swell that starts tall at the edge and dips to nothing at the far end.
		var reach := (1.0 - t) * (0.75 + 0.25 * sin(t * PI * 2.0))
		points.append(corner + Vector2(extent.x * t, y_dir * absf(extent.y) * reach))
		colors.append(outer.lerp(inner, t * 0.8))
	draw_polygon(points, colors)


func _draw_pack_theme(theme: PackTheme) -> void:
	var corners := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	draw_polygon(corners, PackedColorArray([theme.bg_top, theme.bg_top, theme.bg_deep, theme.bg_deep]))
	var texture := theme.background_texture()
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.55))
	var glow_size := size.x * 1.5
	draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-glow_size * 0.45, -glow_size * 0.35), Vector2(glow_size, glow_size)), false, Color(theme.glow_a, 0.2))
	draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(size.x - glow_size * 0.5, size.y - glow_size * 0.6), Vector2(glow_size, glow_size)), false, Color(theme.glow_b, 0.14))
	match theme.pattern:
		"lines":
			_pattern_lines(theme.pattern_color)
		"blueprint":
			_pattern_blueprint(theme.pattern_color)
		"pcb":
			_pattern_pcb(theme.pattern_color)
		"hex":
			_pattern_hex(theme.pattern_color, theme.phase_color)


## Overclock: hairline grid with a few sharp 45-degree runs and bright nodes.
func _pattern_lines(color: Color) -> void:
	var faint := Color(color, 0.045)
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), faint, 1.0)
		x += GRID * 1.5
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), faint, 1.0)
		y += GRID * 1.5
	var rng := RandomNumberGenerator.new()
	rng.seed = TRACE_SEED + 1
	for i in 7:
		var a := Vector2(rng.randi_range(0, int(size.x / GRID)), rng.randi_range(0, int(size.y / GRID))) * GRID
		var b := a + Vector2(rng.randi_range(1, 3) * GRID, 0)
		var c := b + Vector2(1, 1 if rng.randf() < 0.5 else -1) * rng.randi_range(1, 2) * GRID
		draw_polyline(PackedVector2Array([a, b, c]), Color(color, 0.16), 1.5, true)
		draw_circle(c, 4.0, Color(color, 0.55))


## Logic Gates: dot grid with faint gate outlines (AND-style D shapes).
func _pattern_blueprint(color: Color) -> void:
	var step := GRID * 0.5
	var y := step
	while y < size.y:
		var x := step
		while x < size.x:
			draw_circle(Vector2(x, y), 1.4, Color(color, 0.12))
			x += step
		y += step
	var rng := RandomNumberGenerator.new()
	rng.seed = TRACE_SEED + 2
	for i in 6:
		var origin := Vector2(rng.randi_range(1, int(size.x / GRID) - 1), rng.randi_range(1, int(size.y / GRID) - 1)) * GRID
		var body := PackedVector2Array([origin, origin + Vector2(GRID * 0.5, 0)])
		for k in 9:
			var angle := -PI * 0.5 + PI * k / 8.0
			body.append(origin + Vector2(GRID * 0.5, GRID * 0.4) + Vector2(cos(angle) * GRID * 0.3, sin(angle) * GRID * 0.4))
		body.append(origin + Vector2(0, GRID * 0.8))
		body.append(origin)
		draw_polyline(body, Color(color, 0.14), 2.0, true)
		draw_line(origin + Vector2(-GRID * 0.3, GRID * 0.2), origin + Vector2(0, GRID * 0.2), Color(color, 0.14), 2.0, true)
		draw_line(origin + Vector2(-GRID * 0.3, GRID * 0.6), origin + Vector2(0, GRID * 0.6), Color(color, 0.14), 2.0, true)


## Circuit Breaker: copper traces with solder pads, vias and a scorched fault mark.
func _pattern_pcb(color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = TRACE_SEED + 3
	var columns := int(size.x / (GRID * 0.5)) + 1
	var rows := int(size.y / (GRID * 0.5)) + 1
	for i in 16:
		var point := Vector2(rng.randi_range(0, columns), rng.randi_range(0, rows)) * GRID * 0.5
		draw_circle(point, 9.0, Color(color, 0.22))
		draw_circle(point, 4.0, Color("060d09"))
		for step in rng.randi_range(2, 4):
			var horizontal := rng.randf() < 0.5
			var length := rng.randi_range(1, 4) * GRID * 0.5 * (1.0 if rng.randf() < 0.5 else -1.0)
			var next := point + (Vector2(length, 0) if horizontal else Vector2(0, length))
			draw_line(point, next, Color(color, 0.2), 5.0, true)
			draw_line(point, next, Color(color, 0.07), 11.0, true)
			point = next
		draw_circle(point, 8.0, Color(color, 0.28))
		draw_circle(point, 3.5, Color("060d09"))
	# Scorch marks and an exposed wire end near the bottom corner.
	draw_texture_rect(Palette.glow_texture(), Rect2(size * Vector2(0.62, 0.86) - Vector2(90, 90), Vector2(180, 180)), false, Color("ff4d4d", 0.16))


## Quantum Protocol: a hexagonal field with a few phase-coloured nodes.
func _pattern_hex(color: Color, phase_color: Color) -> void:
	var radius := GRID * 0.55
	var dx := radius * 1.5
	var dy := radius * sqrt(3.0)
	var col := 0
	var x := 0.0
	while x < size.x + radius:
		var y := -dy + (dy * 0.5 if col % 2 == 1 else 0.0)
		while y < size.y + radius:
			var points := PackedVector2Array()
			for k in 7:
				var angle := PI / 3.0 * k
				points.append(Vector2(x, y) + Vector2(cos(angle), sin(angle)) * radius * 0.96)
			draw_polyline(points, Color(color, 0.07), 1.0, true)
			y += dy
		x += dx
		col += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = TRACE_SEED + 4
	for i in 8:
		var center := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var node_color := color if i % 2 == 0 else phase_color
		draw_arc(center, 14.0, 0.0, TAU, 24, Color(node_color, 0.35), 2.0, true)
		draw_circle(center, 4.0, Color(node_color, 0.6))
