extends "res://tests/test_case.gd"
## Tile rotation, reciprocal connections and signal traversal.

const T := TileTypes.Type


## Builds a board from rows of tokens, e.g. ["S1 I1 D3"]. Token = type letter, rotation digit, optional "*" fixed.
func _board(rows: Array) -> BoardState:
	var cells: Array = []
	for row: String in rows:
		cells.append(row.split(" ", false))
	var board := BoardState.new(cells[0].size(), cells.size())
	for y in cells.size():
		for x in cells[y].size():
			var token: String = cells[y][x]
			var type: int = TileTypes.TYPE_FOR_TOKEN[token[0]]
			var rotation := int(token[1]) if token.length() > 1 and token[1].is_valid_int() else 0
			board.set_tile(board.index_of(Vector2i(x, y)), type, rotation, token.ends_with("*"))
	return board


func test_rotate_mask_clockwise() -> void:
	assert_eq(TileTypes.rotate_mask(TileTypes.UP, 1), TileTypes.RIGHT, "up -> right")
	assert_eq(TileTypes.rotate_mask(TileTypes.LEFT, 1), TileTypes.UP, "left wraps to up")
	assert_eq(TileTypes.rotate_mask(TileTypes.UP | TileTypes.RIGHT, 1), TileTypes.RIGHT | TileTypes.DOWN, "corner")
	assert_eq(TileTypes.rotate_mask(TileTypes.UP | TileTypes.DOWN, 2), TileTypes.UP | TileTypes.DOWN, "straight 180")
	assert_eq(TileTypes.rotate_mask(TileTypes.ALL, 3), TileTypes.ALL, "cross")
	assert_eq(TileTypes.rotate_mask(TileTypes.UP, -1), TileTypes.LEFT, "negative steps")


func test_four_rotations_return_to_start() -> void:
	for type in [T.STRAIGHT, T.CORNER, T.TEE, T.SOURCE]:
		var board := BoardState.new(1, 1)
		board.set_tile(0, type, 1)
		var start := board.connections_at(0)
		for i in 4:
			assert_true(board.rotate_cw(0), "rotatable")
		assert_eq(board.connections_at(0), start, "type %d full turn" % type)


func test_taps_between_respects_symmetry() -> void:
	assert_eq(TileTypes.taps_between(T.STRAIGHT, 0, 2), 0, "straight 0 == 2")
	assert_eq(TileTypes.taps_between(T.STRAIGHT, 1, 0), 1, "straight 1 -> 0")
	assert_eq(TileTypes.taps_between(T.CORNER, 3, 0), 1, "corner wraps")
	assert_eq(TileTypes.taps_between(T.CORNER, 0, 3), 3, "corner three taps")


func test_fixed_and_blocked_do_not_rotate() -> void:
	var board := _board(["L0* # . X0"])
	assert_false(board.rotate_cw(0), "fixed")
	assert_eq(board.get_rotation(0), 0, "fixed unchanged")
	assert_false(board.rotate_cw(1), "blocked")
	assert_false(board.rotate_cw(2), "empty")
	assert_false(board.can_rotate(3), "cross is symmetric")


func test_straight_line_connects() -> void:
	var result := SignalSolver.solve(_board(["S1 I1 I1 D3"]))
	assert_true(result.is_solved(), "solved")
	assert_eq(result.powered_order.size(), 4, "all powered")
	assert_eq(result.distance[3], 3, "distance to destination")


func test_requires_reciprocal_connection() -> void:
	# Middle straight is vertical: source points into it but it does not point back.
	var result := SignalSolver.solve(_board(["S1 I0 D3"]))
	assert_false(result.is_solved(), "not solved")
	assert_false(result.is_powered(1), "non-reciprocal neighbour unpowered")
	# A tile pointing at the source without the source pointing back is also unpowered.
	result = SignalSolver.solve(_board(["S0 I1 D3"]))
	assert_false(result.is_powered(1), "source must point at neighbour")


func test_corner_route() -> void:
	# S at (0,0) faces down; corner at (0,1) connects up+right; destination at (1,1) faces left.
	var result := SignalSolver.solve(_board(["S2 .", "L0 D3"]))
	assert_true(result.is_solved(), "corner route solved")


func test_blocked_cell_stops_signal() -> void:
	var board := _board(["S1 # D3"])
	var result := SignalSolver.solve(board)
	assert_false(result.is_powered(1), "blocked never powered")
	assert_false(result.is_solved(), "blocked breaks the route")


func test_loop_terminates_and_visits_once() -> void:
	# A 2x2 ring of corners plus a source feeding it; must not loop forever.
	var board := _board([
		". S2 . .",
		"L1 X0 L2 .",
		"L0 I1 L3 .",
	])
	var result := SignalSolver.solve(board)
	var seen := {}
	for cell in result.powered_order:
		assert_false(seen.has(cell), "cell %d visited once" % cell)
		seen[cell] = true
	assert_true(result.is_powered(board.index_of(Vector2i(0, 2))), "loop fully powered")


func test_branching_reaches_all_destinations() -> void:
	# Tee at (1,0) feeds right and down.
	var board := _board([
		"S1 T1 D3",
		". D0 .",
	])
	var result := SignalSolver.solve(board)
	assert_eq(result.destinations.size(), 2, "two destinations")
	assert_true(result.is_solved(), "both destinations reached")
	board.set_tile(1, T.TEE, 2)
	result = SignalSolver.solve(board)
	assert_false(result.is_solved(), "only one branch reached")
	assert_eq(result.reached_destinations.size(), 1, "one destination reached")


func test_no_destination_is_not_solved() -> void:
	assert_false(SignalSolver.solve(_board(["S1 I1"])).is_solved(), "no destination")


func test_snapshot_restore() -> void:
	var board := _board(["S1 L0 L1 D3"])
	var snap := board.snapshot()
	board.rotate_cw(1)
	board.rotate_cw(2)
	board.restore(snap)
	assert_eq(board.get_rotation(1), 0, "restored 1")
	assert_eq(board.get_rotation(2), 1, "restored 2")


func test_circuit_tile_view_matches_model() -> void:
	var tile: CircuitTile = load("res://scenes/game/circuit_tile.tscn").instantiate()
	var board := _board(["L1"])
	tile.setup(0, board.get_type(0), board.connections_at(0), board.is_fixed(0))
	assert_eq(tile.connections, TileTypes.RIGHT | TileTypes.DOWN, "view mask from model")
	board.rotate_cw(0)
	tile.set_connections(board.connections_at(0), false)
	assert_eq(tile.connections, TileTypes.DOWN | TileTypes.LEFT, "view follows rotation")
	tile.free()
