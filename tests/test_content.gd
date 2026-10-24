extends "res://tests/test_case.gd"
## Every shipped puzzle validates, and the campaign follows the difficulty curve in the spec.

const T := TileTypes.Type
const FILES := {
	"campaign": "res://resources/puzzles/campaign/campaign.json",
	"daily": "res://resources/puzzles/daily/daily.json",
	"overclock": "res://resources/puzzles/packs/overclock.json",
	"logic_gates": "res://resources/puzzles/packs/logic_gates.json",
	"circuit_breaker": "res://resources/puzzles/packs/circuit_breaker.json",
	"quantum_protocol": "res://resources/puzzles/packs/quantum_protocol.json",
}


func _load(pack_id: String) -> LevelCatalog.Pack:
	var catalog := LevelCatalog.new()
	var pack := catalog.load_pack(FILES[pack_id], "campaign", "")
	assert_eq(catalog.errors, PackedStringArray(), "%s has no invalid puzzles" % pack_id)
	return pack


func _count_types(puzzle: PuzzleData) -> Dictionary:
	var counts := {}
	for type in puzzle.types:
		counts[type] = int(counts.get(type, 0)) + 1
	return counts


func _movable_fixed(puzzle: PuzzleData) -> int:
	var count := 0
	for i in puzzle.types.size():
		var type := puzzle.types[i]
		if puzzle.fixed[i] != 0 and type != T.SOURCE and type != T.DESTINATION:
			count += 1
	return count


func test_all_packs_validate() -> void:
	assert_eq(_load("campaign").puzzles.size(), 100, "100 campaign puzzles")
	assert_eq(_load("daily").puzzles.size(), 90, "90 daily puzzles")
	assert_eq(_load("overclock").puzzles.size(), 60, "60 overclock puzzles")
	assert_eq(_load("logic_gates").puzzles.size(), 60, "60 logic gates puzzles")
	assert_eq(_load("circuit_breaker").puzzles.size(), 60, "60 circuit breaker puzzles")
	assert_eq(_load("quantum_protocol").puzzles.size(), 60, "60 quantum protocol puzzles")


func test_logic_gates_use_the_gate_tile() -> void:
	for puzzle in _load("logic_gates").puzzles:
		var counts := _count_types(puzzle)
		assert_eq(int(counts.get(T.GATE_AND, 0)), 1, "%s has exactly one gate" % puzzle.id)
		assert_eq(int(counts.get(T.SOURCE, 0)), 2, "%s has two sources feeding the gate" % puzzle.id)


func test_quantum_protocol_uses_the_gate_tile() -> void:
	for puzzle in _load("quantum_protocol").puzzles:
		var counts := _count_types(puzzle)
		assert_eq(int(counts.get(T.GATE_AND, 0)), 1, "%s has exactly one gate" % puzzle.id)
		assert_true(puzzle.has_move_limit(), "%s has a move limit" % puzzle.id)


func test_circuit_breaker_routes_to_multiple_targets() -> void:
	for puzzle in _load("circuit_breaker").puzzles:
		assert_true(int(_count_types(puzzle).get(T.DESTINATION, 0)) >= 2, "%s has multiple destinations" % puzzle.id)


func test_campaign_chapters() -> void:
	var pack := _load("campaign")
	assert_eq(pack.chapters.size(), 10, "ten chapters")
	for chapter in pack.chapters:
		assert_eq(int(chapter["count"]), 10, "ten levels per chapter")


func test_difficulty_curve() -> void:
	var puzzles := _load("campaign").puzzles
	for i in 10:
		var counts := _count_types(puzzles[i])
		assert_eq(int(counts.get(T.TEE, 0)) + int(counts.get(T.CROSS, 0)) + int(counts.get(T.BLOCKED, 0)), 0, "level %d basics only" % (i + 1))
		assert_eq(_movable_fixed(puzzles[i]), 0, "level %d no fixed tiles" % (i + 1))
		assert_eq(puzzles[i].move_limit, 0, "level %d no limit" % (i + 1))
	for i in range(20, 30):
		assert_true(int(_count_types(puzzles[i]).get(T.DESTINATION, 0)) >= 2, "level %d branches" % (i + 1))
	for i in range(30, 40):
		assert_true(_movable_fixed(puzzles[i]) > 0, "level %d has fixed tiles" % (i + 1))
	for i in range(34, 40):
		assert_true(puzzles[i].move_limit > 0, "level %d has a move limit" % (i + 1))
	assert_true(puzzles[0].par <= 2, "first level is trivial")
	assert_true(puzzles[59].par > puzzles[9].par * 2, "late levels are much longer")


func test_ids_unique_across_packs() -> void:
	var seen := {}
	for pack_id in FILES:
		for puzzle in _load(pack_id).puzzles:
			assert_false(seen.has(puzzle.id), "duplicate id %s" % puzzle.id)
			seen[puzzle.id] = true
