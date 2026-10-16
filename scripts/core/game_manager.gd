extends Node
## Owns app-wide game state: which puzzle is being played and saving on pause/quit.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Loads bundled content. Returns an empty string on success or a player-facing error.
func load_content() -> String:
	return ""


func has_progress() -> bool:
	return not SaveService.progress.level_records.is_empty()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT:
			SaveService.save_progress()
