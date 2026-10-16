extends Node
## Loads and saves ProgressionData as JSON in user://.
## Writes go to a temp file first, then replace the save; the previous save is kept as a backup.
## A missing or corrupted save never blocks play: the backup is tried, then defaults are used.

const DEFAULT_PATH := "user://signal_shift_save.json"

var save_path: String = DEFAULT_PATH
var progress: ProgressionData = ProgressionData.new()
## Human-readable note about the last load (for diagnostics and tests).
var last_load_status: String = ""


func _ready() -> void:
	load_progress()


func backup_path() -> String:
	return save_path + ".bak"


func load_progress() -> ProgressionData:
	var primary: Variant = _read_file(save_path)
	if primary != null:
		progress = ProgressionData.from_dict(primary)
		last_load_status = "ok"
		return progress
	var backup: Variant = _read_file(backup_path())
	if backup != null:
		progress = ProgressionData.from_dict(backup)
		last_load_status = "restored_from_backup"
		push_warning("Save file unreadable; restored progress from backup.")
		return progress
	progress = ProgressionData.new()
	last_load_status = "missing" if not FileAccess.file_exists(save_path) else "corrupted_reset"
	if last_load_status == "corrupted_reset":
		push_warning("Save file corrupted and no valid backup; starting fresh.")
	return progress


func save_progress() -> bool:
	var text := JSON.stringify(progress.to_dict(), "\t")
	var temp_path := save_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open %s for writing (error %d)." % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(text)
	file.close()

	# Only rotate the current save into the backup slot if it is itself valid.
	if FileAccess.file_exists(save_path) and _read_file(save_path) != null:
		DirAccess.copy_absolute(save_path, backup_path())
	if DirAccess.rename_absolute(temp_path, save_path) != OK:
		DirAccess.remove_absolute(save_path)
		if DirAccess.rename_absolute(temp_path, save_path) != OK:
			push_error("Could not replace save file at %s." % save_path)
			return false
	return true


## Deletes save and backup. Used by tests and a future "reset progress" option.
func delete_save() -> void:
	for path in [save_path, backup_path(), save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	progress = ProgressionData.new()


## Returns the parsed dictionary, or null if the file is missing or not a valid save object.
func _read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return null
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	if typeof(json.data) != TYPE_DICTIONARY:
		return null
	return json.data
