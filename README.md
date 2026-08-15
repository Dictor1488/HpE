# HpE

HP bars and current HP values for vehicles in the World of Tanks battle players panels (team "ears").

<img width="288" height="311" alt="HpE reference" src="https://github.com/user-attachments/assets/746996b2-22e6-450d-b788-2066555ab140" />

## Current implementation

- Adds a compact green HP bar and current HP number to each vehicle row.
- Supports both left (ally) and right (enemy) player panels with mirrored layout.
- Re-attaches the HP widget when the stock panel rebuilds its rows or changes state.
- Uses the stock `playersPanel` / `epicRandomPlayersPanel` and vehicle IDs rather than a fixed screen overlay.
- Receives health updates from Python and includes a polling fallback for missed battle events.

## Structure

- `python/gui/mods/HpE/` — battle state, health provider and Scaleform bridge.
- `as3/src_flash/` — player-panel injector and HP row renderer.
- `as3/libs/` — WoT SWC compile libraries.
- `.github/workflows/build.yml` — reproducible SWF + Python 2.7 + `.wotmod` build.

## Build

GitHub Actions compiles `hpePlayerPanel.swf`, compiles the Python mod with Python 2.7, packages everything into a `.wotmod`, and uploads it as the `HpE-wotmod` workflow artifact.

Current development version: `0.1.0`.
