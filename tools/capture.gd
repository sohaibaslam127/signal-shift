extends Node
## Dev tool: opens a scene, optionally performs actions, and saves a screenshot.
## Run (needs a window, not --headless):
##   godot --path . res://tools/capture.tscn -- --scene=res://scenes/game/game.tscn --out=/tmp/shot.png [--solve] [--taps=1,2] [--wait=1.0] [--size=1290x2796]
## --size renders offscreen at that pixel size (larger than the desktop window allows) using the 720-wide design layout.


func _ready() -> void:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "true"
	if GameManager.campaign_pack() == null:
		GameManager.load_content()
	if args.has("daily"):
		GameManager.current_mode = GameManager.Mode.DAILY
		GameManager.current_daily_key = DailyPuzzleService.today_key()
		GameManager.current_puzzle = DailyPuzzleService.today_puzzle()
	if args.has("level"):
		GameManager.current_puzzle = GameManager.catalog.get_puzzle(args["level"])
	var scene: PackedScene = load(args.get("scene", "res://scenes/menus/main_menu.tscn"))
	var instance := scene.instantiate()
	var host: Node = get_tree().root
	var shot_view: SubViewport = null
	if args.has("size"):
		var size := str(args["size"]).split("x")
		shot_view = SubViewport.new()
		shot_view.size = Vector2i(int(size[0]), int(size[1]))
		shot_view.size_2d_override = Vector2i(720, roundi(720.0 * shot_view.size.y / shot_view.size.x))
		shot_view.size_2d_override_stretch = true
		shot_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_tree().root.add_child.call_deferred(shot_view)
		host = shot_view
	host.add_child.call_deferred(instance)
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
	var image := (shot_view if shot_view != null else get_viewport()).get_texture().get_image()
	image.save_png(args.get("out", "user://capture.png"))
	get_tree().quit()
