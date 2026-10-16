extends RefCounted
## Minimal assertion base class for the headless test runner (tests/run_tests.gd).
## Test files extend this script and define methods named `test_*`.

var failures: PackedStringArray = PackedStringArray()
var _current_test: String = ""


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func _fail(message: String) -> void:
	failures.append("%s: %s" % [_current_test, message])


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		_fail(message)


func assert_false(condition: bool, message: String = "expected false") -> void:
	if condition:
		_fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("%s expected <%s> got <%s>" % [message, str(expected), str(actual)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		_fail("%s did not expect <%s>" % [message, str(unexpected)])
