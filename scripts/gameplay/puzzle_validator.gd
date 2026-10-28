class_name PuzzleValidator
extends RefCounted
## Checks a PuzzleData against the game rules. A puzzle is only playable if `validate` returns no errors.

const MIN_SIZE := 2
const MAX_WIDTH := 8
const MAX_HEIGHT := 10
const RULE_SETS := ["classic", "logic", "repair", "quantum"]


static func validate(puzzle: PuzzleData) -> PackedStringArray:
	var errors := PackedStringArray()
	errors.append_array(puzzle.parse_errors)
	if not errors.is_empty():
		return _prefix(puzzle, errors)

	if puzzle.id.is_empty():
		errors.append("missing id")
	if puzzle.width < MIN_SIZE or puzzle.height < MIN_SIZE or puzzle.width > MAX_WIDTH or puzzle.height > MAX_HEIGHT:
		errors.append("grid %dx%d outside %d..%dx%d..%d" % [puzzle.width, puzzle.height, MIN_SIZE, MAX_WIDTH, MIN_SIZE, MAX_HEIGHT])
		return _prefix(puzzle, errors)

	if not puzzle.rules in RULE_SETS:
		errors.append("unknown rules '%s'" % puzzle.rules)
		return _prefix(puzzle, errors)

	var sources := 0
	var destinations := 0
	var inputs := 0
	var portal_ids := {}
	for i in puzzle.types.size():
		var type := puzzle.types[i]
		if not TileTypes.is_valid_type(type):
			errors.append("invalid tile type %d at %d" % [type, i])
			continue
		match type:
			TileTypes.Type.SOURCE:
				sources += 1
			TileTypes.Type.DESTINATION, TileTypes.Type.PHASE_DEST:
				destinations += 1
			TileTypes.Type.SWITCH:
				inputs += 1
			TileTypes.Type.PORTAL:
				portal_ids[puzzle.rotations[i]] = int(portal_ids.get(puzzle.rotations[i], 0)) + 1
		# Mechanics only work under the rule set that implements them.
		if TileTypes.RULES_FOR_TYPE.has(type) and TileTypes.RULES_FOR_TYPE[type] != puzzle.rules:
			errors.append("cell %d: tile needs rules '%s'" % [i, TileTypes.RULES_FOR_TYPE[type]])
		if TileTypes.is_stateful(type) and not _state_in_range(type, puzzle.rotations[i], puzzle.solution[i]):
			errors.append("cell %d: invalid state %d -> %d" % [i, puzzle.rotations[i], puzzle.solution[i]])
		if TileTypes.carries_id(type) and (puzzle.rotations[i] != puzzle.solution[i] or puzzle.fixed[i] == 0):
			errors.append("cell %d: portals must be fixed with an unchanging pair id" % i)
		# Tiles that cannot change must have the same connections in the solution.
		var can_change := puzzle.fixed[i] == 0 and (TileTypes.has_orientation(type) or TileTypes.is_stateful(type))
		if not can_change and TileTypes.state_differs(type, puzzle.rotations[i], puzzle.solution[i]):
			errors.append("cell %d cannot rotate but its solution differs" % i)
		if (type == TileTypes.Type.BLOCKED or type == TileTypes.Type.EMPTY) and puzzle.fixed[i] != 0:
			errors.append("cell %d: blocked/empty cells must not be marked fixed" % i)
	for pair_id: int in portal_ids:
		if portal_ids[pair_id] != 2:
			errors.append("portal pair %d must have exactly two portals" % pair_id)
	if sources == 0 and not (puzzle.rules == "logic" and inputs > 0):
		errors.append("no source")
	if destinations == 0:
		errors.append("no destination")
	if not errors.is_empty():
		return _prefix(puzzle, errors)

	if not SignalSolver.solve(puzzle.create_solution_board()).is_solved():
		errors.append("stored solution does not power every destination")
	if SignalSolver.solve(puzzle.create_board()).is_solved():
		errors.append("puzzle is already solved at load")

	var computed_par := puzzle.compute_par()
	if puzzle.par != computed_par:
		errors.append("par %d does not match solution distance %d" % [puzzle.par, computed_par])
	if puzzle.move_limit < 0:
		errors.append("negative move limit")
	elif puzzle.move_limit > 0 and puzzle.move_limit < computed_par:
		errors.append("move limit %d below par %d" % [puzzle.move_limit, computed_par])
	return _prefix(puzzle, errors)


## Broken wires keep their orientation bit and may only be repaired; switches are 0 or 1.
static func _state_in_range(type: int, initial: int, solution: int) -> bool:
	if type == TileTypes.Type.SWITCH:
		return initial <= 1 and solution <= 1
	return (initial & 1) == (solution & 1) and solution >= initial


static func _prefix(puzzle: PuzzleData, errors: PackedStringArray) -> PackedStringArray:
	var label := puzzle.id if not puzzle.id.is_empty() else "<unnamed>"
	var result := PackedStringArray()
	for error in errors:
		result.append("%s: %s" % [label, error])
	return result
