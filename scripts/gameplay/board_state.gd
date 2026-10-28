class_name BoardState
extends RefCounted
## Pure grid model: tile types, rotations and fixed flags. The single source of truth for
## connectivity. Views read from it; they never feed positions back into it.

var width: int = 0
var height: int = 0
var types: PackedByteArray = PackedByteArray()
var rotations: PackedByteArray = PackedByteArray()
var fixed: PackedByteArray = PackedByteArray()
## Rule set that decides connectivity and winning ("classic", "logic", "repair", "quantum").
var rules: String = "classic"


func _init(board_width: int = 0, board_height: int = 0) -> void:
	resize(board_width, board_height)


func resize(board_width: int, board_height: int) -> void:
	width = maxi(0, board_width)
	height = maxi(0, board_height)
	var count := width * height
	types.resize(count)
	types.fill(TileTypes.Type.EMPTY)
	rotations.resize(count)
	rotations.fill(0)
	fixed.resize(count)
	fixed.fill(0)


func cell_count() -> int:
	return width * height


func index_of(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func cell_of(index: int) -> Vector2i:
	return Vector2i(index % width, index / width)


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func set_tile(index: int, type: int, rotation: int = 0, is_fixed: bool = false) -> void:
	types[index] = type
	rotations[index] = posmod(rotation, 4)
	fixed[index] = 1 if is_fixed else 0


func get_type(index: int) -> int:
	return types[index]


func get_rotation(index: int) -> int:
	return rotations[index]


func is_fixed(index: int) -> bool:
	return fixed[index] != 0


func connections_at(index: int) -> int:
	return TileTypes.connections(types[index], rotations[index])


## True when a tap on this cell changes the board.
func can_rotate(index: int) -> bool:
	if index < 0 or index >= cell_count():
		return false
	return not is_fixed(index) and TileTypes.has_orientation(types[index])


## True when a tap changes the board: rotatable tiles, switches, and wires still to repair.
func can_tap(index: int) -> bool:
	if can_rotate(index):
		return true
	if index < 0 or index >= cell_count() or is_fixed(index):
		return false
	match types[index]:
		TileTypes.Type.SWITCH:
			return true
		TileTypes.Type.BROKEN:
			return rotations[index] < 2
	return false


## Applies a player tap: rotate, toggle a switch, or repair a broken wire. Returns false if nothing changed.
func tap(index: int) -> bool:
	if not can_tap(index):
		return false
	match types[index]:
		TileTypes.Type.SWITCH:
			rotations[index] = 1 - rotations[index]
		TileTypes.Type.BROKEN:
			rotations[index] += 2
		_:
			rotations[index] = (rotations[index] + 1) % 4
	return true


## Rotates a tile 90° clockwise. Returns false (and changes nothing) if the tile cannot rotate.
func rotate_cw(index: int) -> bool:
	if not can_rotate(index):
		return false
	rotations[index] = (rotations[index] + 1) % 4
	return true


func snapshot() -> PackedByteArray:
	return rotations.duplicate()


func restore(saved_rotations: PackedByteArray) -> void:
	if saved_rotations.size() == rotations.size():
		rotations = saved_rotations.duplicate()


func indices_of_type(type: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	for i in types.size():
		if types[i] == type:
			result.append(i)
	return result


func duplicate_board() -> BoardState:
	var copy := BoardState.new()
	copy.width = width
	copy.height = height
	copy.types = types.duplicate()
	copy.rotations = rotations.duplicate()
	copy.fixed = fixed.duplicate()
	copy.rules = rules
	return copy
