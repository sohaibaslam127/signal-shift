extends SceneTree
## Generates res://resources/themes/signal_theme.tres from the Palette tokens.
## Run: godot --headless --path . -s res://tools/build_theme.gd

const OUTPUT := "res://resources/themes/signal_theme.tres"

## Raised "lip" under buttons: the face sits on a darker edge and drops onto it when pressed.
const LIP := 8

var _regular: FontVariation
var _medium: FontVariation
var _bold: FontVariation
var _black: FontVariation
var _display: FontVariation


func _initialize() -> void:
	var theme := Theme.new()
	_build_fonts()
	theme.default_font = _regular
	theme.default_font_size = 30

	_label_styles(theme)
	_button_styles(theme)
	_panel_styles(theme)
	_scroll_styles(theme)
	_separator_styles(theme)
	_progress_styles(theme)

	var error := ResourceSaver.save(theme, OUTPUT)
	if error != OK:
		printerr("Failed to save theme: %d" % error)
		quit(1)
		return
	print("Theme written to %s" % OUTPUT)
	quit(0)


func _build_fonts() -> void:
	var base: FontFile = load(Palette.FONT_REGULAR)
	_regular = _weight(base, 400)
	_medium = _weight(base, 500)
	_bold = _weight(base, 650)
	_black = _weight(base, 800)
	_display = _weight(base, 800)
	_display.spacing_glyph = 4


func _weight(base: FontFile, weight: int) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = base
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return font


func _box(bg: Color, border: Color = Color.TRANSPARENT, border_width: int = 0, radius: int = Palette.RADIUS) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	box.anti_aliasing = true
	return box


## Button face with a darker bottom lip and soft drop shadow. `pressed` sinks the face onto the lip.
func _raised(face: Color, lip: Color, pressed: bool = false, radius: int = 28, margin_x: int = 28) -> StyleBoxFlat:
	var box := _box(face, lip, 0, radius)
	box.border_width_bottom = 2 if pressed else LIP
	box.content_margin_left = margin_x
	box.content_margin_right = margin_x
	box.content_margin_top = 14 + (LIP - 2 if pressed else 0)
	box.content_margin_bottom = 14
	if pressed:
		box.expand_margin_top = -float(LIP - 2)
	box.shadow_color = Color(0, 0, 0, 0.0 if pressed else 0.35)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 6)
	return box


func _set_button_variation(theme: Theme, type: StringName, face: Color, lip: Color, text: Color, radius: int = 28, margin_x: int = 28) -> void:
	theme.set_stylebox("normal", type, _raised(face, lip, false, radius, margin_x))
	theme.set_stylebox("hover", type, _raised(face.lightened(0.06), lip, false, radius, margin_x))
	theme.set_stylebox("pressed", type, _raised(face.darkened(0.08), lip, true, radius, margin_x))
	theme.set_stylebox("hover_pressed", type, _raised(face.darkened(0.08), lip, true, radius, margin_x))
	var disabled := _raised(Palette.PANEL, Palette.PANEL_SHADOW, false, radius, margin_x)
	disabled.shadow_color = Color.TRANSPARENT
	theme.set_stylebox("disabled", type, disabled)
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, type, text)
	theme.set_color("font_disabled_color", type, Palette.TEXT_DISABLED)
	theme.set_font("font", type, _bold)


## Flat, lip-less button box (cards and pills); pressing darkens it slightly.
func _set_flat_variation(theme: Theme, type: StringName, face: Color, border: Color, radius: int) -> void:
	var normal := _box(face, border, 2, radius)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = face.darkened(0.25)
	pressed.border_color = Color(Palette.CIRCUIT, 0.6)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(face, face.a * 0.6)
	theme.set_stylebox("normal", type, normal)
	theme.set_stylebox("hover", type, normal)
	theme.set_stylebox("pressed", type, pressed)
	theme.set_stylebox("hover_pressed", type, pressed)
	theme.set_stylebox("disabled", type, disabled)
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, type, Palette.TEXT)
	theme.set_color("font_disabled_color", type, Palette.TEXT_DIM)
	theme.set_font("font", type, _bold)


func _label_styles(theme: Theme) -> void:
	theme.set_color("font_color", "Label", Palette.TEXT)

	# Hero title: heavy weight, wide tracking and a cyan glow drawn as a zero-offset shadow outline.
	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font("font", "TitleLabel", _display)
	theme.set_font_size("font_size", "TitleLabel", 82)
	theme.set_color("font_color", "TitleLabel", Palette.TEXT)
	theme.set_color("font_shadow_color", "TitleLabel", Color(Palette.CIRCUIT, 0.22))
	theme.set_constant("shadow_offset_x", "TitleLabel", 0)
	theme.set_constant("shadow_offset_y", "TitleLabel", 0)
	theme.set_constant("shadow_outline_size", "TitleLabel", 16)

	theme.set_type_variation("HeadingLabel", "Label")
	theme.set_font("font", "HeadingLabel", _bold)
	theme.set_font_size("font_size", "HeadingLabel", 42)
	theme.set_color("font_color", "HeadingLabel", Palette.TEXT)

	theme.set_type_variation("DimLabel", "Label")
	theme.set_font_size("font_size", "DimLabel", 26)
	theme.set_color("font_color", "DimLabel", Palette.TEXT_DIM)

	# Small uppercase captions (section titles, stat names).
	theme.set_type_variation("CaptionLabel", "Label")
	var caption := _medium.duplicate() as FontVariation
	caption.spacing_glyph = 3
	theme.set_font("font", "CaptionLabel", caption)
	theme.set_font_size("font_size", "CaptionLabel", 20)
	theme.set_color("font_color", "CaptionLabel", Palette.TEXT_DIM)

	theme.set_type_variation("StatLabel", "Label")
	theme.set_font("font", "StatLabel", _bold)
	theme.set_font_size("font_size", "StatLabel", 34)
	theme.set_color("font_color", "StatLabel", Palette.CIRCUIT)

	theme.set_type_variation("StatValue", "Label")
	theme.set_font("font", "StatValue", _black)
	theme.set_font_size("font_size", "StatValue", 44)
	theme.set_color("font_color", "StatValue", Palette.TEXT)


func _button_styles(theme: Theme) -> void:
	_set_button_variation(theme, &"Button", Palette.PANEL_RAISED, Palette.PANEL_SHADOW, Palette.TEXT)
	theme.set_font_size("font_size", "Button", 32)

	theme.set_type_variation("PrimaryButton", "Button")
	_set_button_variation(theme, &"PrimaryButton", Palette.MINT, Palette.MINT_DARK, Palette.BACKGROUND_DEEP)
	theme.set_font("font", "PrimaryButton", _black)
	theme.set_font_size("font_size", "PrimaryButton", 38)

	# Oversized pill for the main call to action.
	theme.set_type_variation("HeroButton", "Button")
	_set_button_variation(theme, &"HeroButton", Palette.MINT, Palette.MINT_DARK, Palette.BACKGROUND_DEEP, 72, 40)
	for state in ["normal", "hover"]:
		var hero := theme.get_stylebox(state, "HeroButton") as StyleBoxFlat
		hero.shadow_color = Color(Palette.MINT, 0.28)
		hero.shadow_size = 30
		hero.shadow_offset = Vector2(0, 8)
	theme.set_font("font", "HeroButton", _black)
	theme.set_font_size("font_size", "HeroButton", 54)

	theme.set_type_variation("AccentButton", "Button")
	_set_button_variation(theme, &"AccentButton", Palette.ACCENT, Palette.ACCENT_DARK, Palette.TEXT)

	for state in ["normal", "hover"]:
		var accent := theme.get_stylebox(state, "AccentButton") as StyleBoxFlat
		accent.shadow_color = Color(Palette.ACCENT, 0.25)
		accent.shadow_size = 24

	# Translucent row card with a thin border and no lip.
	theme.set_type_variation("CardButton", "Button")
	_set_flat_variation(theme, &"CardButton", Color(Palette.PANEL_RAISED, 0.55), Color(Palette.PANEL_BORDER, 0.7), 32)

	# Top-bar status pills.
	theme.set_type_variation("PillButton", "Button")
	_set_flat_variation(theme, &"PillButton", Color(Palette.BACKGROUND_DEEP, 0.45), Color(Palette.PANEL_BORDER, 0.9), 50)
	theme.set_font_size("font_size", "PillButton", 30)

	# Round translucent header buttons (back, pause).
	theme.set_type_variation("RoundButton", "Button")
	_set_flat_variation(theme, &"RoundButton", Color(Palette.BACKGROUND_DEEP, 0.45), Color(Palette.PANEL_BORDER, 0.9), 52)

	# Bottom navigation bar items: no box of their own.
	theme.set_type_variation("NavButton", "Button")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "NavButton", StyleBoxEmpty.new())
	theme.set_color("font_color", "NavButton", Palette.TEXT_DIM)
	theme.set_color("font_disabled_color", "NavButton", Palette.TEXT_DISABLED)
	theme.set_font("font", "NavButton", _bold)
	theme.set_font_size("font_size", "NavButton", 26)

	theme.set_type_variation("GoldButton", "Button")
	_set_button_variation(theme, &"GoldButton", Palette.WARNING, Palette.WARNING_DARK, Palette.BACKGROUND_DEEP)

	theme.set_type_variation("HudButton", "Button")
	_set_button_variation(theme, &"HudButton", Palette.PANEL_RAISED, Palette.PANEL_SHADOW, Palette.TEXT, 26, 12)
	theme.set_font_size("font_size", "HudButton", 22)

	# Level grid cells: face colour is drawn per state by LevelButton, so the boxes stay neutral.
	theme.set_type_variation("LevelButton", "Button")
	_set_button_variation(theme, &"LevelButton", Palette.PANEL_RAISED, Palette.PANEL_SHADOW, Palette.TEXT, 22, 4)
	var locked := _raised(Color(Palette.PANEL, 0.7), Color(Palette.PANEL_SHADOW, 0.7), false, 22, 4)
	locked.shadow_color = Color.TRANSPARENT
	theme.set_stylebox("disabled", "LevelButton", locked)
	theme.set_font_size("font_size", "LevelButton", 30)


func _panel_styles(theme: Theme) -> void:
	var panel := _box(Color(Palette.PANEL, 0.92), Palette.PANEL_BORDER, 2, 32)
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 28
	panel.content_margin_bottom = 28
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_type_variation("CardPanel", "PanelContainer")
	var card := _box(Color(Palette.PANEL_RAISED, 0.72), Color(Palette.PANEL_BORDER, 0.8), 2, 28)
	card.content_margin_left = 28
	card.content_margin_right = 28
	card.content_margin_top = 22
	card.content_margin_bottom = 22
	card.shadow_color = Color(0, 0, 0, 0.25)
	card.shadow_size = 14
	card.shadow_offset = Vector2(0, 6)
	theme.set_stylebox("panel", "CardPanel", card)

	theme.set_type_variation("AccentCard", "PanelContainer")
	var accent := card.duplicate() as StyleBoxFlat
	accent.bg_color = Color(Palette.ACCENT_DARK.darkened(0.45), 0.85)
	accent.border_color = Color(Palette.ACCENT, 0.75)
	accent.set_border_width_all(2)
	accent.shadow_color = Color(Palette.ACCENT, 0.18)
	accent.shadow_size = 22
	accent.shadow_offset = Vector2.ZERO
	theme.set_stylebox("panel", "AccentCard", accent)

	# Compact pill used for HUD stats.
	theme.set_type_variation("ChipPanel", "PanelContainer")
	var chip := _box(Color(Palette.PANEL_RAISED, 0.6), Color(Palette.PANEL_BORDER, 0.6), 2, 40)
	chip.content_margin_left = 30
	chip.content_margin_right = 30
	chip.content_margin_top = 10
	chip.content_margin_bottom = 10
	theme.set_stylebox("panel", "ChipPanel", chip)

	theme.set_type_variation("NavPanel", "PanelContainer")
	var nav := _box(Color(Palette.PANEL, 0.88), Color(Palette.PANEL_BORDER, 0.8), 2, 44)
	nav.content_margin_left = 12
	nav.content_margin_right = 12
	nav.content_margin_top = 8
	nav.content_margin_bottom = 8
	nav.shadow_color = Color(0, 0, 0, 0.35)
	nav.shadow_size = 24
	nav.shadow_offset = Vector2(0, 8)
	theme.set_stylebox("panel", "NavPanel", nav)

	theme.set_type_variation("DialogPanel", "PanelContainer")
	var dialog := _box(Palette.PANEL, Color(Palette.CIRCUIT, 0.35), 2, 40)
	dialog.content_margin_left = 40
	dialog.content_margin_right = 40
	dialog.content_margin_top = 40
	dialog.content_margin_bottom = 36
	dialog.shadow_color = Color(Palette.CIRCUIT, 0.12)
	dialog.shadow_size = 48
	theme.set_stylebox("panel", "DialogPanel", dialog)


func _separator_styles(theme: Theme) -> void:
	var line := StyleBoxLine.new()
	line.vertical = true
	line.color = Color(Palette.PANEL_BORDER, 0.7)
	line.thickness = 2
	line.grow_begin = -22.0
	line.grow_end = -22.0
	theme.set_stylebox("separator", "VSeparator", line)


func _scroll_styles(theme: Theme) -> void:
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(Palette.CIRCUIT, 0.35)
	grabber.set_corner_radius_all(4)
	var track := StyleBoxFlat.new()
	track.bg_color = Color.TRANSPARENT
	track.content_margin_left = 3
	track.content_margin_right = 3
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	theme.set_stylebox("scroll", "VScrollBar", track)


func _progress_styles(theme: Theme) -> void:
	var background := _box(Color(Palette.PANEL_SHADOW, 0.9), Color.TRANSPARENT, 0, 8)
	background.content_margin_top = 0
	background.content_margin_bottom = 0
	var fill := _box(Palette.WARNING, Color.TRANSPARENT, 0, 8)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	theme.set_stylebox("background", "ProgressBar", background)
	theme.set_stylebox("fill", "ProgressBar", fill)
