class_name Palette
extends RefCounted
## Central colour palette and spacing tokens shared by the theme builder and custom drawing.

const BACKGROUND := Color("0b1030")
const BACKGROUND_TOP := Color("141a4a")
const BACKGROUND_DEEP := Color("05060f")
const PANEL := Color("121735")
const PANEL_RAISED := Color("1d2452")
const PANEL_BORDER := Color("2e3878")
const PANEL_SHADOW := Color("070920")

const MINT := Color("3ff0c4")
const MINT_DARK := Color("17a88e")
const CIRCUIT := Color("35e0f0")
const CIRCUIT_DARK := Color("1597a8")
const CIRCUIT_IDLE := Color("3a5a8c")
const SIGNAL := Color("4aa8ff")
const SIGNAL_GLOW := Color("a6d8ff")
const SUCCESS := Color("5cf2a6")
const SUCCESS_DARK := Color("23a86a")
const ACCENT := Color("6f42f5")
const ACCENT_DARK := Color("4421b8")
const WARNING := Color("ffc857")
const WARNING_DARK := Color("c98a1c")
const DANGER := Color("ff6b7a")

const TEXT := Color("f2f5ff")
const TEXT_DIM := Color("8f9bc8")
const TEXT_DISABLED := Color("4a5384")

const TILE_BASE := Color("1a2150")
const TILE_TOP := Color("232b63")
const TILE_FIXED := Color("141a40")
const TILE_BLOCKED := Color("0a0d24")
const BOARD_TRAY := Color("0c1029")

const FONT_REGULAR := "res://assets/fonts/Outfit-Variable.ttf"

const RADIUS := 22
const SPACING := 16
const TOUCH_TARGET := 96

static var _glow: GradientTexture2D


## Shared soft radial falloff (white centre to transparent edge). Tint it with the draw modulate.
static func glow_texture() -> GradientTexture2D:
	if _glow == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.4, Color(1, 1, 1, 0.4))
		_glow = GradientTexture2D.new()
		_glow.gradient = gradient
		_glow.fill = GradientTexture2D.FILL_RADIAL
		_glow.fill_from = Vector2(0.5, 0.5)
		_glow.fill_to = Vector2(1.0, 0.5)
		_glow.width = 256
		_glow.height = 256
	return _glow
