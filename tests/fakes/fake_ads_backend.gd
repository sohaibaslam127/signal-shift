extends AdsBackend
## Test double. `mode`: "reward" (reward then close), "close" (closed early), "load_fail", "show_fail".

var mode := "reward"
var ready := false
var shows := 0


func is_available() -> bool:
	return true


func is_rewarded_ready() -> bool:
	return ready


func load_rewarded(_placement: String) -> void:
	if mode == "load_fail":
		rewarded_load_failed.emit.call_deferred("no fill")
	else:
		ready = true
		rewarded_loaded.emit.call_deferred()


func show_rewarded(_placement: String) -> void:
	shows += 1
	ready = false
	match mode:
		"reward":
			reward_earned.emit.call_deferred()
			rewarded_closed.emit.call_deferred()
		"close":
			rewarded_closed.emit.call_deferred()
		"show_fail":
			rewarded_show_failed.emit.call_deferred("display error")
