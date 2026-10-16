extends Node
## Optional rewarded ads. Ads are only ever shown when the player asks for one
## (never during solving, never as interstitials). Rewards are granted only when the
## backend reports `reward_earned`; closing early, load errors and missing SDKs grant nothing.

const LOAD_TIMEOUT := 8.0
const UNAVAILABLE_MESSAGE := "Videos aren't available right now. You can keep playing — solve the Daily Puzzle for a free hint."

var backend: AdsBackend = AdsBackend.new()
var _busy := false


func _ready() -> void:
	set_backend(_detect_backend())


func set_backend(new_backend: AdsBackend) -> void:
	backend = new_backend if new_backend != null else AdsBackend.new()


func is_available() -> bool:
	return backend.is_available()


func is_busy() -> bool:
	return _busy


## Shows a rewarded ad for `placement`. Await the result:
##   { "granted": bool, "message": String }
func request_reward(placement: String) -> Dictionary:
	if _busy:
		return {"granted": false, "message": "A video is already playing."}
	if not backend.is_available():
		return {"granted": false, "message": UNAVAILABLE_MESSAGE}
	_busy = true
	var outcome := await _run(placement)
	_busy = false
	AudioServer.set_bus_mute(0, false)
	return outcome


func _run(placement: String) -> Dictionary:
	if not backend.is_rewarded_ready():
		var waiter := _Waiter.new()
		backend.rewarded_loaded.connect(waiter.finish.bind("loaded"), CONNECT_ONE_SHOT)
		backend.rewarded_load_failed.connect(func(_m: String) -> void: waiter.finish("failed"), CONNECT_ONE_SHOT)
		get_tree().create_timer(LOAD_TIMEOUT, true).timeout.connect(waiter.finish.bind("timeout"))
		backend.load_rewarded(placement)
		var loaded: String = await waiter.wait()
		_disconnect_all(backend.rewarded_loaded)
		_disconnect_all(backend.rewarded_load_failed)
		if loaded != "loaded":
			return {"granted": false, "message": UNAVAILABLE_MESSAGE}

	var state := _Waiter.new()
	var rewarded := [false]
	backend.reward_earned.connect(func() -> void: rewarded[0] = true)
	backend.rewarded_closed.connect(state.finish.bind("closed"), CONNECT_ONE_SHOT)
	backend.rewarded_show_failed.connect(func(_m: String) -> void: state.finish("failed"), CONNECT_ONE_SHOT)
	AudioServer.set_bus_mute(0, true)
	backend.show_rewarded(placement)
	var result: String = await state.wait()
	_disconnect_all(backend.reward_earned)
	_disconnect_all(backend.rewarded_closed)
	_disconnect_all(backend.rewarded_show_failed)
	if rewarded[0]:
		return {"granted": true, "message": ""}
	if result == "failed":
		return {"granted": false, "message": UNAVAILABLE_MESSAGE}
	return {"granted": false, "message": "The video was closed before the end, so no reward this time."}


func _disconnect_all(sig: Signal) -> void:
	for connection in sig.get_connections():
		sig.disconnect(connection["callable"])


## Picks a platform backend when an ad plugin is installed. See docs/PLUGIN_INTEGRATION.md.
func _detect_backend() -> AdsBackend:
	return AdsBackend.new()


## Resolves once with the first value passed to finish().
class _Waiter:
	extends RefCounted
	signal done(value: String)
	var _finished := false
	var _value := ""

	func finish(value: String) -> void:
		if _finished:
			return
		_finished = true
		_value = value
		done.emit(value)

	## Safe even if finish() already ran synchronously.
	func wait() -> String:
		if not _finished:
			await done
		return _value
