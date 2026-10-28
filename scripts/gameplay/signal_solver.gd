class_name SignalSolver
extends RefCounted
## Deterministic breadth-first signal propagation over a BoardState.
## A signal moves from tile A to neighbour B in direction d only if A connects in d and
## B connects in the opposite direction. Blocked tiles never carry signal. Each tile is
## visited at most once, so loops and branches terminate.
##
## Gate tiles (TileTypes.is_gate) are the one exception to plain bidirectional propagation:
## a gate only forwards signal out of its single output side, and only once every one of its
## other connected sides has independently received power. Power arriving on a gate's output
## side never activates it (no backward flow).


class Result:
	extends RefCounted
	## 1 for every cell that carries signal, indexed like BoardState arrays.
	var powered: PackedByteArray = PackedByteArray()
	## Powered cells in BFS order (source first), for staged highlight animation.
	var powered_order: PackedInt32Array = PackedInt32Array()
	## BFS distance from the nearest source for each powered cell (-1 if unpowered).
	var distance: PackedInt32Array = PackedInt32Array()
	var destinations: PackedInt32Array = PackedInt32Array()
	var reached_destinations: PackedInt32Array = PackedInt32Array()

	func is_powered(index: int) -> bool:
		return index >= 0 and index < powered.size() and powered[index] != 0

	## Non-empty when the board is in a failure state that blocks winning (e.g. a short circuit).
	var failure: String = ""
	## Quantum rules: per cell, bit 0 = reached in phase 0, bit 1 = reached in phase 180.
	var phases: PackedByteArray = PackedByteArray()

	## The puzzle is solved when it has at least one destination, every destination is powered and no failure applies.
	func is_solved() -> bool:
		return failure.is_empty() and not destinations.is_empty() and reached_destinations.size() == destinations.size()


## Solves the board under its rule set. "classic" and "repair" are connectivity (repair adds
## the short-circuit check); "logic" and "quantum" live in PackRules.
static func solve(board: BoardState) -> Result:
	match board.rules:
		"logic":
			return PackRules.solve_logic(board)
		"quantum":
			return PackRules.solve_quantum(board)
		"repair":
			return PackRules.check_short_circuit(board, _propagate(board))
	return _propagate(board)


static func _propagate(board: BoardState) -> Result:
	var result := Result.new()
	var count := board.cell_count()
	result.powered.resize(count)
	result.powered.fill(0)
	result.distance.resize(count)
	result.distance.fill(-1)
	result.destinations = board.indices_of_type(TileTypes.Type.DESTINATION)

	var queue := board.indices_of_type(TileTypes.Type.SOURCE)
	for source in queue:
		result.powered[source] = 1
		result.distance[source] = 0

	## Gate index -> bitmask of its input sides that have been powered so far.
	var gate_satisfied := {}

	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		result.powered_order.append(current)
		if board.get_type(current) == TileTypes.Type.DESTINATION:
			result.reached_destinations.append(current)
		var mask := board.connections_at(current)
		# A fault terminal is a sink: it can be powered (a short circuit) but never conducts onward.
		if mask == 0 or board.get_type(current) == TileTypes.Type.FAULT:
			continue
		var current_output_bit := TileTypes.directed_output_bit(board.get_type(current), board.get_rotation(current))
		var cell := board.cell_of(current)
		for direction in 4:
			var bit := TileTypes.DIRECTION_BITS[direction]
			if mask & bit == 0:
				continue
			# A gate only ever forwards power out of its output side.
			if current_output_bit != 0 and bit != current_output_bit:
				continue
			var neighbour_cell := cell + TileTypes.DIRECTION_OFFSETS[direction]
			if not board.in_bounds(neighbour_cell):
				continue
			var neighbour := board.index_of(neighbour_cell)
			if result.powered[neighbour] != 0:
				continue
			if board.get_type(neighbour) == TileTypes.Type.BLOCKED:
				continue
			var back_bit := TileTypes.DIRECTION_BITS[TileTypes.opposite_direction(direction)]
			var neighbour_mask := board.connections_at(neighbour)
			if neighbour_mask & back_bit == 0:
				continue
			var neighbour_output_bit := TileTypes.directed_output_bit(board.get_type(neighbour), board.get_rotation(neighbour))
			if neighbour_output_bit != 0:
				if back_bit == neighbour_output_bit:
					# Power cannot enter a gate or one-way tile through its own output side.
					continue
			if TileTypes.is_gate(board.get_type(neighbour)):
				var satisfied: int = int(gate_satisfied.get(neighbour, 0)) | back_bit
				gate_satisfied[neighbour] = satisfied
				var input_bits := neighbour_mask & (TileTypes.ALL ^ neighbour_output_bit)
				if satisfied & input_bits != input_bits:
					continue
			result.powered[neighbour] = 1
			result.distance[neighbour] = result.distance[current] + 1
			queue.append(neighbour)
	return result
