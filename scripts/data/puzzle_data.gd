class_name PuzzleData
extends RefCounted
## One puzzle definition, parsed from JSON.
##
## JSON shape:
##   {
##     "id": "c001", "name": "First Light",
##     "rows": ["S1* I0 D3*"],     # tokens: type letter + rotation digit + optional "*" (fixed)
##     "solution": ["113"],        # one rotation digit per cell, row-major
##     "par": 1,                   # minimal taps to reach the stored solution
##     "move_limit": 0,            # 0 = unlimited
##     "rules": "classic",         # optional: classic | logic | repair | quantum
##     "tip": ""                   # optional one-line instruction shown above the toolbar
##   }
## Tile letters: "." empty, "#" blocked, I straight, L corner, T three-way, X four-way,
## S source, D destination, G/O/Y/N AND/OR/XOR/NOT gate, A diode, W switch, B broken wire,
## Z fault terminal, P portal, V phase inverter, Q phase destination. Stateful tiles keep their
## state in the digit (switch 0/1, broken wire 0-1 broken / 2-3 repaired, portal pair id). Blocked and empty cells take no rotation digit.

var id: String = ""
var name: String = ""
var width: int = 0
var height: int = 0
var types: PackedByteArray = PackedByteArray()
var rotations: PackedByteArray = PackedByteArray()
var fixed: PackedByteArray = PackedByteArray()
var solution: PackedByteArray = PackedByteArray()
var par: int = 0
var move_limit: int = 0
var rules: String = "classic"
var tip: String = ""
## Problems found while parsing. PuzzleValidator reports these alongside rule checks.
var parse_errors: PackedStringArray = PackedStringArray()

## Set by the catalog: which pack and position this puzzle belongs to.
var pack_id: String = ""
var pack_index: int = -1


static func from_dict(data: Variant) -> PuzzleData:
	var puzzle := PuzzleData.new()
	if typeof(data) != TYPE_DICTIONARY:
		puzzle.parse_errors.append("puzzle is not an object")
		return puzzle
	var dict: Dictionary = data
	puzzle.id = str(dict.get("id", ""))
	puzzle.name = str(dict.get("name", puzzle.id))
	puzzle.par = int(dict.get("par", 0)) if typeof(dict.get("par")) in [TYPE_INT, TYPE_FLOAT] else 0
	puzzle.move_limit = int(dict.get("move_limit", 0)) if typeof(dict.get("move_limit", 0)) in [TYPE_INT, TYPE_FLOAT] else 0

	puzzle.rules = str(dict.get("rules", "classic"))
	puzzle.tip = str(dict.get("tip", ""))

	var rows: Variant = dict.get("rows", [])
	if typeof(rows) != TYPE_ARRAY or (rows as Array).is_empty():
		puzzle.parse_errors.append("rows missing")
		return puzzle
	var row_tokens: Array[PackedStringArray] = []
	for row: Variant in rows:
		row_tokens.append(str(row).split(" ", false))
	puzzle.height = row_tokens.size()
	puzzle.width = row_tokens[0].size()
	for y in puzzle.height:
		if row_tokens[y].size() != puzzle.width:
			puzzle.parse_errors.append("row %d has %d cells, expected %d" % [y, row_tokens[y].size(), puzzle.width])
			return puzzle

	var count := puzzle.width * puzzle.height
	puzzle.types.resize(count)
	puzzle.rotations.resize(count)
	puzzle.fixed.resize(count)
	for y in puzzle.height:
		for x in puzzle.width:
			var i := y * puzzle.width + x
			var token := row_tokens[y][x]
			var letter := token.substr(0, 1)
			if not TileTypes.TYPE_FOR_TOKEN.has(letter):
				puzzle.parse_errors.append("unknown tile '%s' at %d,%d" % [token, x, y])
				continue
			var type: int = TileTypes.TYPE_FOR_TOKEN[letter]
			var rest := token.substr(1)
			var is_fixed := rest.ends_with("*")
			if is_fixed:
				rest = rest.left(-1)
			var rotation := 0
			if not rest.is_empty():
				if not rest.is_valid_int() or int(rest) < 0 or int(rest) > 3:
					puzzle.parse_errors.append("bad rotation '%s' at %d,%d" % [token, x, y])
					continue
				rotation = int(rest)
			puzzle.types[i] = type
			puzzle.rotations[i] = rotation
			puzzle.fixed[i] = 1 if is_fixed else 0

	var solution_rows: Variant = dict.get("solution", [])
	var digits := ""
	if typeof(solution_rows) == TYPE_ARRAY:
		for row: Variant in solution_rows:
			digits += str(row).replace(" ", "")
	if digits.length() != count:
		puzzle.parse_errors.append("solution has %d digits, expected %d" % [digits.length(), count])
		return puzzle
	puzzle.solution.resize(count)
	for i in count:
		var digit := digits[i]
		if not digit.is_valid_int() or int(digit) > 3:
			puzzle.parse_errors.append("bad solution digit '%s' at %d" % [digit, i])
			return puzzle
		puzzle.solution[i] = int(digit)
	return puzzle


func to_dict() -> Dictionary:
	var rows: Array[String] = []
	var solution_rows: Array[String] = []
	for y in height:
		var tokens := PackedStringArray()
		var digits := ""
		for x in width:
			var i := y * width + x
			var type := types[i]
			var token: String = TileTypes.TOKEN_FOR_TYPE[type]
			if type != TileTypes.Type.EMPTY and type != TileTypes.Type.BLOCKED:
				token += str(rotations[i])
			if fixed[i] != 0:
				token += "*"
			tokens.append(token)
			digits += str(solution[i])
		rows.append(" ".join(tokens))
		solution_rows.append(digits)
	var result := {"id": id, "name": name, "rows": rows, "solution": solution_rows, "par": par}
	if move_limit > 0:
		result["move_limit"] = move_limit
	if rules != "classic":
		result["rules"] = rules
	if not tip.is_empty():
		result["tip"] = tip
	return result


func create_board() -> BoardState:
	var board := BoardState.new(width, height)
	board.types = types.duplicate()
	board.rotations = rotations.duplicate()
	board.fixed = fixed.duplicate()
	board.rules = rules
	return board


func create_solution_board() -> BoardState:
	var board := create_board()
	board.rotations = solution.duplicate()
	return board


## Taps needed to turn the initial board into the stored solution.
func compute_par() -> int:
	var total := 0
	for i in types.size():
		total += TileTypes.taps_between(types[i], rotations[i], solution[i])
	return total


func has_move_limit() -> bool:
	return move_limit > 0


## 3 stars at or under par, 2 stars within a small margin, otherwise 1.
func stars_for(moves: int) -> int:
	if moves <= par:
		return 3
	if moves <= par + maxi(2, ceili(par * 0.5)):
		return 2
	return 1