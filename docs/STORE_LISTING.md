# Store Listing — Signal Shift

## Text

- **App name:** Signal Shift
- **Short description (≤80 chars):** Rotate circuit tiles to connect the signal. Calm, clever logic puzzles.
- **Subtitle (iOS, ≤30 chars):** Connect the signal
- **Category:** Puzzle (Games) · **Content rating:** Everyone / 4+

**Full description**

> Connect the signal. Outsmart the grid.
>
> Tap to rotate circuit tiles and route power from the source to every receiver. Simple to learn in seconds, satisfying to master.
>
> • 60 handcrafted campaign levels across six chapters — free, no paywall
> • A new Daily Puzzle every day, playable offline
> • Branching circuits, locked tiles, dead zones and move limits
> • Undo, reset and hints whenever you need them
> • Earn up to three stars by matching par
> • Reduced-motion mode, haptics and audio toggles
> • No forced ads. Optional videos only when you ask for a hint
>
> Want more? The Overclock pack adds 20 expert circuits, and the Supporter upgrade gives unlimited hints with no videos.

**Keywords (iOS):** puzzle,logic,circuit,connect,pipes,rotate,brain,daily,offline,minimal

## Graphics checklist

| Asset | Size | Source |
| --- | --- | --- |
| App icon | 512×512 (Play), 1024×1024 (App Store, no alpha) | export `icon.svg` |
| Feature graphic (Play) | 1024×500 | logo + title on navy background |
| Phone screenshots | 1080×1920 (Play), 1290×2796 (iPhone 6.7") | capture on device |
| iPad screenshots (if iPad enabled) | 2048×2732 | capture on device |

Suggested screenshots: main menu · early level mid-solve · branching level solved (green glow) ·
level select with stars · daily puzzle complete · Overclock preview.

Draft captures can be produced on desktop with the dev tool:

```sh
godot --path . res://tools/capture.tscn -- --scene=res://scenes/game/game.tscn --level=c025 --out=/path/shot.png
godot --path . res://tools/capture.tscn -- --scene=res://scenes/game/game.tscn --level=c060 --solve --wait=0.3 --out=/path/solved.png
```

Final store screenshots should be taken on real devices at native resolution.
