class_name CircuitTile
extends Control
## Visual for one grid cell. Drawn with vector primitives from the connection mask it is given,
## so what the player sees always matches the model. Emits `tapped` on press.

signal tapped(index: int)

const SPIN_TIME := 0.12
const PULSE_TIME := 0.45

var index: int = -1
var tile_type: int = TileTypes.Type.EMPTY
var connections: int = 0
var is_fixed: bool = false
var powered: bool = false
var solved: bool = false
var hinted: bool = false
var interactive: bool = true

var _spin: float = 0.0
var _pulse: float = 0.0
var _shake: float = 0.0
var _tween: Tween
var _box: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_box = StyleBoxFlat.new()
	_box.set_corner_radius_all(14)
	_box.anti_aliasing = true
	resized.connect(queue_redraw)


func setup(cell_index: int, type: int, mask: int, fixed_tile: bool) -> void:
	index = cell_index
	tile_type = type
	connections = mask
	is_fixed = fixed_tile
	queue_redraw()


## Updates the mask. With `animate`, the new shape spins in from the previous orientation.
func set_connections(mask: int, animate: bool) -> void:
	connections = mask
	if animate and not SaveService.progress.reduced_motion:
		_kill_tween()
		_spin = -PI * 0.5
		_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_spin, _spin, 0.0, SPIN_TIME)
	else:
		_spin = 0.0
	queue_redraw()


func set_powered(value: bool, is_solved: bool) -> void:
	if powered == value and solved == is_solved:
		return
	powered = value
	solved = is_solved
	queue_redraw()


func set_hinted(value: bool) -> void:
	hinted = value
	queue_redraw()


## Brief glow travelling through a newly powered tile. `delay` staggers the pulse along the path.
func pulse(delay: float = 0.0) -> void:
	if SaveService.progress.reduced_motion:
		return
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_method(_set_pulse, 1.0, 0.0, PULSE_TIME)


## Small side-to-side wobble for taps on tiles that cannot rotate.
func shake() -> void:
	if SaveService.progress.reduced_motion:
		_set_pulse(0.6)
		create_tween().tween_method(_set_pulse, 0.6, 0.0, 0.2)
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(_set_shake, 0.0, 1.0, 0.22)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_spin = 0.0
	_shake = 0.0


func _set_spin(value: float) -> void:
	_spin = value
	queue_redraw()


func _set_pulse(value: float) -> void:
	_pulse = value
	queue_redraw()


func _set_shake(value: float) -> void:
	_shake = sin(value * TAU * 2.0) * (1.0 - value) * 6.0
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		tapped.emit(index)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var inset := s * 0.045
	var lip := s * 0.045
	var rect := Rect2(Vector2(inset, inset) + Vector2(_shake, 0), size - Vector2(inset, inset) * 2.0)
	var radius := int(s * 0.16)
	_box.set_corner_radius_all(radius)

	if tile_type == TileTypes.Type.BLOCKED:
		_draw_blocked(rect)
		return

	# Rotatable tiles are raised (face on a darker lip); fixed tiles sit flat and recessed.
	var face := rect
	if not is_fixed:
		face.size.y -= lip
		_box.bg_color = Palette.PANEL_SHADOW
		_box.set_border_width_all(0)
		draw_style_box(_box, Rect2(rect.position + Vector2(0, lip), face.size))
	_box.bg_color = Palette.TILE_FIXED if is_fixed else Palette.TILE_BASE
	_box.border_color = Palette.TILE_TOP if not is_fixed else Color(Palette.PANEL_BORDER, 0.5)
	_box.set_border_width_all(0 if not is_fixed else 2)
	if not is_fixed:
		_box.border_width_top = maxi(2, int(s * 0.025))
	draw_style_box(_box, face)
	if hinted:
		_box.draw_center = false
		_box.border_color = Palette.WARNING
		_box.set_border_width_all(maxi(3, int(s * 0.035)))
		draw_style_box(_box, face.grow(s * 0.01))
		_box.draw_center = true

	if is_fixed:
		_draw_fixed_marks(face, s)
	if tile_type == TileTypes.Type.EMPTY:
		return

	# Traces stay on the cell centre so they line up with neighbours regardless of the lip.
	var center := size * 0.5 + Vector2(_shake, 0)
	draw_set_transform(center, _spin, Vector2.ONE)
	var half := s * 0.5
	var width := s * 0.15
	var glow := _pulse if not powered else 0.55 + 0.45 * _pulse

	# Recessed groove the trace sits in, then the trace itself.
	_draw_traces(half, width * 1.45, Color(Palette.PANEL_SHADOW, 0.85))
	if powered or _pulse > 0.0:
		var glow_color := Palette.SUCCESS if solved else Palette.SIGNAL
		_draw_traces(half, width * 2.6, Color(glow_color, 0.10 * glow))
		_draw_traces(half, width * 1.7, Color(glow_color, 0.22 * glow))
	_draw_traces(half, width, _line_color())
	if powered:
		# Bright core line: a shape cue for powered state that does not rely on colour alone.
		_draw_traces(half, width * 0.34, Color(Palette.TEXT, 0.9))

	match tile_type:
		TileTypes.Type.SOURCE:
			_draw_source(s)
		TileTypes.Type.DESTINATION:
			_draw_destination(s)
		_:
			if connections != 0:
				draw_circle(Vector2.ZERO, width * 0.7, _line_color())
				if powered:
					draw_circle(Vector2.ZERO, width * 0.32, Palette.TEXT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_source(s: float) -> void:
	var halo := s * (0.95 + 0.15 * _pulse)
	draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(Palette.SIGNAL, 0.55))
	draw_circle(Vector2.ZERO, s * 0.25, Palette.PANEL_SHADOW)
	draw_circle(Vector2.ZERO, s * 0.21, Palette.SIGNAL)
	draw_arc(Vector2.ZERO, s * 0.21, PI * 1.1, PI * 1.6, 12, Color(Palette.SIGNAL_GLOW, 0.9), s * 0.03, true)
	draw_circle(Vector2.ZERO, s * 0.1, Palette.TEXT)


func _draw_destination(s: float) -> void:
	var lit := Palette.SUCCESS if powered else Palette.CIRCUIT_IDLE
	if powered:
		var halo := s * (0.95 + 0.2 * _pulse)
		draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(Palette.SUCCESS, 0.6))
	draw_circle(Vector2.ZERO, s * 0.27, Palette.PANEL_SHADOW)
	draw_arc(Vector2.ZERO, s * 0.205, 0.0, TAU, 48, lit, s * 0.07, true)
	if powered:
		draw_circle(Vector2.ZERO, s * 0.12, Palette.SUCCESS)
		draw_circle(Vector2.ZERO, s * 0.055, Palette.TEXT)
	else:
		draw_circle(Vector2.ZERO, s * 0.06, Color(Palette.CIRCUIT_IDLE, 0.7))


func _line_color() -> Color:
	if solved and powered:
		return Palette.SUCCESS
	if powered:
		return Palette.SIGNAL
	return Palette.CIRCUIT_IDLE if not is_fixed else Palette.CIRCUIT_IDLE.darkened(0.2)


## Draws a trace from the centre to each connected edge, in tile-local (centred) coordinates.
func _draw_traces(half: float, width: float, color: Color) -> void:
	for direction in 4:
		if connections & TileTypes.DIRECTION_BITS[direction] == 0:
			continue
		var offset := Vector2(TileTypes.DIRECTION_OFFSETS[direction])
		draw_line(Vector2.ZERO, offset * half, color, width, true)
	draw_circle(Vector2.ZERO, width * 0.5, color)


func _draw_blocked(rect: Rect2) -> void:
	_box.bg_color = Palette.TILE_BLOCKED
	_box.border_color = Color(Palette.PANEL_BORDER, 0.35)
	_box.set_border_width_all(2)
	draw_style_box(_box, rect)
	# Diagonal hazard hatching clipped to the inner square.
	var color := Color(Palette.PANEL_BORDER, 0.45)
	var inner := rect.grow(-rect.size.x * 0.22)
	var step := inner.size.x / 4.0
	for i in range(1, 8):
		var t := i * step
		var a := inner.position + Vector2(maxf(0.0, t - inner.size.x), minf(t, inner.size.y))
		var b := inner.position + Vector2(minf(t, inner.size.x), maxf(0.0, t - inner.size.y))
		draw_line(a, b, color, 3.0, true)


## Four small corner rivets mark tiles that cannot rotate.
func _draw_fixed_marks(rect: Rect2, s: float) -> void:
	var r := s * 0.035
	var pad := s * 0.11
	for corner in [Vector2(pad, pad), Vector2(rect.size.x - pad, pad), Vector2(pad, rect.size.y - pad), rect.size - Vector2(pad, pad)]:
		draw_circle(rect.position + corner + Vector2(0, 1.5), r, Palette.PANEL_SHADOW)
		draw_circle(rect.position + corner, r, Palette.TEXT_DIM)
