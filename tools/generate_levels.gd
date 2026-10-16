extends SceneTree
## Deterministic puzzle designer for Signal Shift content.
##
## Each level comes from a hand-tuned spec (grid size, route length, branches, decoys,
## blocked cells, fixed tiles, move-limit slack, target par range). The designer lays a
## random route with a seeded RNG, assigns tile types from the route shape, scrambles the
## rotations and then runs PuzzleValidator. Nothing is written unless every puzzle in the
## file validates, so shipped content always has a verified solution.
##
## Run: godot --headless --path . -s res://tools/generate_levels.gd
## Output is stable: the same specs always produce the same JSON.

const T := TileTypes.Type
const MAX_ATTEMPTS := 600

const CAMPAIGN_NAMES := [
	"First Light", "Bend", "Spark", "Relay", "Detour", "Junction", "Glow", "Pathfinder", "Low Voltage", "Ignition",
	"Long Haul", "Switchback", "Meander", "Corridor", "Zigzag", "Overpass", "Serpent", "Transit", "Backroad", "Mainline",
	"Fork", "Split Signal", "Twin Lights", "Decoy", "Crossroads", "Mirage", "Bifurcate", "Tangle", "False Lead", "Delta",
	"Rivets", "Bolted", "Dead Zone", "Firewall", "Bulkhead", "Tight Budget", "Countdown", "Clamp", "Lockstep", "Lockdown",
	"Surge", "Feedback", "Breaker", "Capacitor", "Amplifier", "Interference", "Short Circuit", "Resonance", "Static", "Overload",
	"Event Horizon", "Quantum", "Labyrinth", "Mainframe", "Supernova", "Paradox", "Nexus", "Zenith", "Apex", "Singularity",
]

const CAMPAIGN_CHAPTERS := [
	{"title": "Ignition", "levels": 10},
	{"title": "Long Lines", "levels": 10},
	{"title": "Crossroads", "levels": 10},
	{"title": "Lockdown", "levels": 10},
	{"title": "Overload", "levels": 10},
	{"title": "Singularity", "levels": 10},
]

var _failures := PackedStringArray()


func _initialize() -> void:
	var campaign := _build_pack("campaign", 11, _campaign_specs(), CAMPAIGN_NAMES, "c%03d")
	_write_pack("res://resources/puzzles/campaign/campaign.json", {
		"id": "campaign",
		"title": "Campaign",
		"description": "Sixty handcrafted circuits, free forever.",
		"chapters": CAMPAIGN_CHAPTERS,
	}, campaign)

	var daily := _build_pack("daily", 23, _daily_specs(), [], "d%03d")
	_write_pack("res://resources/puzzles/daily/daily.json", {
		"id": "daily",
		"title": "Daily Puzzles",
		"description": "Curated daily circuits, bundled for offline play.",
		"chapters": [],
	}, daily)

	var overclock := _build_pack("overclock", 37, _overclock_specs(), [], "o%02d")
	_write_pack("res://resources/puzzles/packs/overclock.json", {
		"id": "overclock",
		"title": "Overclock",
		"description": "Twenty dense, multi-branch circuits for experts.",
		"chapters": [{"title": "Overclock", "levels": 20}],
	}, overclock)

	if not _failures.is_empty():
		for failure in _failures:
			printerr(failure)
		quit(1)
		return
	quit(0)


# --- Level specs -----------------------------------------------------------------------------

## Fields: w, h, len (route cells incl. source/destination [min, max]), branches, decoys (0..1 of free
## cells), decoy_types, blocked, fixed (fraction of route tiles), limit (move-limit slack, -1 = none),
## par ([min, max]).
func _spec(w: int, h: int, len_range: Vector2i, par_range: Vector2i, extra: Dictionary = {}) -> Dictionary:
	var spec := {
		"w": w, "h": h, "len": len_range, "par": par_range,
		"branches": 0, "decoys": 0.0, "decoy_types": [T.STRAIGHT, T.CORNER],
		"blocked": 0, "fixed": 0.0, "limit": -1,
	}
	spec.merge(extra, true)
	return spec


func _campaign_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	# 1–10 Ignition: straight and corner basics.
	specs.append(_spec(3, 3, Vector2i(3, 3), Vector2i(1, 1)))
	specs.append(_spec(3, 3, Vector2i(3, 4), Vector2i(2, 3)))
	specs.append(_spec(3, 3, Vector2i(4, 5), Vector2i(3, 4)))
	specs.append(_spec(3, 4, Vector2i(5, 6), Vector2i(3, 5), {"decoys": 0.2}))
	specs.append(_spec(3, 4, Vector2i(5, 6), Vector2i(4, 6), {"decoys": 0.3}))
	specs.append(_spec(4, 4, Vector2i(6, 7), Vector2i(4, 6), {"decoys": 0.3}))
	specs.append(_spec(4, 4, Vector2i(6, 8), Vector2i(5, 7), {"decoys": 0.35}))
	specs.append(_spec(4, 5, Vector2i(7, 8), Vector2i(6, 8), {"decoys": 0.35}))
	specs.append(_spec(4, 5, Vector2i(7, 9), Vector2i(6, 9), {"decoys": 0.4}))
	specs.append(_spec(4, 5, Vector2i(8, 9), Vector2i(7, 10), {"decoys": 0.45}))
	# 11–20 Long Lines: longer routes, more turns.
	for i in 10:
		var w := 4 if i < 3 else 5
		var h := 5 if i < 3 else (6 if i < 7 else 7)
		var min_len := 9 + i
		specs.append(_spec(w, h, Vector2i(min_len, min_len + 2), Vector2i(8 + i, 14 + i), {"decoys": 0.45 + i * 0.02}))
	# 21–30 Crossroads: branches and misleading connections (three-way decoys).
	for i in 10:
		var h := 6 if i < 5 else 7
		var branches := 1 if i < 7 else 2
		specs.append(_spec(5, h, Vector2i(9 + i / 2, 12 + i / 2), Vector2i(10 + i, 18 + i), {
			"branches": branches, "decoys": 0.6 + i * 0.02,
			"decoy_types": [T.STRAIGHT, T.CORNER, T.TEE],
		}))
	# 31–40 Lockdown: fixed tiles (31+), blocked cells (33+), move limits (35+).
	for i in 10:
		var w := 5 if i < 5 else 6
		var h := 6 if i < 3 else 7
		var extra := {
			"fixed": 0.2 + i * 0.015,
			"decoys": 0.6, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE],
			"branches": 1 if i >= 7 else 0,
		}
		if i >= 2:
			extra["blocked"] = 2 + i / 3
		if i >= 4:
			extra["limit"] = 5 - (i - 4) / 2
		specs.append(_spec(w, h, Vector2i(10 + i / 2, 13 + i / 2), Vector2i(10 + i, 18 + i), extra))
	# 41–50 Overload: bigger layouts and multiple constraints.
	for i in 10:
		var h := 7 if i < 4 else 8
		var extra := {
			"branches": 1 + i % 2,
			"fixed": 0.25, "blocked": 3 + i / 3,
			"decoys": 0.7, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE, T.CROSS],
		}
		if i % 2 == 1 or i >= 7:
			extra["limit"] = 3
		specs.append(_spec(6, h, Vector2i(12 + i / 2, 15 + i / 2), Vector2i(14 + i, 24 + i), extra))
	# 51–60 Singularity: everything combined.
	for i in 10:
		var w := 6 if i < 5 else 7
		var h := 8 if i < 5 else 9
		var extra := {
			"branches": 2 if i < 8 else 3,
			"fixed": 0.3, "blocked": 4 + i / 2,
			"decoys": 0.8, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE, T.CROSS],
			"limit": 2 if i >= 2 else 4,
		}
		specs.append(_spec(w, h, Vector2i(13 + i / 2, 17 + i / 2), Vector2i(18 + i, 30 + i), extra))
	return specs


func _daily_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	# 90 mid-difficulty puzzles cycling through every mechanic.
	for i in 90:
		var variant := i % 6
		match variant:
			0:
				specs.append(_spec(5, 6, Vector2i(10, 13), Vector2i(9, 18), {"decoys": 0.5}))
			1:
				specs.append(_spec(5, 6, Vector2i(9, 12), Vector2i(10, 20), {"branches": 1, "decoys": 0.6, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE]}))
			2:
				specs.append(_spec(5, 7, Vector2i(10, 13), Vector2i(10, 20), {"fixed": 0.25, "blocked": 3, "decoys": 0.55}))
			3:
				specs.append(_spec(6, 7, Vector2i(11, 14), Vector2i(12, 22), {"branches": 1, "blocked": 2, "limit": 4, "decoys": 0.6, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE]}))
			4:
				specs.append(_spec(5, 7, Vector2i(12, 15), Vector2i(11, 21), {"decoys": 0.65, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE, T.CROSS]}))
			5:
				specs.append(_spec(6, 7, Vector2i(10, 13), Vector2i(12, 24), {"branches": 2, "fixed": 0.2, "blocked": 3, "decoys": 0.6, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE]}))
	return specs


func _overclock_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for i in 20:
		var w := 6 if i < 8 else 7
		var h := 8 if i < 8 else 9
		specs.append(_spec(w, h, Vector2i(14 + i / 4, 18 + i / 4), Vector2i(20 + i / 2, 34 + i), {
			"branches": 2 + i / 10,
			"fixed": 0.3, "blocked": 4 + i / 4,
			"decoys": 0.85, "decoy_types": [T.STRAIGHT, T.CORNER, T.TEE, T.CROSS],
			"limit": 3 if i % 3 != 0 else -1,
		}))
	return specs


# --- Generation ------------------------------------------------------------------------------

func _build_pack(pack_id: String, pack_seed: int, specs: Array[Dictionary], names: Array, id_format: String) -> Array[PuzzleData]:
	var puzzles: Array[PuzzleData] = []
	for i in specs.size():
		var puzzle_id := id_format % (i + 1)
		var started := Time.get_ticks_msec()
		var puzzle := _design(specs[i], pack_seed * 100003 + i * 7919, puzzle_id)
		if puzzle == null:
			print("  FAILED %s" % puzzle_id)
			_failures.append("%s: could not design %s within %d attempts" % [pack_id, puzzle_id, MAX_ATTEMPTS])
			continue
		puzzle.id = puzzle_id
		var elapsed := Time.get_ticks_msec() - started
		if elapsed > 500:
			print("  slow: %s took %d ms" % [puzzle_id, elapsed])
		puzzle.name = names[i] if i < names.size() else "%s %d" % [pack_id.capitalize(), i + 1]
		var errors := PuzzleValidator.validate(puzzle)
		if not errors.is_empty():
			_failures.append_array(errors)
			continue
		puzzles.append(puzzle)
	return puzzles


func _design(spec: Dictionary, base_seed: int, puzzle_id: String) -> PuzzleData:
	var rng := RandomNumberGenerator.new()
	for attempt in MAX_ATTEMPTS:
		rng.seed = base_seed + attempt * 104729
		var puzzle := _try_design(spec, rng)
		if puzzle != null:
			puzzle.id = puzzle_id
		if puzzle == null:
			if OS.has_environment("GEN_DEBUG") and attempt < 3:
				print("  attempt %d: design returned null" % attempt)
			continue
		if OS.has_environment("GEN_DEBUG") and attempt < 3:
			print("  attempt %d: par %d errors %s" % [attempt, puzzle.par, PuzzleValidator.validate(puzzle)])
		var par_range: Vector2i = spec["par"]
		if puzzle.par < par_range.x or puzzle.par > par_range.y:
			continue
		if PuzzleValidator.validate(puzzle).is_empty():
			if OS.is_stdout_verbose():
				print("  designed in %d attempts (par %d)" % [attempt + 1, puzzle.par])
			return puzzle
	return null


func _try_design(spec: Dictionary, rng: RandomNumberGenerator) -> PuzzleData:
	var w: int = spec["w"]
	var h: int = spec["h"]
	var length_range: Vector2i = spec["len"]
	var target_length := rng.randi_range(length_range.x, length_range.y)
	var board := BoardState.new(w, h)

	# 1. Main route from source to destination.
	var route := _random_route(board, target_length, rng)
	if route.is_empty():
		return null
	var used := {}
	var edges := {}  # cell index -> connection mask
	for cell in route:
		used[cell] = true
	for k in route.size() - 1:
		_link(board, edges, route[k], route[k + 1])
	var endpoints := {route[0]: T.SOURCE, route[route.size() - 1]: T.DESTINATION}

	# 2. Branches to extra destinations, each splitting off a two-way route tile.
	for b in int(spec["branches"]):
		if not _add_branch(board, route, used, edges, endpoints, rng):
			return null

	# 3. Route tiles from their connection masks.
	var puzzle := PuzzleData.new()
	puzzle.width = w
	puzzle.height = h
	var count := w * h
	puzzle.types.resize(count)
	puzzle.rotations.resize(count)
	puzzle.fixed.resize(count)
	puzzle.solution.resize(count)
	var route_cells: Array[int] = []
	for cell: int in edges:
		var mask: int = edges[cell]
		var type: int = endpoints.get(cell, _type_for_mask(mask))
		var rotation := TileTypes.rotation_for_mask(type, mask)
		if rotation < 0:
			return null
		puzzle.types[cell] = type
		puzzle.solution[cell] = rotation
		puzzle.rotations[cell] = rotation
		if endpoints.has(cell):
			puzzle.fixed[cell] = 1
		else:
			route_cells.append(cell)
	route_cells.sort()

	# 4. Blocked cells and decoys in the remaining space.
	var free: Array[int] = []
	for cell in count:
		if not edges.has(cell):
			free.append(cell)
	_shuffle(free, rng)
	var blocked: int = mini(int(spec["blocked"]), free.size())
	for k in blocked:
		puzzle.types[free[k]] = T.BLOCKED
	var decoy_types: Array = spec["decoy_types"]
	for k in range(blocked, free.size()):
		var cell := free[k]
		if rng.randf() < float(spec["decoys"]):
			var type: int = decoy_types[rng.randi_range(0, decoy_types.size() - 1)]
			var rotation := rng.randi_range(0, 3)
			puzzle.types[cell] = type
			puzzle.rotations[cell] = rotation
			puzzle.solution[cell] = rotation
			if float(spec["fixed"]) > 0.0 and rng.randf() < float(spec["fixed"]) * 0.5:
				puzzle.fixed[cell] = 1
		else:
			puzzle.types[cell] = T.EMPTY

	# 5. Fixed route tiles keep their solved orientation; the rest are scrambled.
	var fixed_count := roundi(route_cells.size() * float(spec["fixed"]))
	var shuffled := route_cells.duplicate()
	_shuffle(shuffled, rng)
	for k in fixed_count:
		puzzle.fixed[shuffled[k]] = 1
	for cell in route_cells:
		if puzzle.fixed[cell] != 0:
			continue
		var type := puzzle.types[cell]
		if type == T.CROSS:
			continue
		# Most route tiles start wrong; a few start correct so the board is not all-wrong.
		if rng.randf() < 0.85:
			var period := TileTypes.distinct_rotations(type)
			puzzle.rotations[cell] = (puzzle.solution[cell] + rng.randi_range(1, period - 1)) % 4
	puzzle.par = puzzle.compute_par()
	var slack: int = spec["limit"]
	if slack >= 0:
		puzzle.move_limit = puzzle.par + slack
	return puzzle


## Self-avoiding random route of exactly `length` cells, found by randomized depth-first search.
func _random_route(board: BoardState, length: int, rng: RandomNumberGenerator) -> Array[int]:
	var start := Vector2i(rng.randi_range(0, board.width - 1), rng.randi_range(0, board.height - 1))
	var route: Array[int] = [board.index_of(start)]
	var visited := {route[0]: true}
	var budget := [3000]
	if _extend(board, route, visited, length, rng, budget):
		return route
	return []


func _extend(board: BoardState, route: Array[int], visited: Dictionary, length: int, rng: RandomNumberGenerator, budget: Array) -> bool:
	if route.size() == length:
		return true
	budget[0] -= 1
	if budget[0] <= 0:
		return false
	var cell := board.cell_of(route[route.size() - 1])
	var directions := [0, 1, 2, 3]
	_shuffle(directions, rng)
	for direction: int in directions:
		var next := cell + TileTypes.DIRECTION_OFFSETS[direction]
		if not board.in_bounds(next):
			continue
		var index := board.index_of(next)
		if visited.has(index):
			continue
		visited[index] = true
		route.append(index)
		if _extend(board, route, visited, length, rng, budget):
			return true
		route.pop_back()
		visited.erase(index)
	return false


func _add_branch(board: BoardState, route: Array[int], used: Dictionary, edges: Dictionary, endpoints: Dictionary, rng: RandomNumberGenerator) -> bool:
	var candidates: Array[int] = []
	for cell: int in edges:
		if not endpoints.has(cell) and _bit_count(edges[cell]) == 2:
			candidates.append(cell)
	candidates.sort()
	_shuffle(candidates, rng)
	for root in candidates:
		var length := rng.randi_range(2, 4)
		var branch: Array[int] = [root]
		var visited := used.duplicate()
		var budget := [400]
		if not _extend(board, branch, visited, length + 1, rng, budget):
			continue
		for k in branch.size() - 1:
			_link(board, edges, branch[k], branch[k + 1])
		for cell in branch:
			used[cell] = true
		endpoints[branch[branch.size() - 1]] = T.DESTINATION
		return true
	return false


func _link(board: BoardState, edges: Dictionary, a: int, b: int) -> void:
	var delta := board.cell_of(b) - board.cell_of(a)
	var direction := TileTypes.DIRECTION_OFFSETS.find(delta)
	edges[a] = int(edges.get(a, 0)) | TileTypes.DIRECTION_BITS[direction]
	edges[b] = int(edges.get(b, 0)) | TileTypes.DIRECTION_BITS[TileTypes.opposite_direction(direction)]


func _type_for_mask(mask: int) -> int:
	match _bit_count(mask):
		2:
			return T.STRAIGHT if mask == (TileTypes.UP | TileTypes.DOWN) or mask == (TileTypes.LEFT | TileTypes.RIGHT) else T.CORNER
		3:
			return T.TEE
		4:
			return T.CROSS
	return T.EMPTY


func _bit_count(mask: int) -> int:
	var bits := 0
	for direction in 4:
		if mask & TileTypes.DIRECTION_BITS[direction] != 0:
			bits += 1
	return bits


func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = values[i]
		values[i] = values[j]
		values[j] = tmp


# --- Output ----------------------------------------------------------------------------------

func _write_pack(path: String, header: Dictionary, puzzles: Array[PuzzleData]) -> void:
	if not _failures.is_empty():
		return
	var lines := PackedStringArray()
	lines.append("{")
	lines.append('\t"id": %s,' % JSON.stringify(header["id"]))
	lines.append('\t"title": %s,' % JSON.stringify(header["title"]))
	lines.append('\t"description": %s,' % JSON.stringify(header["description"]))
	lines.append('\t"chapters": %s,' % JSON.stringify(header["chapters"]))
	lines.append('\t"puzzles": [')
	for i in puzzles.size():
		var entry := JSON.stringify(puzzles[i].to_dict(), "", false)
		lines.append("\t\t%s%s" % [entry, "," if i < puzzles.size() - 1 else ""])
	lines.append("\t]")
	lines.append("}")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("cannot write %s" % path)
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
	var total_par := 0
	for puzzle in puzzles:
		total_par += puzzle.par
		print("%s  %-14s %dx%d  par %2d  limit %s" % [puzzle.id, puzzle.name, puzzle.width, puzzle.height, puzzle.par,
			str(puzzle.move_limit) if puzzle.move_limit > 0 else "-"])
	print("Wrote %d verified puzzles to %s" % [puzzles.size(), path])
