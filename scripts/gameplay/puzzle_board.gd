class_name PuzzleBoard
extends Control
## Lays out CircuitTile views for a PuzzleController's board and forwards taps to it.
## Presentation only: all state comes from the controller's BoardState and solver result.

const TILE_SCENE := preload("res://scenes/game/circuit_tile.tscn")
const MAX_TILE_SIZE := 150.0
const PULSE_STEP := 0.035
const TRAY_PADDING := 18.0

var controller: PuzzleController
var interactive: bool = true:
	set(value):
		interactive = value
		for tile in _tiles:
			tile.interactive = value

var _tiles: Array[CircuitTile] = []
var _was_powered: PackedByteArray = PackedByteArray()
var _hinted_index := -1
var _grid_rect := Rect2()
var _tray := StyleBoxFlat.new()


func _ready() -> void:
	resized.connect(_layout)
	_tray.bg_color = Color(Palette.BOARD_TRAY, 0.92)
	_tray.border_color = Color(Palette.CIRCUIT, 0.22)
	_tray.set_border_width_all(2)
	_tray.set_corner_radius_all(34)
	_tray.shadow_color = Color(Palette.CIRCUIT, 0.10)
	_tray.shadow_size = 36
	_tray.anti_aliasing = true


func _draw() -> void:
	if _grid_rect.size == Vector2.ZERO:
		return
	draw_style_box(_tray, _grid_rect.grow(TRAY_PADDING))


func bind(puzzle_controller: PuzzleController) -> void:
	if controller != null:
		controller.board_changed.disconnect(_on_board_changed)
		controller.tap_rejected.disconnect(_on_tap_rejected)
	controller = puzzle_controller
	controller.board_changed.connect(_on_board_changed)
	controller.tap_rejected.connect(_on_tap_rejected)
	_build()


func tile_at(index: int) -> CircuitTile:
	return _tiles[index] if index >= 0 and index < _tiles.size() else null


func _build() -> void:
	for tile in _tiles:
		tile.queue_free()
	_tiles.clear()
	var board := controller.board
	for i in board.cell_count():
		var tile: CircuitTile = TILE_SCENE.instantiate()
		add_child(tile)
		tile.setup(i, board.get_type(i), board.connections_at(i), board.is_fixed(i), TileTypes.gate_output_bit(board.get_type(i), board.get_rotation(i)))
		tile.interactive = interactive
		tile.tapped.connect(_on_tile_tapped)
		_tiles.append(tile)
	_was_powered.resize(board.cell_count())
	_was_powered.fill(0)
	_layout()
	_refresh(-1, false)


func _layout() -> void:
	if controller == null or _tiles.is_empty():
		return
	var board := controller.board
	var available := size - Vector2(TRAY_PADDING, TRAY_PADDING) * 2.0
	var tile_size := floorf(minf(minf(available.x / board.width, available.y / board.height), MAX_TILE_SIZE))
	var grid_size := Vector2(tile_size * board.width, tile_size * board.height)
	var origin := ((size - grid_size) * 0.5).floor()
	_grid_rect = Rect2(origin, grid_size)
	queue_redraw()
	for i in _tiles.size():
		var cell := board.cell_of(i)
		var tile := _tiles[i]
		tile.position = origin + Vector2(cell) * tile_size
		tile.size = Vector2(tile_size, tile_size)
		tile.pivot_offset = tile.size * 0.5


func _on_tile_tapped(index: int) -> void:
	if not interactive or controller == null:
		return
	if controller.tap(index):
		AudioService.play(&"rotate", randf_range(0.95, 1.05))
		AudioService.haptic(12)


func _on_tap_rejected(index: int) -> void:
	if controller.is_playing():
		_tiles[index].shake()
		AudioService.play(&"locked")
		AudioService.haptic(30)


func _on_board_changed(changed_index: int, animate: bool) -> void:
	if _tiles.size() != controller.board.cell_count():
		_build()
		return
	_refresh(changed_index, animate)


func _refresh(changed_index: int, animate: bool) -> void:
	var board := controller.board
	var result := controller.result
	var solved := result.is_solved()
	var newly_powered := false
	if _hinted_index >= 0:
		_tiles[_hinted_index].set_hinted(false)
		_hinted_index = -1
	for i in _tiles.size():
		var tile := _tiles[i]
		var mask := board.connections_at(i)
		var gate_bit := TileTypes.gate_output_bit(board.get_type(i), board.get_rotation(i))
		if i == changed_index:
			tile.set_connections(mask, animate, gate_bit)
		elif tile.connections != mask or tile.gate_output_bit != gate_bit:
			tile.set_connections(mask, false, gate_bit)
		var is_powered := result.is_powered(i)
		tile.set_powered(is_powered, solved)
		if is_powered and _was_powered[i] == 0 and animate:
			tile.pulse(result.distance[i] * PULSE_STEP)
			newly_powered = true
		_was_powered[i] = 1 if is_powered else 0
	if newly_powered and not solved:
		AudioService.play(&"connect", 1.0 + 0.02 * mini(result.powered_order.size(), 20))
	if solved and animate:
		for i in result.powered_order:
			_tiles[i].pulse(result.distance[i] * PULSE_STEP)


func highlight_hint(index: int) -> void:
	if index < 0 or index >= _tiles.size():
		return
	if _hinted_index >= 0:
		_tiles[_hinted_index].set_hinted(false)
	_hinted_index = index
	_tiles[index].set_hinted(true)
