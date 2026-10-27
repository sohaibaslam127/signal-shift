class_name IconGlyph
extends Control
## Non-interactive icon for labels and HUD chips; draws a UiIcons glyph centred in its box.

@export var icon_name: StringName = &"star":
	set(value):
		icon_name = value
		queue_redraw()
@export var color: Color = Palette.CIRCUIT:
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	UiIcons.draw_icon(self, icon_name, size * 0.5, minf(size.x, size.y) * 0.5, color)
