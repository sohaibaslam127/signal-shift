extends Node
## Dev tool: opens a scene, optionally performs actions, and saves a screenshot.
## Run (needs a window, not --headless):
##   godot --path . res://tools/capture.tscn -- --scene=res://scenes/game/game.tscn --out=/tmp/shot.png [--solve] [--taps=1,2] [--wait=1.0]


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "true"
	if GameManager.campaign_pack() == null:
		GameManager.load_content()
	if args.has("level"):
		GameManager.current_puzzle = GameManager.catalog.get_puzzle(args["level"])
	var scene: PackedScene = load(args.get("scene", "res://scenes/menus/main_menu.tscn"))
	var instance := scene.instantiate()
	get_tree().root.add_child.call_deferred(instance)
	await get_tree().create_timer(0.4).timeout
	var game := instance.get("controller") as PuzzleController
	if game != null:
		if args.has("taps"):
			for tap in str(args["taps"]).split(",", false):
				game.tap(int(tap))
				await get_tree().create_timer(0.05).timeout
		if args.has("solve"):
			while game.is_playing() and game.apply_hint() >= 0:
				await get_tree().create_timer(0.05).timeout
	await get_tree().create_timer(float(args.get("wait", "1.0"))).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png(args.get("out", "user://capture.png"))
	get_tree().quit()
