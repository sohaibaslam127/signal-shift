class_name LevelCatalog
extends RefCounted
## Loads every puzzle pack listed in the manifest and keeps only puzzles that pass validation.
##
## Manifest (res://resources/puzzles/catalog.json):
##   { "packs": [ { "id": "campaign", "file": "res://resources/puzzles/campaign/campaign.json",
##                  "kind": "campaign" | "daily" | "premium", "product_id": "" } ] }
## Pack file:
##   { "id", "title", "description", "chapters": [ {"title", "levels"} ], "puzzles": [ ... ] }

const MANIFEST_PATH := "res://resources/puzzles/catalog.json"


class Pack:
	extends RefCounted
	var id: String = ""
	var kind: String = "campaign"
	var title: String = ""
	var description: String = ""
	var product_id: String = ""
	var accent: Color = Palette.CIRCUIT
	var puzzles: Array[PuzzleData] = []
	## Each: { "title": String, "start": int, "count": int }
	var chapters: Array[Dictionary] = []

	func level_ids() -> PackedStringArray:
		var ids := PackedStringArray()
		for puzzle in puzzles:
			ids.append(puzzle.id)
		return ids

	func chapter_of(index: int) -> int:
		for c in chapters.size():
			var chapter: Dictionary = chapters[c]
			if index >= int(chapter["start"]) and index < int(chapter["start"]) + int(chapter["count"]):
				return c
		return -1


var packs: Array[Pack] = []
var errors: PackedStringArray = PackedStringArray()
var _by_id: Dictionary = {}
var _puzzles_by_id: Dictionary = {}


func load_manifest(path: String = MANIFEST_PATH) -> bool:
	packs.clear()
	errors.clear()
	_by_id.clear()
	_puzzles_by_id.clear()
	var manifest: Variant = _read_json(path)
	if typeof(manifest) != TYPE_DICTIONARY or typeof(manifest.get("packs")) != TYPE_ARRAY:
		errors.append("catalog manifest missing or invalid: %s" % path)
		return false
	for entry: Variant in manifest["packs"]:
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append("manifest entry is not an object")
			continue
		var pack := load_pack(str(entry.get("file", "")), str(entry.get("kind", "campaign")), str(entry.get("product_id", "")))
		if pack != null:
			if entry.has("accent"):
				pack.accent = Color(str(entry["accent"]))
			add_pack(pack)
	return errors.is_empty()


func load_pack(path: String, kind: String, product_id: String) -> Pack:
	var data: Variant = _read_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("pack file missing or invalid: %s" % path)
		return null
	var pack := Pack.new()
	pack.id = str(data.get("id", path.get_file().get_basename()))
	pack.kind = kind
	pack.product_id = product_id
	pack.title = str(data.get("title", pack.id))
	pack.description = str(data.get("description", ""))
	var raw_puzzles: Variant = data.get("puzzles", [])
	if typeof(raw_puzzles) != TYPE_ARRAY:
		errors.append("%s: puzzles must be an array" % pack.id)
		return pack
	for raw: Variant in raw_puzzles:
		var puzzle := PuzzleData.from_dict(raw)
		var puzzle_errors := PuzzleValidator.validate(puzzle)
		if _puzzles_by_id.has(puzzle.id):
			puzzle_errors.append("%s: duplicate puzzle id" % puzzle.id)
		if not puzzle_errors.is_empty():
			# Invalid puzzles never become available to players.
			errors.append_array(puzzle_errors)
			continue
		puzzle.pack_id = pack.id
		puzzle.pack_index = pack.puzzles.size()
		pack.puzzles.append(puzzle)
		_puzzles_by_id[puzzle.id] = puzzle

	var start := 0
	var raw_chapters: Variant = data.get("chapters", [])
	if typeof(raw_chapters) == TYPE_ARRAY:
		for chapter: Variant in raw_chapters:
			if typeof(chapter) != TYPE_DICTIONARY:
				continue
			var count := mini(int(chapter.get("levels", 0)), pack.puzzles.size() - start)
			if count <= 0:
				break
			pack.chapters.append({"title": str(chapter.get("title", "")), "start": start, "count": count})
			start += count
	if start < pack.puzzles.size():
		pack.chapters.append({"title": pack.title if pack.chapters.is_empty() else "More", "start": start, "count": pack.puzzles.size() - start})
	return pack


func add_pack(pack: Pack) -> void:
	packs.append(pack)
	_by_id[pack.id] = pack
	for puzzle in pack.puzzles:
		_puzzles_by_id[puzzle.id] = puzzle


func get_pack(pack_id: String) -> Pack:
	return _by_id.get(pack_id)


func get_puzzle(puzzle_id: String) -> PuzzleData:
	return _puzzles_by_id.get(puzzle_id)


func packs_of_kind(kind: String) -> Array[Pack]:
	var result: Array[Pack] = []
	for pack in packs:
		if pack.kind == kind:
			result.append(pack)
	return result


static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("JSON error in %s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
