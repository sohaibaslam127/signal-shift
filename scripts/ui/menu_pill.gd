class_name MenuPill
extends FeedbackButton
## Rounded status pill for the menu top bar: icon, title, optional progress bar and badge.

@export var icon_name: StringName = &"star"
@export var icon_color: Color = Palette.WARNING
@export var title: String = "":
	set(value):
		title = value
		queue_redraw()

## 0..1 to show a progress bar under the title; negative hides it.
var progress: float = -1.0:
	set(value):
		progress = value
		queue_redraw()
var badge: int = -1:
	set(value):
		badge = value
		queue_redraw()


func _ready() -> void:
	super()
	focus_mode = Control.FOCUS_NONE
	if tooltip_text.is_empty():
		tooltip_text = title


func _draw() -> void:
	var pressed_now := get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED
	var offset := Vector2(0, 2.0 if pressed_now else 0.0)
	var r := size.y * 0.26
	var icon_center := Vector2(size.y * 0.5, size.y * 0.5) + offset
	UiIcons.draw_icon(self, icon_name, icon_center, r, icon_color)
	var font := get_theme_font(&"font")
	var font_size := get_theme_font_size(&"font_size")
	var text_x := icon_center.x + r + 18.0
	var ascent := font.get_ascent(font_size)
	var text_y := size.y * 0.5 + ascent * 0.36 - (10.0 if progress >= 0.0 else 0.0)
	draw_string(font, Vector2(text_x, text_y) + offset, title, HORIZONTAL_ALIGNMENT_LEFT, size.x - text_x - 20.0, font_size, Palette.TEXT)
	if progress >= 0.0:
		var bar := Rect2(Vector2(text_x, text_y + 14.0) + offset, Vector2(size.x - text_x - 30.0, 9.0))
		UiIcons.rounded_rect(self, bar, 4.5, Palette.PANEL_SHADOW)
		if progress > 0.0:
			UiIcons.rounded_rect(self, Rect2(bar.position, Vector2(maxf(9.0, bar.size.x * clampf(progress, 0.0, 1.0)), bar.size.y)), 4.5, Palette.CIRCUIT)
	if badge >= 0:
		var center := Vector2(size.x - 14.0, 8.0)
		var label := str(badge)
		var badge_size := 22
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, badge_size)
		draw_circle(center, 20.0, Palette.BACKGROUND_DEEP)
		draw_circle(center, 17.0, Palette.DANGER)
		draw_string(font, center + Vector2(-text_size.x * 0.5, font.get_ascent(badge_size) * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, badge_size, Palette.TEXT)
