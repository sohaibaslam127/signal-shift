extends SceneTree
## Headless test runner. Discovers res://tests/test_*.gd and runs every `test_*` method.
## Usage: godot --headless --path . -s res://tests/run_tests.gd
## Exit code is 0 when all tests pass, 1 otherwise.

const TEST_DIR := "res://tests"


func _initialize() -> void:
	# Defer so autoloads are fully in the tree before tests run.
	_run.call_deferred()


func _run() -> void:
	# Keep tests away from the real player save.
	var save_service: Node = root.get_node("SaveService")
	save_service.set("save_path", "user://test_runner_save.json")
	save_service.call("delete_save")
	var files := DirAccess.get_files_at(TEST_DIR)
	var total := 0
	var failed := 0
	for file_name in files:
		if not file_name.begins_with("test_") or not file_name.ends_with(".gd") or file_name == "test_case.gd":
			continue
		var script: GDScript = load(TEST_DIR.path_join(file_name))
		if script == null:
			printerr("Could not load %s" % file_name)
			failed += 1
			continue
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			var instance: Object = script.new()
			instance.set("_current_test", "%s::%s" % [file_name.get_basename(), method_name])
			instance.call("before_each")
			# Awaiting works for both plain and coroutine (async) tests.
			await instance.call(method_name)
			instance.call("after_each")
			total += 1
			var failures: PackedStringArray = instance.get("failures")
			if failures.is_empty():
				print("  ok   %s" % method_name)
			else:
				failed += 1
				for failure in failures:
					printerr("  FAIL %s" % failure)
	save_service.call("delete_save")
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)
