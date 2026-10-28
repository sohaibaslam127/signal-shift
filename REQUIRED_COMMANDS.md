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

Premium pack rules (new `PackRules`, `PackTheme`, `IconGlyph` classes; hand-authored lesson levels in `tools/slices/`): refresh the class cache, regenerate pack JSON and run the checks.

```sh
godot --headless --path . --import
godot --headless --path . -s res://tools/generate_levels.gd
./tools/run_tests.sh
```

Optional pack artwork (needs a Pollinations secret key, never committed; put it in the environment or a gitignored `.env.local`):

```sh
export POLLINATIONS_API_KEY=...            # from https://enter.pollinations.ai/keys
python3 tools/asset_generation/generate_assets.py            # generates into tools/asset_generation/staging/
python3 tools/asset_generation/generate_assets.py --approve all   # after reviewing the staged files
godot --headless --path . --import
```
