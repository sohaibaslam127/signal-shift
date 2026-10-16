class_name IconButton
extends FeedbackButton
## Button with a vector icon drawn in code (no image assets). Layouts:
## - no text, no caption: icon centred (round header buttons);
## - caption: icon above a small caption (toolbar and navigation buttons);
## - text: icon at the left edge, theme text centred (menu buttons).
## Optional extras: a count badge, a trailing chevron, a top gloss highlight, and a
## "selected" underline for navigation bars.

const PRESS_DROP := 6.0  # Matches the theme's button lip (8) minus the pressed lip (2).
const LIP_HALF := 4.0

@export var icon_name: StringName = &"back":
	set(value):
		icon_name = value
		queue_redraw()
@export var caption: String = "":
	set(value):
		caption = value
		queue_redraw()
@export var icon_color_override: Color = Color.TRANSPARENT
@export var show_chevron: bool = false
@export var gloss: bool = false
@export var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
## Navigation-bar buttons have no lip, so their content is not offset for it.
@export var flat_face: bool = false

var badge: int = -1:
	set(value):
		badge = value
		queue_redraw()


func _ready() -> void:
	super()
	if tooltip_text.is_empty():
		tooltip_text = caption if not caption.is_empty() else text


func _draw() -> void:
	var pressed_now := get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED
	var drop := 0.0 if flat_face else (PRESS_DROP if pressed_now else 0.0)
	var face_center := Vector2(size.x * 0.5, size.y * 0.5 + (0.0 if flat_face else -LIP_HALF + drop * 0.5))
	var color := _content_color()
	var font := get_theme_font(&"font")
	if gloss and not disabled:
		var top := drop + 7.0
		UiIcons.rounded_rect(self, Rect2(Vector2(size.y * 0.3, top), Vector2(size.x - size.y * 0.6, size.y * 0.1)), size.y * 0.05, Color(1, 1, 1, 0.22))
	if not text.is_empty():
		var r := minf(size.y * 0.17, 26.0)
		UiIcons.draw_icon(self, icon_name, Vector2(size.y * 0.55 + r * 0.4, face_center.y), r, color)
	elif not caption.is_empty():
		var r := size.y * 0.17
		UiIcons.draw_icon(self, icon_name, face_center - Vector2(0, size.y * 0.12), r, color)
		var font_size := get_theme_font_size(&"font_size")
		var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(face_center.x - text_size.x * 0.5, face_center.y + size.y * 0.27), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, 0.92))
	else:
		UiIcons.draw_icon(self, icon_name, face_center, minf(size.x, size.y) * 0.2, color)
	if show_chevron:
		UiIcons.draw_icon(self, &"chevron", Vector2(size.x - size.y * 0.5, face_center.y), minf(size.y * 0.13, 20.0), Color(color, 0.85))
	if selected:
		var bar := Vector2(size.x * 0.42, 6.0)
		UiIcons.rounded_rect(self, Rect2(Vector2((size.x - bar.x) * 0.5, size.y - bar.y - 4.0), bar), 3.0, Palette.CIRCUIT)
	if badge >= 0:
		_draw_badge(font)


func _content_color() -> Color:
	if disabled:
		return get_theme_color(&"font_disabled_color")
	if selected:
		return Palette.CIRCUIT
	if icon_color_override.a > 0.0:
		return icon_color_override
	return get_theme_color(&"font_color")


func _draw_badge(font: Font) -> void:
	var label := str(badge) if badge < 100 else "99+"
	var font_size := 22
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var r := maxf(18.0, text_size.x * 0.5 + 9.0)
	var center := Vector2(size.x - r * 0.9, r * 0.75)
	var fill := Palette.WARNING if badge > 0 else Palette.TEXT_DISABLED
	draw_circle(center, r + 3.0, Palette.BACKGROUND_DEEP)
	draw_circle(center, r, fill)
	var ascent := font.get_ascent(font_size) - font.get_descent(font_size)
	draw_string(font, Vector2(center.x - text_size.x * 0.5, center.y + ascent * 0.5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.BACKGROUND_DEEP)
