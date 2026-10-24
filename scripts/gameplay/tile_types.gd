class_name TileTypes
extends RefCounted
## Tile type definitions, direction bitmasks and rotation math.
## Connections are a 4-bit mask: UP=1, RIGHT=2, DOWN=4, LEFT=8. Rotation r (0..3) means
## r quarter turns clockwise from the base orientation.

enum Type { EMPTY, STRAIGHT, CORNER, TEE, CROSS, SOURCE, DESTINATION, BLOCKED, GATE_AND }

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
	Type.GATE_AND: UP | RIGHT | DOWN,
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
	Type.GATE_AND: "G",
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
	"G": Type.GATE_AND,
}

## Base-orientation output side for each gate type; the other connected sides are inputs.
const GATE_OUTPUT_BASE_BIT := {
	Type.GATE_AND: RIGHT,
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


static func is_gate(type: int) -> bool:
	return GATE_OUTPUT_BASE_BIT.has(type)


## The single connection bit a gate currently forwards signal through; 0 for non-gate types.
static func gate_output_bit(type: int, rotation: int) -> int:
	if not GATE_OUTPUT_BASE_BIT.has(type):
		return 0
	return rotate_mask(int(GATE_OUTPUT_BASE_BIT[type]), rotation)


## A gate's remaining connected sides, which must all be powered before it forwards signal.
static func gate_input_bits(type: int, rotation: int) -> int:
	var output_bit := gate_output_bit(type, rotation)
	if output_bit == 0:
		return 0
	return connections(type, rotation) & (ALL ^ output_bit)
