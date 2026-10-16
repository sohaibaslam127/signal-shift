class_name SignalSolver
extends RefCounted
## Deterministic breadth-first signal propagation over a BoardState.
## A signal moves from tile A to neighbour B in direction d only if A connects in d and
## B connects in the opposite direction. Blocked tiles never carry signal. Each tile is
## visited at most once, so loops and branches terminate.


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

	## The puzzle is solved when it has at least one destination and every destination is powered.
	func is_solved() -> bool:
		return not destinations.is_empty() and reached_destinations.size() == destinations.size()


static func solve(board: BoardState) -> Result:
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

	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		result.powered_order.append(current)
		if board.get_type(current) == TileTypes.Type.DESTINATION:
			result.reached_destinations.append(current)
		var mask := board.connections_at(current)
		if mask == 0:
			continue
		var cell := board.cell_of(current)
		for direction in 4:
			if mask & TileTypes.DIRECTION_BITS[direction] == 0:
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
			if board.connections_at(neighbour) & back_bit == 0:
				continue
			result.powered[neighbour] = 1
			result.distance[neighbour] = result.distance[current] + 1
			queue.append(neighbour)
	return result
