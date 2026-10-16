class_name PuzzleController
extends RefCounted
## Rules of a play session: taps, move counting, undo/reset, hints, win and out-of-moves detection.
## Pure logic with signals, so it is testable without any scene.

signal board_changed(changed_index: int, animate: bool)
signal tap_rejected(index: int)
signal moves_changed(moves: int)
signal won(moves: int, stars: int)
signal failed

enum State { PLAYING, WON, FAILED }

var puzzle: PuzzleData
var board: BoardState
var moves: int = 0
var state: State = State.PLAYING
var hints_used: int = 0
var result: SignalSolver.Result

## Each entry: { "rotations": PackedByteArray, "moves": int }
var _undo_stack: Array[Dictionary] = []
## Solution path cells in BFS order from the source, used for hints.
var _hint_order: PackedInt32Array = PackedInt32Array()


func start(puzzle_data: PuzzleData) -> void:
	puzzle = puzzle_data
	board = puzzle.create_board()
	moves = 0
	hints_used = 0
	state = State.PLAYING
	_undo_stack.clear()
	_hint_order = SignalSolver.solve(puzzle.create_solution_board()).powered_order
	result = SignalSolver.solve(board)
	board_changed.emit(-1, false)
	moves_changed.emit(moves)


func is_playing() -> bool:
	return state == State.PLAYING


func can_undo() -> bool:
	return state != State.WON and not _undo_stack.is_empty()


func moves_left() -> int:
	return maxi(0, puzzle.move_limit - moves) if puzzle.has_move_limit() else -1


## Handles a tap. Returns true if the board changed.
func tap(index: int) -> bool:
	if state != State.PLAYING:
		return false
	if not board.can_rotate(index):
		tap_rejected.emit(index)
		return false
	_push_undo()
	board.rotate_cw(index)
	moves += 1
	_after_move(index)
	return true


func undo() -> bool:
	if not can_undo():
		return false
	var entry: Dictionary = _undo_stack.pop_back()
	board.restore(entry["rotations"])
	moves = entry["moves"]
	state = State.PLAYING
	result = SignalSolver.solve(board)
	board_changed.emit(-1, false)
	moves_changed.emit(moves)
	return true


func reset() -> void:
	if state == State.WON:
		return
	board = puzzle.create_board()
	moves = 0
	state = State.PLAYING
	_undo_stack.clear()
	result = SignalSolver.solve(board)
	board_changed.emit(-1, false)
	moves_changed.emit(moves)


## Cell the next hint would fix, or -1 if the board already matches the solution path.
func next_hint_cell() -> int:
	for index in _hint_order:
		if board.can_rotate(index) and board.connections_at(index) != TileTypes.connections(board.get_type(index), puzzle.solution[index]):
			return index
	return -1


## Turns the first wrong tile along the solution path into its solved orientation.
## Costs as many moves as the taps it performs, so hints never beat par.
## Returns the changed cell index or -1 if no hint applies.
func apply_hint() -> int:
	if state != State.PLAYING:
		return -1
	var index := next_hint_cell()
	if index < 0:
		return -1
	_push_undo()
	moves += TileTypes.taps_between(board.get_type(index), board.get_rotation(index), puzzle.solution[index])
	board.rotations[index] = puzzle.solution[index]
	hints_used += 1
	_after_move(index)
	return index


func _push_undo() -> void:
	_undo_stack.append({"rotations": board.snapshot(), "moves": moves})


func _after_move(index: int) -> void:
	result = SignalSolver.solve(board)
	board_changed.emit(index, true)
	moves_changed.emit(moves)
	if result.is_solved():
		state = State.WON
		won.emit(moves, puzzle.stars_for(moves))
	elif puzzle.has_move_limit() and moves >= puzzle.move_limit:
		state = State.FAILED
		failed.emit()
