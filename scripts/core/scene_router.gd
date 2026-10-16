extends CanvasLayer
## Scene changes with a short fade. Input is blocked for the whole transition.
## Also routes the Android back button to the current scene's `handle_back()` if it has one.

const FADE_TIME := 0.18

const BOOT := "res://scenes/boot/boot.tscn"
const MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/menus/level_select.tscn"
const SETTINGS := "res://scenes/menus/settings.tscn"
const PACK_STORE := "res://scenes/menus/puzzle_pack_store.tscn"
const GAME := "res://scenes/game/game.tscn"

var is_transitioning: bool = false
var _overlay: ColorRect
## Scene to return to from Settings (settings can be opened from the menu or the pause panel).
var settings_return_scene: String = MAIN_MENU


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.color = Palette.BACKGROUND_DEEP
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate.a = 0.0
	add_child(_overlay)


func goto(scene_path: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade := 0.01 if SaveService.progress.reduced_motion else FADE_TIME
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, fade)
	await tween.finished
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not change scene to %s (error %d)." % [scene_path, error])
	# Wait one frame so the new scene is in the tree before fading in.
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, fade)
	await tween.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


func open_settings(return_scene: String) -> void:
	settings_return_scene = return_scene
	goto(SETTINGS)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_transitioning:
			return
		var scene := get_tree().current_scene
		if scene != null and scene.has_method("handle_back"):
			scene.call("handle_back")
		else:
			goto(MAIN_MENU)
