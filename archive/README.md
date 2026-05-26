<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# archive

Salvaged artefacts from the 2023-era prototype (the original
`Dryopea` repo, now private at `jjstwerff/dryopea-archive`).
These files are **historical reference only**; they do not build
and are not maintained.

Living design that derives from this material is in
[`../docs/DESIGN_HISTORY.md`](../docs/DESIGN_HISTORY.md); the
canonical current design is in
[`../docs/DESIGN.md`](../docs/DESIGN.md).

## Contents

| File | Origin | What it is |
|---|---|---|
| `world.gcp` | `code/overland/world.gcp` | Game data schema in proto-loft (the `.gcp` extension predates loft's `.loft`). Classes for `Mission`, `Faction`, `Item`, `Building`, `Machine`, `BuildQueue`, `Link`; enums `Statistic`, `ItemType`, `LinkType`. Direct foundation for D4 (economy) + D5 (scramble inventory). |
| `main.gcp` | `code/overland/main.gcp` | CLI entry point of the 2023 `overland` generator (`<png-file>` in → `.glb` out). Shows the original "world is generated from a PNG" approach. |
| `gameplay.data` | `code/overland/data/gameplay.data` | 31 KB of filled-in game data — factions, items, missions. Mine when D4 starts. |
| `terrain.data` | `code/overland/data/terrain.data` | Terrain definitions. Inspect alongside `examples/terrain.txt`. |
| `world-prototype.loft` | `archive/world.loft` (in the original repo) | Partial loft port of the world model. Hill formula `(r-t)²(r+t)²`, `Action` enum (Flatten / Add / Subtract / Smooth / Pillar), multi-level `Position`, 32-chunk block addressing. Half-converted from C++ — useful as a thinking record, not as code. |

## What was deliberately NOT salvaged

- The entire loft-engine precursor (`Cargo.toml`, `src/`, `lib/`,
  `default/`, `tests/`, `webassembly/`, `archive/map.rs` etc.) —
  superseded by [loft](https://github.com/jjstwerff/loft) itself.
- Loft language documentation (`doc/*.html`,
  `loft-reference.{pdf,typ}`, `print.html`, `index.html`) —
  current versions live in loft.
- Build / IDE configuration (`Makefile`, `clippy.toml`,
  `.idea/`, `*.iml`, `rusty-tags.vi`).
- `example/todo.json` — that was a *personal* todo list
  (cleaning, exercise, call a friend), not a game file.
- The top section of the original `todo` file (loft-engine
  development notes). Only the bottom section, which contains
  game-design notes, was preserved — and only as quoted material
  in [`../docs/DESIGN_HISTORY.md`](../docs/DESIGN_HISTORY.md) § 2.
