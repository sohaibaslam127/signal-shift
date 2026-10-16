class_name TitleMark
extends Control
## Game wordmark: "SIGNAL" in white and "SHIFT" in a cyan-to-mint letter gradient, both with a
## thick dark outline and drop shadow, over a glowing swoosh. Scales its font to fit the width.

@export var first_word: String = "SIGNAL"
@export var second_word: String = "SHIFT"
@export var max_font_size: int = 104

const OUTLINE := 18
const GAP := 0.28  # Word gap as a fraction of the font size.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var font := get_theme_font(&"font", &"TitleLabel")
	var probe := 100
	var probe_width := _word_width(font, first_word, probe) + _word_width(font, second_word, probe) + probe * GAP
	var font_size := mini(max_font_size, int(probe * (size.x - OUTLINE * 2.0) / probe_width))
	var first_w := _word_width(font, first_word, font_size)
	var total := first_w + font_size * GAP + _word_width(font, second_word, font_size)
	var baseline := size.y * 0.5 + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.42
	var x := (size.x - total) * 0.5

	_draw_swoosh(Vector2(size.x * 0.5, baseline + font_size * 0.32), total * 0.5)

	var colors := PackedColorArray()
	for i in first_word.length():
		colors.append(Palette.TEXT)
	for i in second_word.length():
		colors.append(Palette.CIRCUIT.lerp(Palette.SUCCESS, float(i) / maxf(1.0, second_word.length() - 1.0)))
	var letters := first_word + second_word
	var positions := PackedFloat32Array()
	var cursor := x
	for i in letters.length():
		if i == first_word.length():
			cursor += font_size * GAP
		positions.append(cursor)
		cursor += font.get_char_size(letters.unicode_at(i), font_size).x + font.get_spacing(TextServer.SPACING_GLYPH)

	# Shadow, outline, fill: each pass over all letters so outlines never overlap neighbours' fills.
	for i in letters.length():
		draw_char_outline(font, Vector2(positions[i], baseline + 8.0), letters[i], font_size, OUTLINE, Color(0, 0, 0, 0.45))
	for i in letters.length():
		draw_char_outline(font, Vector2(positions[i], baseline), letters[i], font_size, OUTLINE, Palette.PANEL_SHADOW)
	for i in letters.length():
		draw_char(font, Vector2(positions[i], baseline), letters[i], font_size, colors[i])
	# Soft top sheen on each letter.
	for i in letters.length():
		draw_char(font, Vector2(positions[i], baseline - 2.0), letters[i], font_size, Color(1, 1, 1, 0.12))


func _word_width(font: Font, word: String, font_size: int) -> float:
	var width := 0.0
	for i in word.length():
		width += font.get_char_size(word.unicode_at(i), font_size).x + font.get_spacing(TextServer.SPACING_GLYPH)
	return width


func _draw_swoosh(center: Vector2, half_width: float) -> void:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var steps := 24
	for i in steps + 1:
		var t := float(i) / steps
		var x := lerpf(-half_width * 0.55, half_width * 0.55, t)
		points.append(center + Vector2(x, -sin(t * PI) * 10.0 + 6.0))
		colors.append(Color(Palette.CIRCUIT.lerp(Palette.SUCCESS, t), sin(t * PI)))
	draw_polyline_colors(points, colors, 7.0, true)
