extends SceneTree
## Generates res://resources/themes/signal_theme.tres from the Palette tokens.
## Run: godot --headless --path . -s res://tools/build_theme.gd

const OUTPUT := "res://resources/themes/signal_theme.tres"


func _initialize() -> void:
	var theme := Theme.new()
	theme.default_font_size = 30

	_label_styles(theme)
	_button_styles(theme)
	_panel_styles(theme)
	_scroll_styles(theme)

	var error := ResourceSaver.save(theme, OUTPUT)
	if error != OK:
		printerr("Failed to save theme: %d" % error)
		quit(1)
		return
	print("Theme written to %s" % OUTPUT)
	quit(0)


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


func _label_styles(theme: Theme) -> void:
	theme.set_color("font_color", "Label", Palette.TEXT)

	theme.set_type_variation("TitleLabel", "Label")
	theme.set_font_size("font_size", "TitleLabel", 76)
	theme.set_color("font_color", "TitleLabel", Palette.CIRCUIT)
	theme.set_color("font_outline_color", "TitleLabel", Color(Palette.SIGNAL, 0.35))
	theme.set_constant("outline_size", "TitleLabel", 10)

	theme.set_type_variation("HeadingLabel", "Label")
	theme.set_font_size("font_size", "HeadingLabel", 42)
	theme.set_color("font_color", "HeadingLabel", Palette.TEXT)

	theme.set_type_variation("DimLabel", "Label")
	theme.set_font_size("font_size", "DimLabel", 26)
	theme.set_color("font_color", "DimLabel", Palette.TEXT_DIM)

	theme.set_type_variation("StatLabel", "Label")
	theme.set_font_size("font_size", "StatLabel", 34)
	theme.set_color("font_color", "StatLabel", Palette.CIRCUIT)


func _button_styles(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", _box(Palette.PANEL_RAISED, Palette.PANEL_BORDER, 2))
	theme.set_stylebox("hover", "Button", _box(Palette.PANEL_RAISED.lightened(0.06), Palette.CIRCUIT_IDLE, 2))
	theme.set_stylebox("pressed", "Button", _box(Palette.PANEL.darkened(0.1), Palette.CIRCUIT, 2))
	theme.set_stylebox("hover_pressed", "Button", _box(Palette.PANEL.darkened(0.1), Palette.CIRCUIT, 2))
	theme.set_stylebox("disabled", "Button", _box(Palette.PANEL, Palette.PANEL, 2))
	theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, Palette.SIGNAL_GLOW, 3))
	theme.set_color("font_color", "Button", Palette.TEXT)
	theme.set_color("font_hover_color", "Button", Palette.TEXT)
	theme.set_color("font_pressed_color", "Button", Palette.CIRCUIT)
	theme.set_color("font_hover_pressed_color", "Button", Palette.CIRCUIT)
	theme.set_color("font_focus_color", "Button", Palette.TEXT)
	theme.set_color("font_disabled_color", "Button", Palette.TEXT_DISABLED)
	theme.set_font_size("font_size", "Button", 32)

	# Primary call to action: cyan fill, dark text.
	theme.set_type_variation("PrimaryButton", "Button")
	theme.set_stylebox("normal", "PrimaryButton", _box(Palette.CIRCUIT, Palette.CIRCUIT, 2))
	theme.set_stylebox("hover", "PrimaryButton", _box(Palette.CIRCUIT.lightened(0.12), Palette.SIGNAL_GLOW, 2))
	theme.set_stylebox("pressed", "PrimaryButton", _box(Palette.CIRCUIT.darkened(0.2), Palette.CIRCUIT, 2))
	theme.set_stylebox("hover_pressed", "PrimaryButton", _box(Palette.CIRCUIT.darkened(0.2), Palette.CIRCUIT, 2))
	theme.set_color("font_color", "PrimaryButton", Palette.BACKGROUND_DEEP)
	theme.set_color("font_hover_color", "PrimaryButton", Palette.BACKGROUND_DEEP)
	theme.set_color("font_pressed_color", "PrimaryButton", Palette.BACKGROUND_DEEP)
	theme.set_color("font_hover_pressed_color", "PrimaryButton", Palette.BACKGROUND_DEEP)
	theme.set_color("font_focus_color", "PrimaryButton", Palette.BACKGROUND_DEEP)
	theme.set_font_size("font_size", "PrimaryButton", 36)

	# Accent (violet) button for the daily challenge and premium content.
	theme.set_type_variation("AccentButton", "Button")
	theme.set_stylebox("normal", "AccentButton", _box(Palette.PANEL_RAISED, Palette.ACCENT, 3))
	theme.set_stylebox("hover", "AccentButton", _box(Palette.PANEL_RAISED.lightened(0.06), Palette.ACCENT.lightened(0.2), 3))
	theme.set_stylebox("pressed", "AccentButton", _box(Palette.PANEL, Palette.ACCENT, 3))
	theme.set_stylebox("hover_pressed", "AccentButton", _box(Palette.PANEL, Palette.ACCENT, 3))

	# Compact square-ish HUD buttons.
	theme.set_type_variation("HudButton", "Button")
	var hud := _box(Palette.PANEL_RAISED, Palette.PANEL_BORDER, 2, 16)
	hud.content_margin_left = 12
	hud.content_margin_right = 12
	theme.set_stylebox("normal", "HudButton", hud)
	var hud_pressed := _box(Palette.PANEL, Palette.CIRCUIT, 2, 16)
	hud_pressed.content_margin_left = 12
	hud_pressed.content_margin_right = 12
	theme.set_stylebox("pressed", "HudButton", hud_pressed)
	theme.set_stylebox("hover_pressed", "HudButton", hud_pressed)
	theme.set_font_size("font_size", "HudButton", 26)

	# Level buttons in the level grid.
	theme.set_type_variation("LevelButton", "Button")
	var level := _box(Palette.PANEL_RAISED, Palette.CIRCUIT_IDLE, 2, 16)
	level.content_margin_left = 4
	level.content_margin_right = 4
	theme.set_stylebox("normal", "LevelButton", level)
	var level_disabled := _box(Palette.PANEL, Palette.PANEL_RAISED, 2, 16)
	level_disabled.content_margin_left = 4
	level_disabled.content_margin_right = 4
	theme.set_stylebox("disabled", "LevelButton", level_disabled)
	theme.set_font_size("font_size", "LevelButton", 30)


func _panel_styles(theme: Theme) -> void:
	var panel := _box(Palette.PANEL, Palette.PANEL_BORDER, 2, 24)
	panel.content_margin_left = 32
	panel.content_margin_right = 32
	panel.content_margin_top = 28
	panel.content_margin_bottom = 28
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_type_variation("CardPanel", "PanelContainer")
	var card := _box(Palette.PANEL_RAISED, Palette.PANEL_BORDER, 2, 20)
	card.content_margin_left = 24
	card.content_margin_right = 24
	card.content_margin_top = 20
	card.content_margin_bottom = 20
	theme.set_stylebox("panel", "CardPanel", card)

	theme.set_type_variation("AccentCard", "PanelContainer")
	var accent := card.duplicate() as StyleBoxFlat
	accent.border_color = Palette.ACCENT
	accent.set_border_width_all(3)
	theme.set_stylebox("panel", "AccentCard", accent)

	theme.set_type_variation("DialogPanel", "PanelContainer")
	var dialog := panel.duplicate() as StyleBoxFlat
	dialog.border_color = Palette.CIRCUIT_IDLE
	dialog.shadow_color = Color(0, 0, 0, 0.45)
	dialog.shadow_size = 24
	theme.set_stylebox("panel", "DialogPanel", dialog)


func _scroll_styles(theme: Theme) -> void:
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Palette.CIRCUIT_IDLE
	grabber.set_corner_radius_all(4)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(Palette.PANEL, 0.4)
	track.set_corner_radius_all(4)
	track.content_margin_left = 3
	track.content_margin_right = 3
	theme.set_stylebox("grabber", "VScrollBar", grabber)
	theme.set_stylebox("grabber_highlight", "VScrollBar", grabber)
	theme.set_stylebox("grabber_pressed", "VScrollBar", grabber)
	theme.set_stylebox("scroll", "VScrollBar", track)
