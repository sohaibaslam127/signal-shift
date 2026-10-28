class_name PackTheme
extends RefCounted
## Per-pack visual identity: board colours, background pattern and optional generated artwork.
## Colours and patterns are code-drawn, so the game looks right without any generated asset;
## `background_texture` layers reviewed AI artwork on top when the file exists. Gameplay never reads
## a theme: connectivity comes from BoardState and the pack rules only.

const ART_PATHS := ["res://assets/packs/%s/backgrounds/background.png", "res://assets/packs/%s/backgrounds/background.jpg"]

## "default" is used by the campaign, daily puzzles and menus.
static var current: PackTheme = for_pack("default")

var id: String = "default"
var pattern: String = "grid"  # grid | lines | blueprint | pcb | hex
var bg_top: Color = Palette.BACKGROUND_TOP
var bg_deep: Color = Palette.BACKGROUND_DEEP
var glow_a: Color = Palette.ACCENT
var glow_b: Color = Palette.CIRCUIT
var pattern_color: Color = Palette.CIRCUIT
var signal_color: Color = Palette.SIGNAL
var success_color: Color = Palette.SUCCESS
var idle_color: Color = Palette.CIRCUIT_IDLE
var phase_color: Color = Palette.ACCENT
var tile_base: Color = Palette.TILE_BASE
var tile_top: Color = Palette.TILE_TOP
var tile_fixed: Color = Palette.TILE_FIXED
var tray_border: Color = Palette.CIRCUIT
var trace_width: float = 0.15  # fraction of the tile size


static func for_pack(pack_id: String) -> PackTheme:
	var t := PackTheme.new()
	t.id = pack_id
	match pack_id:
		"overclock":
			# Minimalist precision: near-black, thin neon lines.
			t.pattern = "lines"
			t.bg_top = Color("0a1016")
			t.bg_deep = Color("020305")
			t.glow_a = Color("0d3a44")
			t.glow_b = Color("0a2a33")
			t.pattern_color = Color("7ff6ff")
			t.signal_color = Color("8ff8ff")
			t.success_color = Color("e8fdff")
			t.idle_color = Color("2b4a55")
			t.tile_base = Color("070b0f")
			t.tile_top = Color("111b22")
			t.tile_fixed = Color("05080b")
			t.tray_border = Color("7ff6ff")
			t.trace_width = 0.07
		"logic_gates":
			# Digital lab: deep navy blueprint, blue/green indicators.
			t.pattern = "blueprint"
			t.bg_top = Color("0b1a3a")
			t.bg_deep = Color("040a1a")
			t.glow_a = Color("1b4fd1")
			t.glow_b = Color("1a8f6a")
			t.pattern_color = Color("6fb4ff")
			t.signal_color = Color("4aa8ff")
			t.success_color = Color("5cf2a6")
			t.idle_color = Color("39527f")
			t.tile_base = Color("0f1f44")
			t.tile_top = Color("17306a")
			t.tile_fixed = Color("0a1534")
			t.tray_border = Color("6fb4ff")
			t.trace_width = 0.11
		"circuit_breaker":
			# Repair bench: green PCB, copper traces, amber/red fault lighting.
			t.pattern = "pcb"
			t.bg_top = Color("14261b")
			t.bg_deep = Color("060d09")
			t.glow_a = Color("ff9a3c")
			t.glow_b = Color("ff4d4d")
			t.pattern_color = Color("d28b4a")
			t.signal_color = Color("ffb347")
			t.success_color = Color("7dff9c")
			t.idle_color = Color("8a5a2b")
			t.tile_base = Color("173323")
			t.tile_top = Color("21452f")
			t.tile_fixed = Color("0f2318")
			t.tray_border = Color("d28b4a")
			t.trace_width = 0.17
		"quantum_protocol":
			# Holographic network: violet/cyan energy on deep indigo.
			t.pattern = "hex"
			t.bg_top = Color("1a0f4a")
			t.bg_deep = Color("05030f")
			t.glow_a = Color("7a3cff")
			t.glow_b = Color("35e0f0")
			t.pattern_color = Color("a58bff")
			t.signal_color = Color("35e0f0")
			t.success_color = Color("9dfff0")
			t.idle_color = Color("4b4f8c")
			t.phase_color = Color("c58bff")
			t.tile_base = Color("1a1450")
			t.tile_top = Color("2a2275")
			t.tile_fixed = Color("120d38")
			t.tray_border = Color("a58bff")
			t.trace_width = 0.12
	return t


static func set_current(pack_id: String) -> void:
	current = for_pack(pack_id)


## Reviewed AI-generated backdrop for this pack, or null when none has been added.
func background_texture() -> Texture2D:
	for template: String in ART_PATHS:
		var path := template % id
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null
