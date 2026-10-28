class_name PackRules
extends RefCounted
## Deterministic simulators for the premium packs' rule sets. Every function is a pure function
## of a BoardState, and every loop is bounded, so no board (including cyclic ones) can hang.
##
## - logic:   gates (AND/OR/XOR/NOT) and switches. Wires carry power by BFS; each gate's output is
##            re-evaluated from the power reaching its input sides until no gate changes. A circuit
##            that never settles (e.g. a NOT gate feeding itself) is an invalid, unsolved state.
## - repair:  plain connectivity plus a short-circuit rule: powering a fault terminal fails the board.
## - quantum: the signal has a phase (0 or 180 degrees). Inverters flip it, portals teleport it to the
##            paired portal, and destinations only accept their own phase.


# --- repair ----------------------------------------------------------------------------------

static func check_short_circuit(board: BoardState, result: SignalSolver.Result) -> SignalSolver.Result:
	for index in board.indices_of_type(TileTypes.Type.FAULT):
		if result.is_powered(index):
			result.failure = "Short circuit: a fault terminal is powered."
			break
	return result


# --- logic -----------------------------------------------------------------------------------

static func solve_logic(board: BoardState) -> SignalSolver.Result:
	var gates := PackedInt32Array()
	for i in board.cell_count():
		if TileTypes.is_gate(board.get_type(i)):
			gates.append(i)
	var active := {}  # gate index -> true while its output is on
	var result: SignalSolver.Result
	var delivered := {}
	# Each round can only change gate outputs, so a settled board is reached within a bounded number of rounds.
	for _round in gates.size() * 2 + 4:
		delivered = {}
		result = _logic_pass(board, active, delivered)
		var next := {}
		for gate in gates:
			if _gate_output(board.get_type(gate), board.get_rotation(gate), int(delivered.get(gate, 0))):
				next[gate] = true
		if next.keys() == active.keys():
			return result
		active = next
	result.failure = "Unstable circuit: a gate keeps flipping."
	return result


## One BFS from sources, ON switches and active gates. `delivered` collects, per gate, the input
## sides that currently receive power.
static func _logic_pass(board: BoardState, active: Dictionary, delivered: Dictionary) -> SignalSolver.Result:
	var result := SignalSolver.Result.new()
	var count := board.cell_count()
	result.powered.resize(count)
	result.powered.fill(0)
	result.distance.resize(count)
	result.distance.fill(-1)
	result.destinations = board.indices_of_type(TileTypes.Type.DESTINATION)
	var queue := PackedInt32Array()
	for i in count:
		var type := board.get_type(i)
		if type == TileTypes.Type.SOURCE or (type == TileTypes.Type.SWITCH and board.get_rotation(i) == 1) or active.has(i):
			result.powered[i] = 1
			result.distance[i] = 0
			queue.append(i)
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		result.powered_order.append(current)
		if board.get_type(current) == TileTypes.Type.DESTINATION:
			result.reached_destinations.append(current)
		var mask := board.connections_at(current)
		var out_bit := TileTypes.directed_output_bit(board.get_type(current), board.get_rotation(current))
		var cell := board.cell_of(current)
		for direction in 4:
			var bit := TileTypes.DIRECTION_BITS[direction]
			if mask & bit == 0 or (out_bit != 0 and bit != out_bit):
				continue
			var neighbour_cell := cell + TileTypes.DIRECTION_OFFSETS[direction]
			if not board.in_bounds(neighbour_cell):
				continue
			var neighbour := board.index_of(neighbour_cell)
			var back_bit := TileTypes.DIRECTION_BITS[TileTypes.opposite_direction(direction)]
			if board.get_type(neighbour) == TileTypes.Type.BLOCKED or board.connections_at(neighbour) & back_bit == 0:
				continue
			var neighbour_out := TileTypes.directed_output_bit(board.get_type(neighbour), board.get_rotation(neighbour))
			if neighbour_out == back_bit:
				continue
			if TileTypes.is_gate(board.get_type(neighbour)):
				# Gates never conduct input power; they only record it for their own evaluation.
				delivered[neighbour] = int(delivered.get(neighbour, 0)) | back_bit
				continue
			if result.powered[neighbour] != 0:
				continue
			result.powered[neighbour] = 1
			result.distance[neighbour] = result.distance[current] + 1
			queue.append(neighbour)
	return result


## Truth function of a gate given the input sides that currently receive power.
static func _gate_output(type: int, rotation: int, delivered: int) -> bool:
	var inputs := TileTypes.gate_input_bits(type, rotation)
	var live := delivered & inputs
	match type:
		TileTypes.Type.GATE_AND:
			return inputs != 0 and live == inputs
		TileTypes.Type.GATE_OR:
			return live != 0
		TileTypes.Type.GATE_XOR:
			return _bit_count(live) % 2 == 1
		TileTypes.Type.GATE_NOT:
			return live == 0
	return false


static func _bit_count(mask: int) -> int:
	var total := 0
	for bit in TileTypes.DIRECTION_BITS:
		if mask & bit != 0:
			total += 1
	return total


# --- quantum ---------------------------------------------------------------------------------

## Phase bits: 1 = phase 0, 2 = phase 180. A search state is (cell, phase, previous cell): signal never
## doubles straight back along the wire it arrived on (otherwise an inverter could be cancelled by
## reflecting through it), and each state is visited once, so loops and portal cycles terminate.
static func solve_quantum(board: BoardState) -> SignalSolver.Result:
	var result := SignalSolver.Result.new()
	var count := board.cell_count()
	result.powered.resize(count)
	result.powered.fill(0)
	result.distance.resize(count)
	result.distance.fill(-1)
	result.phases.resize(count)
	result.phases.fill(0)
	result.destinations = board.indices_of_type(TileTypes.Type.DESTINATION)
	result.destinations.append_array(board.indices_of_type(TileTypes.Type.PHASE_DEST))

	var portals := {}  # pair id -> Array of cell indices
	for index in board.indices_of_type(TileTypes.Type.PORTAL):
		var pair_id := board.get_rotation(index)
		if not portals.has(pair_id):
			portals[pair_id] = []
		portals[pair_id].append(index)

	var visited := {}
	var queue: Array[Vector3i] = []  # x = cell, y = phase (0 or 1), z = previous cell or -1
	for source in board.indices_of_type(TileTypes.Type.SOURCE):
		_visit(result, visited, queue, source, 0, -1, 0)
	var head := 0
	while head < queue.size():
		var state := queue[head]
		head += 1
		var current := state.x
		var phase := state.y
		result.powered_order.append(current)
		var dist := result.distance[current]
		if board.get_type(current) == TileTypes.Type.PORTAL:
			for partner: int in portals.get(board.get_rotation(current), []):
				if partner != current:
					_visit(result, visited, queue, partner, phase, -1, dist + 1)
		var mask := board.connections_at(current)
		var cell := board.cell_of(current)
		for direction in 4:
			var bit := TileTypes.DIRECTION_BITS[direction]
			if mask & bit == 0:
				continue
			var neighbour_cell := cell + TileTypes.DIRECTION_OFFSETS[direction]
			if not board.in_bounds(neighbour_cell):
				continue
			var neighbour := board.index_of(neighbour_cell)
			if neighbour == state.z:
				continue
			var back_bit := TileTypes.DIRECTION_BITS[TileTypes.opposite_direction(direction)]
			if board.get_type(neighbour) == TileTypes.Type.BLOCKED or board.connections_at(neighbour) & back_bit == 0:
				continue
			var next_phase := phase ^ (1 if board.get_type(neighbour) == TileTypes.Type.INVERTER else 0)
			_visit(result, visited, queue, neighbour, next_phase, current, dist + 1)

	for index in result.destinations:
		var wanted := 2 if board.get_type(index) == TileTypes.Type.PHASE_DEST else 1
		if result.phases[index] & wanted != 0:
			result.reached_destinations.append(index)
	return result


static func _visit(result: SignalSolver.Result, visited: Dictionary, queue: Array[Vector3i], cell: int, phase: int, previous: int, distance: int) -> void:
	var key := Vector3i(cell, phase, previous)
	if visited.has(key):
		return
	visited[key] = true
	result.phases[cell] |= 1 << phase
	if result.powered[cell] == 0:
		result.powered[cell] = 1
		result.distance[cell] = distance
	queue.append(key)
