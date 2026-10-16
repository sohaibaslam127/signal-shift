extends "res://tests/test_case.gd"
## Puzzle parsing, validation, win detection, undo/reset and hints.


func _puzzle(rows: Array, solution: Array, par: int, move_limit: int = 0, puzzle_id: String = "t1") -> PuzzleData:
	var data := {"id": puzzle_id, "name": "Test", "rows": rows, "solution": solution, "par": par}
	if move_limit > 0:
		data["move_limit"] = move_limit
	return PuzzleData.from_dict(data)


func _simple() -> PuzzleData:
	# Source faces right, two vertical straights need one tap each, destination faces left.
	return _puzzle(["S1* I0 I0 D3*", ". . . ."], ["1113", "0000"], 2)


func test_valid_puzzle_has_no_errors() -> void:
	assert_eq(PuzzleValidator.validate(_simple()), PackedStringArray(), "valid")


func test_round_trip_dict() -> void:
	var puzzle := _simple()
	var again := PuzzleData.from_dict(puzzle.to_dict())
	assert_eq(again.types, puzzle.types, "types")
	assert_eq(again.rotations, puzzle.rotations, "rotations")
	assert_eq(again.fixed, puzzle.fixed, "fixed")
	assert_eq(again.solution, puzzle.solution, "solution")


func test_rejects_missing_source_and_destination() -> void:
	var errors := PuzzleValidator.validate(_puzzle(["I0 I0", ". ."], ["11", "00"], 2))
	assert_eq(errors.size(), 2, "no source + no destination")


func test_rejects_bad_dimensions_and_tokens() -> void:
	assert_false(PuzzleValidator.validate(_puzzle(["S1 D3"], ["13"], 0)).is_empty(), "1 row is too small")
	assert_false(PuzzleValidator.validate(_puzzle(["S1 Q0", "D3 ."], ["10", "30"], 0)).is_empty(), "unknown token")
	assert_false(PuzzleValidator.validate(_puzzle(["S1 I0", "D3"], ["10", "3"], 0)).is_empty(), "ragged rows")
	assert_false(PuzzleValidator.validate(_puzzle(["S1 I0 D3"], ["11"], 1)).is_empty(), "short solution")


func test_rejects_unsolvable_solution() -> void:
	var errors := PuzzleValidator.validate(_puzzle(["S1* I0 I0 D3*", ". . . ."], ["1103", "0000"], 1))
	assert_false(errors.is_empty(), "solution must power the destination")


func test_rejects_already_solved_board() -> void:
	var errors := PuzzleValidator.validate(_puzzle(["S1* I1 D3*", ". . ."], ["113", "000"], 0))
	assert_false(errors.is_empty(), "already solved at load")


func test_rejects_fixed_tile_needing_rotation() -> void:
	var errors := PuzzleValidator.validate(_puzzle(["S1* I0* D3*", ". . ."], ["113", "000"], 1))
	assert_false(errors.is_empty(), "fixed tile cannot be part of the required changes")


func test_rejects_wrong_par_and_low_limit() -> void:
	assert_false(PuzzleValidator.validate(_puzzle(["S1* I0 I0 D3*", ". . . ."], ["1113", "0000"], 3)).is_empty(), "par mismatch")
	assert_false(PuzzleValidator.validate(_puzzle(["S1* I0 I0 D3*", ". . . ."], ["1113", "0000"], 2, 1)).is_empty(), "limit below par")


func test_win_detection_emits_once() -> void:
	var controller := PuzzleController.new()
	var wins := [0]
	controller.won.connect(func(_m: int, _s: int) -> void: wins[0] += 1)
	controller.start(_simple())
	controller.tap(1)
	assert_eq(controller.state, PuzzleController.State.PLAYING, "not yet")
	controller.tap(2)
	assert_eq(controller.state, PuzzleController.State.WON, "won")
	assert_eq(wins[0], 1, "one victory event")
	assert_false(controller.tap(2), "taps ignored after win")
	assert_false(controller.undo(), "no undo after win")
	assert_eq(wins[0], 1, "still one victory event")
	assert_eq(controller.moves, 2, "moves counted")


func test_fixed_tap_rejected_without_move() -> void:
	var controller := PuzzleController.new()
	var rejected := [0]
	controller.tap_rejected.connect(func(_i: int) -> void: rejected[0] += 1)
	controller.start(_simple())
	assert_false(controller.tap(0), "fixed source")
	assert_eq(rejected[0], 1, "rejection signalled")
	assert_eq(controller.moves, 0, "no move")


func test_undo_restores_exact_state() -> void:
	var controller := PuzzleController.new()
	controller.start(_simple())
	var initial := controller.board.snapshot()
	controller.tap(1)
	var after_one := controller.board.snapshot()
	controller.tap(1)
	controller.tap(1)
	assert_true(controller.is_playing(), "still playing")
	assert_true(controller.undo(), "undo 1")
	assert_true(controller.undo(), "undo 2")
	assert_eq(controller.board.snapshot(), after_one, "state after first move")
	assert_eq(controller.moves, 1, "moves restored")
	assert_true(controller.undo(), "undo 3")
	assert_eq(controller.board.snapshot(), initial, "initial state")
	assert_false(controller.undo(), "stack empty")


func test_reset_restores_initial_board() -> void:
	var controller := PuzzleController.new()
	controller.start(_simple())
	controller.tap(1)
	controller.tap(1)
	controller.reset()
	assert_eq(controller.board.snapshot(), _simple().rotations, "initial rotations")
	assert_eq(controller.moves, 0, "moves reset")
	assert_false(controller.can_undo(), "undo cleared")


func test_move_limit_fails_and_undo_recovers() -> void:
	var controller := PuzzleController.new()
	var failed := [0]
	controller.failed.connect(func() -> void: failed[0] += 1)
	controller.start(_puzzle(["S1* I0 I0 D3*", ". . . ."], ["1113", "0000"], 2, 2))
	controller.tap(1)
	controller.tap(1)
	assert_eq(controller.state, PuzzleController.State.FAILED, "out of moves")
	assert_eq(failed[0], 1, "failed once")
	assert_false(controller.tap(1), "no taps when failed")
	assert_true(controller.undo(), "undo from failed")
	assert_true(controller.is_playing(), "playing again")


func test_hint_moves_toward_solution() -> void:
	var controller := PuzzleController.new()
	controller.start(_simple())
	assert_eq(controller.next_hint_cell(), 1, "first wrong tile from source")
	assert_eq(controller.apply_hint(), 1, "hint applied")
	assert_eq(controller.board.get_rotation(1) % 2, 1, "straight now horizontal")
	assert_eq(controller.apply_hint(), 2, "next hint")
	assert_eq(controller.state, PuzzleController.State.WON, "hints can finish")


func test_stars() -> void:
	var puzzle := _simple()
	assert_eq(puzzle.stars_for(2), 3, "par")
	assert_eq(puzzle.stars_for(4), 2, "near par")
	assert_eq(puzzle.stars_for(9), 1, "far")


func test_shipped_catalog_is_valid() -> void:
	var catalog := LevelCatalog.new()
	assert_true(catalog.load_manifest(), "catalog loads without errors: %s" % "; ".join(catalog.errors))
	assert_true(catalog.get_pack("campaign") != null, "campaign present")


func test_hint_costs_its_taps() -> void:
	var controller := PuzzleController.new()
	# Corner at (0,1) needs three taps (L1 -> L0).
	controller.start(_puzzle(["S2* .", "L1 D3*"], ["20", "03"], 3))
	controller.apply_hint()
	assert_eq(controller.moves, 3, "hint counts the taps it performs")
	assert_eq(controller.state, PuzzleController.State.WON, "solved")
