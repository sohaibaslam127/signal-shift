# Required Commands

Visual redesign (new font asset and new `class_name` scripts: `IconButton`, `ToggleSwitch`, `UiIcons`, `TitleMark`, `MenuPill`, `MenuCard`):

```sh
# Import the Outfit font and refresh the global class cache
godot --headless --path . --import
```

Logic Gates pack (new `GATE_AND` tile type and puzzle topology): regenerating content is required to (re)produce `resources/puzzles/packs/logic_gates.json` after any change to the gate generator or its specs.

```sh
godot --headless --path . -s res://tools/generate_levels.gd
./tools/run_tests.sh
```
