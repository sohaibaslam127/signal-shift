class_name PuzzlePreview
extends Control
## Small non-interactive thumbnail of a puzzle in its solved state, used for pack previews.

var puzzle: PuzzleData:
	set(value):
		puzzle = value
		_powered = SignalSolver.solve(puzzle.create_solution_board()).powered if puzzle != null else PackedByteArray()
		queue_redraw()
var accent: Color = Palette.ACCENT

var _powered := PackedByteArray()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if puzzle == null:
		return
	var cell := floorf(minf(size.x / puzzle.width, size.y / puzzle.height))
	var origin := (size - Vector2(cell * puzzle.width, cell * puzzle.height)) * 0.5
	var half := cell * 0.5
	for i in puzzle.types.size():
		var type := puzzle.types[i]
		var center := origin + Vector2(i % puzzle.width, i / puzzle.width) * cell + Vector2(half, half)
		if type == TileTypes.Type.BLOCKED:
			draw_rect(Rect2(center - Vector2(half, half) * 0.8, Vector2(cell, cell) * 0.8), Palette.TILE_BLOCKED)
			continue
		var mask := TileTypes.connections(type, puzzle.solution[i])
		var color := accent if _powered[i] != 0 else Color(Palette.CIRCUIT_IDLE, 0.6)
		for direction in 4:
			if mask & TileTypes.DIRECTION_BITS[direction] != 0:
				draw_line(center, center + Vector2(TileTypes.DIRECTION_OFFSETS[direction]) * half, color, maxf(2.0, cell * 0.16))
		if type == TileTypes.Type.SOURCE or type == TileTypes.Type.DESTINATION:
			draw_circle(center, cell * 0.24, Palette.SIGNAL if type == TileTypes.Type.SOURCE else Palette.SUCCESS)
