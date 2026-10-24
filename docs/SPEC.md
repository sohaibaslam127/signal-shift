# Signal Shift — Godot Game Development Specification

## 1. Role and objective

Build **Signal Shift**, a polished, lightweight 2D logic-puzzle game for Android and iOS, using Godot 4 Standard and GDScript. The game must be suitable for a solo developer to build, test, maintain, and monetize with Claude Code and Google Antigravity.

Work incrementally, implement one complete feature at a time, run validation, and fix regressions before proceeding.

## 2. Game vision

Tagline: Connect the signal. Outsmart the grid.

Players rotate circuit tiles to connect a power source to a destination. The game starts with simple puzzles and progressively introduces more difficult mechanics.

The experience must be:
- Easy to understand in under 10 seconds.
- Challenging without being unfair.
- Fast to load and responsive on mobile.
- Visually distinctive, with a clean futuristic circuit aesthetic.
- Replayable through daily challenges and progression.
- Monetizable without forcing advertisements on players.

## 3. Technology constraints

- Engine: Godot 4.x Standard. Language: GDScript, with static typing where practical.
- Primary platforms: Android and iOS. 2D, portrait orientation.
- Input: touch first; mouse input should also work in the editor.
- UI: Godot Control nodes and responsive containers.
- Rendering: favor compatibility and simplicity over unnecessary effects.
- Store levels and puzzle packs as local, version-controlled resources.
- Keep core gameplay functional offline.
- No backend, user accounts, multiplayer, or cloud saves in version 1.
- Keep advertising and in-app purchase integrations behind service interfaces.
- Verify all APIs against the actual Godot version and plugin versions in the project.

## 4. Architecture

Scene-oriented, modular architecture. Gameplay rules separate from presentation and platform-specific services. Folders: `scenes/` (boot, menus, game, components), `scripts/` (core, gameplay, data, services, ui), `resources/` (puzzles/campaign, daily, packs; themes), `assets/`, `addons/`, `tests/`, `docs/`. Create only what implemented features need.

## 5. Gameplay rules

### Circuit tiles
Straight, corner, three-way, four-way, source, destination, blocked, fixed (cannot rotate). Connections are directions up, right, down, left. Rotating changes connections by 90 degrees; visuals must always match connection data.

**AND gate** (`GATE_AND`, Logic Gates pack): a three-way tile with one designated output side and two input sides (the designation rotates with the tile). It only forwards signal out of its output side once both of its input sides are independently powered; power reaching it through its output side never activates it. Generator-placed gates are always fixed, so the puzzle is in wiring both input arms and the output arm, not in re-orienting the gate.

### Signal solver
Deterministic graph traversal / BFS that starts at the source, follows a connection only when the adjacent tile has the reciprocal connection, stops at blocked tiles and inactive gates, avoids revisiting tiles, detects destination reachability, returns the connected path for highlighting, and handles loops and branches safely. Visual node positions are never the source of truth.

### Puzzle validation
Validate grid dimensions, source and destination presence, tile data, fixed/blocked rules, and solvability. A puzzle that requires player action must not be complete at initial load.

### Player interaction
Tap rotates clockwise 90°. Tapping a fixed tile gives subtle feedback. Recalculate connectivity after each move; animate valid connections with a brief pulse. On success stop accepting moves; prevent duplicate victory events. Provide reset and undo (undo restores the exact previous board state). Store best move count and completion status.

## 6. Level design

60 handcrafted campaign puzzles:
- 1–10: basic straight and corner connections.
- 11–20: longer routes and additional turns.
- 21–30: branches and misleading connections.
- 31–40: fixed tiles, blocked cells, limited moves.
- 41–50: more complex layouts and multiple constraints.
- 51–60: challenging combinations.

Each puzzle has a known solution or verified solvability path. Never ship random puzzles without checking solvability. Data-driven definitions so new packs need no gameplay code changes.

## 7. User interface

- Main menu: logo/title, Continue, Level selection, Daily puzzle, Puzzle packs, Settings.
- Level selection: chapters, locked/unlocked, completion and stars, preserved scroll position.
- Gameplay: current level, move counter, optional move limit, reset, undo, hint, pause/settings, clear victory state.
- Victory: feedback, stars, next level, replay, level selection.
- Settings: sound, music, haptics, reduced motion, privacy policy link, restore purchases.

Responsive layouts, appropriate touch targets, safe-area aware, readable contrast.

## 8. Visual design

Premium minimalist sci-fi. Palette: deep navy background, cyan circuit, bright electric blue active signal, restrained green success, violet accent, off-white text. Reusable vector drawing; no expensive real-time effects. Only original or properly licensed assets.

## 9. Persistence

Versioned local save: unlocked level, completed levels, stars, best moves, sound/accessibility settings, daily completion, non-premium currency, purchased-content entitlements as supported by billing. Validate loaded data; handle missing/corrupted files. A local purchase flag is never proof of a store purchase.

## 10. Monetization

Never required to complete the free campaign.
- Rewarded ads: optional hint; optional retry/bonus where appropriate. Grant only after the SDK reports a reward. Friendly message when unavailable. No interruptions during solving.
- Puzzle packs: free starter campaign; additional data-driven packs with previews and level counts; platform-compliant IAP; restore; handle cancel/failure/unavailable billing; never simulate real-money purchases.
- Optional ad-free upgrade with exact benefits explained.
- Service interfaces before platform plugins; game playable with no monetization plugin.

## 11. Daily challenges

Deterministic date-based selection of curated puzzles; same date → same puzzle. Track completion, award a modest cosmetic or non-premium reward, never punish missed days, show on main menu, offline bundled content. No push notifications, accounts or cloud services in v1.

## 12. Performance

Smooth on common devices; avoid per-frame allocations, unnecessary instantiation and expensive shaders; handle pause/resume; block input during transitions and modals; test touch on devices; reasonable load time and install size.

## 13. Testing

Automated tests for tile rotation, reciprocal connections, traversal, loops/branches, blocked cells, fixed tiles, validation, win detection, undo/reset, save/load, daily selection. Use the project's actual Godot executable; do not assume a framework exists. Headless parse/import checks. Manual checks for UI, touch, audio, exports.

## 14. Agent workflow

Inspect project and Godot version, read AGENTS.md and docs, pick the smallest complete feature, explain the plan. For every feature: implement, validate, test, fix, summarize. Avoid concurrent edits to the same files by multiple agents. Never expose credentials or run destructive actions without approval.

## 15. Milestones

1. Project, boot scene, theme, main menu.
2. Circuit tiles, rotation, signal solver.
3. Puzzle data, validation, HUD, victory detection.
4. First 20 verified puzzles, then the 60-level campaign.
5. Level selection, undo, reset, local saving, settings.
6. Daily challenges and accessibility.
7. Rewarded-ad and IAP service interfaces.
8. Integrate and test mobile plugins, store purchases, rewarded ads.
9. Polish audio, animation, icons, store assets, performance.
10. Android and iOS release builds, privacy disclosures, store listings.

## 16. Definition of done

Behavior matches spec; scripts and scenes validate; tests pass; existing features still work; errors/warnings reviewed; works without unconfigured external services; final report lists modified files, validation, limitations and next step.
