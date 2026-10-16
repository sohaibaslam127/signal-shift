class_name PuzzleValidator
extends RefCounted
## Checks a PuzzleData against the game rules. A puzzle is only playable if `validate` returns no errors.

const MIN_SIZE := 2
const MAX_WIDTH := 8
const MAX_HEIGHT := 10


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

	var sources := 0
	var destinations := 0
	for i in puzzle.types.size():
		var type := puzzle.types[i]
		if not TileTypes.is_valid_type(type):
			errors.append("invalid tile type %d at %d" % [type, i])
			continue
		match type:
			TileTypes.Type.SOURCE:
				sources += 1
			TileTypes.Type.DESTINATION:
				destinations += 1
		# Tiles that cannot change must have the same connections in the solution.
		var can_change := puzzle.fixed[i] == 0 and TileTypes.has_orientation(type)
		if not can_change and TileTypes.connections(type, puzzle.rotations[i]) != TileTypes.connections(type, puzzle.solution[i]):
			errors.append("cell %d cannot rotate but its solution differs" % i)
		if (type == TileTypes.Type.BLOCKED or type == TileTypes.Type.EMPTY) and puzzle.fixed[i] != 0:
			errors.append("cell %d: blocked/empty cells must not be marked fixed" % i)
	if sources == 0:
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


static func _prefix(puzzle: PuzzleData, errors: PackedStringArray) -> PackedStringArray:
	var label := puzzle.id if not puzzle.id.is_empty() else "<unnamed>"
	var result := PackedStringArray()
	for error in errors:
		result.append("%s: %s" % [label, error])
	return result
