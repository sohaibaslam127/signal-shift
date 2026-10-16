extends "res://tests/test_case.gd"
## Smoke tests: core scenes and autoloads load.


func test_main_scenes_load() -> void:
	for path in ["res://scenes/boot/boot.tscn", "res://scenes/menus/main_menu.tscn"]:
		var scene: PackedScene = load(path)
		assert_true(scene != null, "%s should load" % path)
		var node := scene.instantiate()
		assert_true(node != null, "%s should instantiate" % path)
		node.free()


func test_theme_loads() -> void:
	var theme: Theme = load("res://resources/themes/signal_theme.tres")
	assert_true(theme != null, "theme should load")
	assert_true(theme.has_stylebox("normal", "PrimaryButton"), "PrimaryButton variation exists")


func test_autoloads_present() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	for autoload_name in ["SignalBus", "SaveService", "AudioService", "GameManager", "SceneRouter"]:
		assert_true(root.has_node(autoload_name), "autoload %s should be running" % autoload_name)
