extends Control
## Boot scene: loads content, then routes to the main menu.

@onready var _status: Label = $Center/Status


func _ready() -> void:
	# Let the first frame render before doing any work so the screen is never blank.
	await get_tree().process_frame
	var error := GameManager.load_content()
	if not error.is_empty():
		_status.text = error
		return
	SceneRouter.goto(SceneRouter.MAIN_MENU)
