class_name MenuCard
extends FeedbackButton
## Wide menu card: leading icon, title and subtitle, an optional chip on the right
## (a quiet date chip or a bright action chip) and an optional chevron.

enum ChipStyle { QUIET, ACTION }

@export var icon_name: StringName = &"daily"
@export var icon_color: Color = Palette.TEXT
@export var title: String = "":
	set(value):
		title = value
		queue_redraw()
@export var subtitle: String = "":
	set(value):
		subtitle = value
		queue_redraw()
@export var chip_text: String = "":
	set(value):
		chip_text = value
		queue_redraw()
@export var chip_style: ChipStyle = ChipStyle.QUIET
@export var show_chevron: bool = true
@export var title_size: int = 38
@export var subtitle_size: int = 26


func _ready() -> void:
	super()
	focus_mode = Control.FOCUS_NONE
	if tooltip_text.is_empty():
		tooltip_text = title


func _draw() -> void:
	var pressed_now := get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED
	var lip := get_theme_stylebox(&"normal").get_margin(SIDE_BOTTOM) - get_theme_stylebox(&"normal").get_margin(SIDE_TOP)
	var drop := 6.0 if pressed_now and lip > 0.0 else 0.0
	var mid := size.y * 0.5 - maxf(0.0, lip) * 0.5 + drop
	var dim := disabled
	var text_color := get_theme_color(&"font_disabled_color") if dim else get_theme_color(&"font_color")

	var r := minf(size.y * 0.2, 30.0)
	var icon_x := 36.0 + r
	UiIcons.draw_icon(self, icon_name, Vector2(icon_x, mid), r, text_color if dim else icon_color)

	var right := size.x - 28.0
	if show_chevron:
		UiIcons.draw_icon(self, &"chevron", Vector2(right - 10.0, mid), 16.0, Color(text_color, 0.9))
		right -= 44.0
	var bold := get_theme_font(&"font")
	if not chip_text.is_empty():
		right = _draw_chip(bold, right, mid, dim) - 18.0

	var text_x := icon_x + r + 30.0
	var width := right - text_x
	var regular := get_theme_font(&"font", &"Label")
	if subtitle.is_empty():
		draw_string(bold, Vector2(text_x, mid + bold.get_ascent(title_size) * 0.36), title, HORIZONTAL_ALIGNMENT_LEFT, width, title_size, text_color)
	else:
		draw_string(bold, Vector2(text_x, mid - 4.0), title, HORIZONTAL_ALIGNMENT_LEFT, width, title_size, text_color)
		draw_string(regular, Vector2(text_x, mid + subtitle_size + 6.0), subtitle, HORIZONTAL_ALIGNMENT_LEFT, width, subtitle_size, Color(text_color, 0.8))


## Draws the chip ending at `right`; returns its left edge.
func _draw_chip(font: Font, right: float, mid: float, dim: bool) -> float:
	var font_size := 28
	var text_size := font.get_string_size(chip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var icon_space := 40.0 if chip_style == ChipStyle.ACTION else 0.0
	var chip := Rect2(Vector2(right - text_size.x - icon_space - 56.0, mid - 32.0), Vector2(text_size.x + icon_space + 56.0, 64.0))
	var text_color := Palette.TEXT
	if chip_style == ChipStyle.ACTION and not dim:
		UiIcons.rounded_rect(self, Rect2(chip.position + Vector2(0, 5), chip.size), 32.0, Color("1d4fd1"))
		UiIcons.rounded_rect(self, chip, 32.0, Color("2f6bff"))
		var badge := Rect2(chip.position + Vector2(22.0, 18.0), Vector2(32.0, 28.0))
		UiIcons.rounded_rect(self, badge, 7.0, Palette.TEXT)
		UiIcons.draw_icon(self, &"play", badge.get_center() + Vector2(1.5, 0), 8.0, Color("2f6bff"))
	else:
		UiIcons.rounded_rect(self, chip, 32.0, Color(Palette.BACKGROUND_DEEP, 0.35))
		text_color = Color(Palette.TEXT, 0.6) if dim else Palette.TEXT
	draw_string(font, Vector2(chip.position.x + 28.0 + icon_space, mid + font.get_ascent(font_size) * 0.36), chip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	return chip.position.x
