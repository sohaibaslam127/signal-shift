class_name AdsBackend
extends RefCounted
## Interface between AdsService and a platform ad SDK plugin.
## A concrete backend wraps one plugin (e.g. an AdMob plugin) and translates its callbacks
## into these signals. The base class is the "no ads" backend: always unavailable.

## A rewarded ad finished loading and can be shown.
signal rewarded_loaded
signal rewarded_load_failed(message: String)
## The SDK confirmed the player earned the reward. This is the only signal that grants rewards.
signal reward_earned
## The ad was dismissed (with or without a reward event).
signal rewarded_closed
signal rewarded_show_failed(message: String)


## True if an ad SDK is installed and initialised on this platform.
func is_available() -> bool:
	return false


func is_rewarded_ready() -> bool:
	return false


func load_rewarded(_placement: String) -> void:
	rewarded_load_failed.emit.call_deferred("No ad SDK installed")


func show_rewarded(_placement: String) -> void:
	rewarded_show_failed.emit.call_deferred("No ad SDK installed")


func backend_name() -> String:
	return "none"
