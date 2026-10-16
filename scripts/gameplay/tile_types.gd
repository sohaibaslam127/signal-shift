class_name TileTypes
extends RefCounted
## Tile type definitions, direction bitmasks and rotation math.
## Connections are a 4-bit mask: UP=1, RIGHT=2, DOWN=4, LEFT=8. Rotation r (0..3) means
## r quarter turns clockwise from the base orientation.

enum Type { EMPTY, STRAIGHT, CORNER, TEE, CROSS, SOURCE, DESTINATION, BLOCKED }

const UP := 1
const RIGHT := 2
const DOWN := 4
const LEFT := 8
const ALL := 15

## Direction index order: up, right, down, left.
const DIRECTION_BITS: Array[int] = [UP, RIGHT, DOWN, LEFT]
const DIRECTION_OFFSETS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

## Connection mask of each type at rotation 0.
const BASE_MASKS := {
	Type.EMPTY: 0,
	Type.STRAIGHT: UP | DOWN,
	Type.CORNER: UP | RIGHT,
	Type.TEE: UP | RIGHT | DOWN,
	Type.CROSS: ALL,
	Type.SOURCE: UP,
	Type.DESTINATION: UP,
	Type.BLOCKED: 0,
}

const TOKEN_FOR_TYPE := {
	Type.EMPTY: ".",
	Type.STRAIGHT: "I",
	Type.CORNER: "L",
	Type.TEE: "T",
	Type.CROSS: "X",
	Type.SOURCE: "S",
	Type.DESTINATION: "D",
	Type.BLOCKED: "#",
}

const TYPE_FOR_TOKEN := {
	".": Type.EMPTY,
	"I": Type.STRAIGHT,
	"L": Type.CORNER,
	"T": Type.TEE,
	"X": Type.CROSS,
	"S": Type.SOURCE,
	"D": Type.DESTINATION,
	"#": Type.BLOCKED,
}


## Rotates a connection mask clockwise by `steps` quarter turns.
static func rotate_mask(mask: int, steps: int) -> int:
	var s := posmod(steps, 4)
	if s == 0:
		return mask & ALL
	return ((mask << s) | (mask >> (4 - s))) & ALL


static func connections(type: int, rotation: int) -> int:
	return rotate_mask(int(BASE_MASKS.get(type, 0)), rotation)


static func opposite_direction(direction_index: int) -> int:
	return (direction_index + 2) % 4


## Types that have connection data a player could rotate (fixed flag aside).
static func has_orientation(type: int) -> bool:
	return type != Type.EMPTY and type != Type.BLOCKED and type != Type.CROSS


static func is_valid_type(type: int) -> bool:
	return BASE_MASKS.has(type)


## Number of rotations that give a distinct connection mask (1, 2 or 4).
static func distinct_rotations(type: int) -> int:
	match type:
		Type.EMPTY, Type.BLOCKED, Type.CROSS:
			return 1
		Type.STRAIGHT:
			return 2
		_:
			return 4


## Minimal number of clockwise taps to turn `from_rotation` into a rotation with the same mask as `to_rotation`.
static func taps_between(type: int, from_rotation: int, to_rotation: int) -> int:
	var period := distinct_rotations(type)
	return posmod(to_rotation - from_rotation, period)


## Finds a rotation (0..3) for `type` whose mask equals `mask`, or -1 if none exists.
static func rotation_for_mask(type: int, mask: int) -> int:
	for r in 4:
		if connections(type, r) == mask:
			return r
	return -1
