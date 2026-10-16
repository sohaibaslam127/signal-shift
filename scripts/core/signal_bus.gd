extends Node
## Global event bus for cross-scene notifications that have no natural owner.

signal settings_changed
signal progress_changed
signal hint_tokens_changed(tokens: int)
signal entitlements_changed
