extends "res://tests/test_case.gd"
## Premium pack rule sets: one-way tiles (Overclock), Boolean gates and switches (Logic Gates),
## repairs and short circuits (Circuit Breaker), portals and phase (Quantum Protocol).

const T := TileTypes.Type


func _board(rows: Array, rules: String = "classic") -> BoardState:
	var cells: Array = []
	for row: String in rows:
		cells.append(row.split(" ", false))
	var board := BoardState.new(cells[0].size(), cells.size())
	board.rules = rules
	for y in cells.size():
		for x in cells[y].size():
			var token: String = cells[y][x]
			var type: int = TileTypes.TYPE_FOR_TOKEN[token[0]]
			var rotation := int(token[1]) if token.length() > 1 and token[1].is_valid_int() else 0
			board.set_tile(board.index_of(Vector2i(x, y)), type, rotation, token.ends_with("*"))
	return board


func _solved(board: BoardState) -> bool:
	return SignalSolver.solve(board).is_solved()


func _pack_puzzle(pack_id: String) -> PuzzleData:
	var catalog := LevelCatalog.new()
	catalog.load_manifest()
	return catalog.get_pack(pack_id).puzzles[0]


# --- Overclock -------------------------------------------------------------------------------

func test_one_way_tile_passes_only_in_its_direction() -> void:
	assert_true(_solved(_board(["S1* A1 D3*"])), "arrow points along the route")
	assert_false(_solved(_board(["S1* A3 D3*"])), "arrow points against the route")
	assert_true(_solved(_board(["D1* A3 S3*"])), "same tile works from the other side")


# --- Logic Gates -----------------------------------------------------------------------------

## Two switches feed the gate's UP and DOWN inputs; its output (RIGHT) lights the destination.
func _gate_board(gate: String, a: int, b: int) -> BoardState:
	return _board([". W%d L2* ." % a, ". . %s0* D3*" % gate, ". W%d L3* ." % b], "logic")


func test_boolean_gate_truth_tables() -> void:
	var expected := {
		"G": [false, false, false, true],  # AND
		"O": [false, true, true, true],    # OR
		"Y": [false, true, true, false],   # XOR
	}
	for gate: String in expected:
		for combo in 4:
			var a := combo & 1
			var b := (combo >> 1) & 1
			assert_eq(_solved(_gate_board(gate, a, b)), expected[gate][combo], "%s with inputs %d,%d" % [gate, a, b])


func test_not_gate_inverts_its_input() -> void:
	assert_false(_solved(_board(["W1 I1 N1* I1 D3*"], "logic")), "input on -> output off")
	assert_true(_solved(_board(["W0 I1 N1* I1 D3*"], "logic")), "input off -> output on")


func test_unstable_logic_loop_is_invalid_not_a_hang() -> void:
	# A NOT gate whose output feeds its own input never settles.
	var result := SignalSolver.solve(_board(["L1 I1 L2", "N0* . I0", "L0 I1 L3"], "logic"))
	assert_false(result.failure.is_empty(), "oscillation reported")
	assert_false(result.is_solved(), "never solved")


func test_switch_taps_toggle_and_undo() -> void:
	var board := _board(["W0 I1 D3*"], "logic")
	assert_true(board.can_tap(0), "switch is tappable")
	board.tap(0)
	assert_eq(board.get_rotation(0), 1, "on")
	board.tap(0)
	assert_eq(board.get_rotation(0), 0, "off again")


# --- Circuit Breaker -------------------------------------------------------------------------

func test_broken_wire_blocks_until_repaired() -> void:
	var board := _board(["S1* B1 D3*"], "repair")
	assert_false(_solved(board), "broken wire does not conduct")
	assert_true(board.tap(1), "tap repairs")
	assert_eq(board.get_rotation(1), 3, "repaired keeps its orientation")
	assert_true(_solved(board), "repaired wire conducts")
	assert_false(board.can_tap(1), "repair is permanent")


func test_powering_a_fault_terminal_is_a_short_circuit() -> void:
	var safe := SignalSolver.solve(_board(["S1* T3 D3*", ". Z0* ."], "repair"))
	assert_true(safe.is_solved(), "tee that avoids the fault wins")
	var shorted := SignalSolver.solve(_board(["S1* T1 D3*", ". Z0* ."], "repair"))
	assert_true(shorted.is_powered(4), "fault is powered")
	assert_false(shorted.failure.is_empty(), "short circuit reported")
	assert_false(shorted.is_solved(), "cannot win while shorted")


# --- Quantum Protocol ------------------------------------------------------------------------

func test_portals_teleport_between_distant_cells() -> void:
	assert_true(_solved(_board(["S1* P0* . . P0* D3*"], "quantum")), "signal reappears at the paired portal")
	assert_false(_solved(_board(["S1* P0* . . P1* D3*"], "quantum")), "different pair ids do not link")


func test_destinations_accept_only_their_phase() -> void:
	assert_true(_solved(_board(["S1* I1 D3*"], "quantum")), "phase 0 reaches a normal destination")
	assert_false(_solved(_board(["S1* V1 D3*"], "quantum")), "inverted signal is rejected")
	assert_true(_solved(_board(["S1* V1 Q3*"], "quantum")), "inverted signal reaches the phase destination")
	assert_false(_solved(_board(["S1* I1 Q3*"], "quantum")), "uninverted signal is rejected")


func test_portal_cycles_terminate() -> void:
	var result := SignalSolver.solve(_board(["S1* P0* P0*"], "quantum"))
	assert_true(result.is_powered(2), "partner portal is reached once")


# --- Content and controller ------------------------------------------------------------------

func test_slice_puzzles_load_with_their_rules() -> void:
	var expected := {"overclock": "classic", "logic_gates": "logic", "circuit_breaker": "repair", "quantum_protocol": "quantum"}
	for pack_id: String in expected:
		var puzzle := _pack_puzzle(pack_id)
		assert_eq(puzzle.rules, expected[pack_id], "%s opening level rules" % pack_id)
		assert_false(puzzle.tip.is_empty(), "%s opening level teaches its mechanic" % pack_id)
		assert_false(SignalSolver.solve(puzzle.create_board()).is_solved(), "%s not solved at load" % pack_id)
		assert_true(SignalSolver.solve(puzzle.create_solution_board()).is_solved(), "%s stored solution wins" % pack_id)


func test_rules_must_match_the_tiles_used() -> void:
	var data := {"id": "x", "rows": ["S1* W0 D3*"], "solution": ["101"], "par": 1}
	assert_false(PuzzleValidator.validate(PuzzleData.from_dict(data)).is_empty(), "switch needs logic rules")
	data["rules"] = "nonsense"
	assert_false(PuzzleValidator.validate(PuzzleData.from_dict(data)).is_empty(), "unknown rules rejected")


func test_unpaired_portal_is_invalid() -> void:
	var data := {"id": "x", "rules": "quantum", "rows": ["S1* P0* D3*"], "solution": ["100"], "par": 0}
	var errors := PuzzleValidator.validate(PuzzleData.from_dict(data))
	assert_false(errors.is_empty(), "single portal rejected")


func test_classic_puzzles_default_to_classic_rules() -> void:
	var puzzle := PuzzleData.from_dict({"id": "c", "rows": ["S1* I0 D3*"], "solution": ["111"], "par": 1})
	assert_eq(puzzle.rules, "classic", "default rules")
	assert_false(puzzle.to_dict().has("rules"), "classic puzzles keep their old JSON shape")


func test_hint_and_undo_work_for_switches() -> void:
	var controller := PuzzleController.new()
	controller.start(_pack_puzzle("logic_gates"))
	assert_eq(controller.state, PuzzleController.State.PLAYING, "starts unsolved")
	var hinted := controller.apply_hint()
	assert_true(hinted >= 0, "hint points at a switch")
	assert_eq(controller.state, PuzzleController.State.WON, "one flip solves the lesson level")
	var controller2 := PuzzleController.new()
	controller2.start(_pack_puzzle("circuit_breaker"))
	assert_true(controller2.tap(1), "repair the wire")
	assert_true(controller2.undo(), "undo")
	assert_eq(controller2.board.get_rotation(1), 1, "wire is broken again after undo")
