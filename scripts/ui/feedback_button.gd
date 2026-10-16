class_name FeedbackButton
extends Button
## Button with click sound and a light haptic tick. Used by the reusable button components.


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	AudioService.play(&"button")
	AudioService.haptic(10)
