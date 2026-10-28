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
## Exit side of a gate or one-way tile (0 for other types).
var gate_output_bit: int = 0
## The tile's state digit: switch on/off, broken wire repair state, portal pair id.
var state: int = 0
## Quantum rules: bit 0 = powered in phase 0, bit 1 = powered in phase 180.
var phases: int = 0
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


func setup(cell_index: int, type: int, mask: int, fixed_tile: bool, gate_bit: int = 0) -> void:
	index = cell_index
	tile_type = type
	connections = mask
	gate_output_bit = gate_bit
	is_fixed = fixed_tile
	queue_redraw()


## Updates the mask. With `animate`, the new shape spins in from the previous orientation.
func set_connections(mask: int, animate: bool, gate_bit: int = 0) -> void:
	connections = mask
	gate_output_bit = gate_bit
	if animate and not SaveService.progress.reduced_motion:
		_kill_tween()
		_spin = -PI * 0.5
		_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_spin, _spin, 0.0, SPIN_TIME)
	else:
		_spin = 0.0
	queue_redraw()


func set_state(value: int) -> void:
	if state != value:
		state = value
		queue_redraw()


func set_phases(bits: int) -> void:
	if phases != bits:
		phases = bits
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
	_box.bg_color = _theme().tile_fixed if is_fixed else _theme().tile_base
	_box.border_color = _theme().tile_top if not is_fixed else Color(Palette.PANEL_BORDER, 0.5)
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
	var width := s * _theme().trace_width
	var glow := _pulse if not powered else 0.55 + 0.45 * _pulse

	if tile_type == TileTypes.Type.BROKEN and state < 2:
		_draw_broken(s, width)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	# Recessed groove the trace sits in, then the trace itself.
	_draw_traces(half, width * 1.45, Color(Palette.PANEL_SHADOW, 0.85))
	if powered or _pulse > 0.0:
		var glow_color := _theme().success_color if solved else _signal_color()
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
		TileTypes.Type.GATE_AND, TileTypes.Type.GATE_OR, TileTypes.Type.GATE_XOR, TileTypes.Type.GATE_NOT:
			_draw_gate(s)
		TileTypes.Type.DIODE:
			_draw_diode(s)
		TileTypes.Type.SWITCH:
			_draw_switch(s)
		TileTypes.Type.FAULT:
			_draw_fault(s)
		TileTypes.Type.PORTAL:
			_draw_portal(s)
		TileTypes.Type.INVERTER:
			_draw_inverter(s)
		TileTypes.Type.PHASE_DEST:
			_draw_phase_destination(s)
		TileTypes.Type.BROKEN:
			_draw_clamp(s)
		_:
			if connections != 0:
				draw_circle(Vector2.ZERO, width * 0.7, _line_color())
				if powered:
					draw_circle(Vector2.ZERO, width * 0.32, Palette.TEXT)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_source(s: float) -> void:
	var halo := s * (0.95 + 0.15 * _pulse)
	draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(_theme().signal_color, 0.55))
	draw_circle(Vector2.ZERO, s * 0.25, Palette.PANEL_SHADOW)
	draw_circle(Vector2.ZERO, s * 0.21, _theme().signal_color)
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


## Labelled gate body: dim until its output is on, then it glows and marks the output side.
func _draw_gate(s: float) -> void:
	var active := powered
	var label := {
		TileTypes.Type.GATE_AND: "AND", TileTypes.Type.GATE_OR: "OR",
		TileTypes.Type.GATE_XOR: "XOR", TileTypes.Type.GATE_NOT: "NOT",
	}[tile_type] as String
	var body := Rect2(Vector2(-s * 0.27, -s * 0.2), Vector2(s * 0.54, s * 0.4))
	if active:
		var halo := s * (0.95 + 0.2 * _pulse)
		draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(_theme().success_color, 0.5))
	UiIcons.rounded_rect(self, body, s * 0.1, Palette.PANEL_SHADOW)
	UiIcons.rounded_rect(self, body.grow(-s * 0.02), s * 0.08, Color(_theme().success_color, 0.9) if active else Color(_theme().signal_color, 0.25))
	var font := get_theme_default_font()
	var font_size := int(s * 0.2)
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, text_size.y * 0.3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.BACKGROUND_DEEP if active else Palette.TEXT)
	if gate_output_bit != 0:
		var output_direction := TileTypes.DIRECTION_BITS.find(gate_output_bit)
		if output_direction >= 0:
			var offset := Vector2(TileTypes.DIRECTION_OFFSETS[output_direction])
			draw_circle(offset * s * 0.34, s * 0.05, Palette.TEXT if active else Color(Palette.TEXT, 0.5))


## One-way tile: a solid arrowhead pointing along the only direction signal may travel.
func _draw_diode(s: float) -> void:
	var direction := TileTypes.DIRECTION_BITS.find(gate_output_bit)
	if direction < 0:
		return
	var forward := Vector2(TileTypes.DIRECTION_OFFSETS[direction])
	var side := Vector2(-forward.y, forward.x)
	var tip := forward * s * 0.2
	var tail := -forward * s * 0.12
	var color := _line_color() if powered else _theme().signal_color
	draw_colored_polygon(PackedVector2Array([tip, tail + side * s * 0.17, tail - side * s * 0.17]), Palette.PANEL_SHADOW)
	draw_colored_polygon(PackedVector2Array([tip - forward * s * 0.03, tail + side * s * 0.13 + forward * s * 0.01, tail - side * s * 0.13 + forward * s * 0.01]), color)
	draw_line(forward * s * 0.3, forward * s * 0.5, color, s * 0.05, true)


## Toggle switch: a pill with a knob that sits right when ON.
func _draw_switch(s: float) -> void:
	var on := state == 1
	var track := Rect2(Vector2(-s * 0.26, -s * 0.14), Vector2(s * 0.52, s * 0.28))
	if on:
		var halo := s * (0.95 + 0.2 * _pulse)
		draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(_theme().signal_color, 0.5))
	UiIcons.rounded_rect(self, track.grow(s * 0.02), s * 0.16, Palette.PANEL_SHADOW)
	UiIcons.rounded_rect(self, track, s * 0.14, _theme().signal_color if on else Color(_theme().idle_color, 0.7))
	var knob_x := s * 0.12 if on else -s * 0.12
	draw_circle(Vector2(knob_x, 0), s * 0.1, Palette.TEXT)


## Fault terminal: a warning triangle that flares when something powers it (a short circuit).
func _draw_fault(s: float) -> void:
	var danger := Palette.DANGER
	var tri := PackedVector2Array([Vector2(0, -s * 0.27), Vector2(s * 0.26, s * 0.2), Vector2(-s * 0.26, s * 0.2)])
	if powered:
		var halo := s * (1.1 + 0.25 * _pulse)
		draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(danger, 0.8))
	draw_colored_polygon(tri, Color(danger, 0.9) if powered else Color(danger, 0.28))
	draw_polyline(tri + PackedVector2Array([tri[0]]), danger, s * 0.025, true)
	draw_line(Vector2(0, -s * 0.1), Vector2(0, s * 0.04), Palette.TEXT, s * 0.04, true)
	draw_circle(Vector2(0, s * 0.12), s * 0.025, Palette.TEXT)


## Broken wire: two stubs along its orientation with a gap and a spark; tap to repair.
func _draw_broken(s: float, width: float) -> void:
	var along := Vector2(1, 0) if state & 1 == 1 else Vector2(0, 1)
	var copper := _theme().idle_color
	for sign in [-1.0, 1.0]:
		draw_line(along * sign * s * 0.13, along * sign * s * 0.5, Color(Palette.PANEL_SHADOW, 0.85), width * 1.45, true)
		draw_line(along * sign * s * 0.13, along * sign * s * 0.5, copper, width, true)
		draw_circle(along * sign * s * 0.13, width * 0.55, Palette.WARNING)
	var side := Vector2(-along.y, along.x)
	for k in [-1.0, 0.0, 1.0]:
		var jitter := 0.5 + 0.5 * sin(_pulse * 9.0 + k * 2.0)
		draw_line(side * k * s * 0.03, side * k * s * 0.03 + along.rotated(k * 0.9) * s * 0.07 * (0.5 + jitter), Color(Palette.WARNING, 0.9), s * 0.02, true)


## Small clamp over a repaired wire so the repair stays visible.
func _draw_clamp(s: float) -> void:
	var color := _line_color()
	UiIcons.rounded_rect(self, Rect2(Vector2(-s * 0.09, -s * 0.09), Vector2(s * 0.18, s * 0.18)), s * 0.04, Palette.PANEL_SHADOW)
	UiIcons.rounded_rect(self, Rect2(Vector2(-s * 0.07, -s * 0.07), Vector2(s * 0.14, s * 0.14)), s * 0.03, color)


## Portal: concentric rings coloured by pair id; matching colours link the two ends.
func _draw_portal(s: float) -> void:
	var colors := [Color("35e0f0"), Color("c58bff"), Color("ffc857"), Color("5cf2a6")]
	var color: Color = colors[state % 4]
	var halo := s * (0.95 + 0.2 * _pulse)
	draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(color, 0.55 if powered else 0.25))
	draw_circle(Vector2.ZERO, s * 0.27, Palette.PANEL_SHADOW)
	draw_arc(Vector2.ZERO, s * 0.22, 0.0, TAU, 40, color, s * 0.045, true)
	draw_arc(Vector2.ZERO, s * 0.13, 0.4, TAU + 0.4, 32, Color(color, 0.9 if powered else 0.5), s * 0.035, true)
	draw_circle(Vector2.ZERO, s * 0.05, Palette.TEXT if powered else Color(color, 0.6))


## Phase inverter: a split disc (half filled) that flips the signal's phase.
func _draw_inverter(s: float) -> void:
	var color := _theme().phase_color
	draw_circle(Vector2.ZERO, s * 0.2, Palette.PANEL_SHADOW)
	draw_arc(Vector2.ZERO, s * 0.16, 0.0, TAU, 32, color, s * 0.03, true)
	var half := PackedVector2Array()
	for k in 17:
		var angle := PI / 2.0 + PI * k / 16.0
		half.append(Vector2(cos(angle), sin(angle)) * s * 0.14)
	draw_colored_polygon(half, Color(color, 0.95 if powered else 0.55))


## Destination that only accepts the inverted phase: ringed in the phase colour with a half-filled core.
func _draw_phase_destination(s: float) -> void:
	var color := _theme().phase_color
	var lit := powered and phases & 2 != 0
	if lit:
		var halo := s * (0.95 + 0.2 * _pulse)
		draw_texture_rect(Palette.glow_texture(), Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false, Color(color, 0.6))
	draw_circle(Vector2.ZERO, s * 0.27, Palette.PANEL_SHADOW)
	draw_arc(Vector2.ZERO, s * 0.205, 0.0, TAU, 48, color if lit else Color(color, 0.45), s * 0.07, true)
	var half := PackedVector2Array()
	for k in 17:
		var angle := PI / 2.0 + PI * k / 16.0
		half.append(Vector2(cos(angle), sin(angle)) * s * 0.12)
	draw_colored_polygon(half, Palette.TEXT if lit else Color(color, 0.5))


func _theme() -> PackTheme:
	return PackTheme.current


## Quantum signals that only arrive in phase 180 are drawn in the phase colour.
func _signal_color() -> Color:
	return _theme().phase_color if phases == 2 else _theme().signal_color


func _line_color() -> Color:
	if solved and powered:
		return _theme().success_color
	if powered:
		return _signal_color()
	return _theme().idle_color if not is_fixed else _theme().idle_color.darkened(0.2)


## Draws a trace from the centre to each connected edge, in tile-local (centred) coordinates.
func _draw_traces(half: float, width: float, color: Color) -> void:
	if tile_type in [TileTypes.Type.SWITCH, TileTypes.Type.FAULT, TileTypes.Type.PORTAL]:
		return
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
