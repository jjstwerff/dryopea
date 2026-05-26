<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Plan 01 — In-game ground-type editor

**Status:** Future (design drafted 2026-05-26; no code).

## Goal

A minimal **in-game** editor that lets the player paint hex tiles
with ground types from a small palette. The painted hex grid is the
SUBSTRATE every later dryopea system (structures, flow-field
pathing, combat, scramble) builds on top of via a runtime override
layer — see the master design at
[`../../../docs/DESIGN.md`](../../../docs/DESIGN.md).

This is the **first** dryopea plan because every other plan assumes
"a level exists." This one creates that level.

## Two load-bearing design choices

### 1. In-game, not a separate editor

The editor is a **mode of the dryopea executable**, sharing the
same render pipeline, input system, camera, and hex math as the
running game. There is no separate editor binary.

Why:
- One executable → one render path to maintain → no
  editor-vs-game drift (the moros project has historically had
  to keep its editor and game renderers in sync; dryopea avoids
  that by construction).
- "Level designer" is just a privileged player mode. Same code
  draws a base in-edit and in-play; the only delta is which
  input gestures are wired up.
- The player can adjust terrain **between runs** without leaving
  the game — dovetails with the scramble + run meta-loop
  (DESIGN.md § scramble): tweak the next base while reviewing
  what you carried over.

### 2. Sea-default infinite world (sparse storage)

The default ground type is **sea (dark blue)** and the world is
conceptually **infinite** — the camera can pan in any direction
forever and always renders flat sea.

Storage is **sparse**: a hex only takes memory once it has been
painted to something OTHER than sea. Un-painted hexes are sea by
implicit default; reading them returns the sea palette entry
without touching memory.

Why:
- Matches the lib-plan-19 gridmesh world model
  (`hash<Chunk[cx,cy,cz]>` sparse outer, dense inner), so the
  editor naturally scales into the same data layout the game
  consumes.
- A blank world is "the sea before land was raised" — paint =
  reveal land. This dovetails with lib-plan-20's drainage-seed
  semantics: sea pins height = 0, painting hills/mountains
  raises terrain *out of* sea.
- An infinite grid frees the editor from choosing a world size
  upfront. Bases grow organically.

## Scope

In:
- A FLAT (single `cy`-layer) hex world. Camera 2D top-down for
  E1-E4; 3D extrusion + 3rd-person camera deferred to
  [lib-plan 19](https://github.com/jjstwerff/loft/blob/main/doc/claude/lib_plans/19-gridmesh/README.md)
  Phase C.
- A ground-type palette read from
  [`../../../examples/terrain.txt`](../../../examples/terrain.txt):
  `{name, color, slope}` per type. Sea is one entry — the default.
- Sparse painted-hex storage: `hash<GroundType[q,r]>`. Miss =
  sea.
- Hover-to-highlight; click to paint a hex; click-and-drag to
  paint a line.
- Camera pan (drag or WASD) over the infinite world.
- Save / load to disk; reload on launch resumes the world.

Out of scope (later plans):
- Slope-from-painted-type solver — lib-plan 20.
- Multi-layer (`cy`) editing — lib-plan 20 + dryopea D1.
- 3D extrusion / gridmesh meshing — lib-plan 19 Phase C.
- Built structures (walls / towers / bridges) — dryopea D1.
- Combat, waves, scramble, run meta — D3-D5.

## Phases

| # | Scope | Proves |
|---|---|---|
| **E1** | **Infinite sea + camera.** Render an endless 2D hex grid where every visible hex is sea (dark blue). Camera pans freely (drag or WASD). NO data, NO palette UI, NO paint. Just the empty world + a moving viewport. | The frustum→visible-hexes enumeration. The "miss = sea" path. The render pipeline against `lib/graphics`. |
| **E2** | **Palette load + named picker.** Parse [`examples/palette.json`](../../../examples/palette.json) at startup; render a **named swatch picker** on screen (each entry = colour swatch + the type's name, vertically stacked); click or hotkey selects the active type. Still no painting — just inspection.  Sketch + details below. | Palette file format. Basic 2D UI primitives (swatch, label text, hover-state). The picker is the player's primary *named* interface to the palette — colour alone is not enough. |
| **E3** | **Paint sparse.** Click a hex → write `(q,r) → active_type` into the sparse `hash<GroundType[q,r]>`. Drag → paint a line. Hover → highlight. Render: each visible hex looks up in the sparse map; miss = sea. | Picking (screen→hex). Sparse mutation. The data model the rest of dryopea inherits. |
| **E4** | **Save / load.** JSON file: list of `{q, r, type_name}` entries; load on launch repopulates the sparse map. | Persistence file format — the seed of dryopea's level format. |

E1 is the foundation everything else stacks on; E2-E4 each add
one capability on top.

### E2 — named picker UI sketch

The palette UI is a **vertical list of named swatches**, one
row per palette entry from
[`examples/palette.json`](../../../examples/palette.json).  Each
row is a coloured swatch + the type's name + a hotkey hint;
clicking a row or pressing the hotkey selects that type as
active for painting.  The active row gets a visible highlight
(e.g. brighter border or a leading arrow).

```
┌───────────────────────────────┐
│ Palette                       │
├───────────────────────────────┤
│ ▶ ■ sea          [1]          │  ← active (highlighted)
│   ■ water        [2]          │
│   ■ rapids       [3]          │
│   ■ waterfall    [4]          │
│   ■ sand         [5]          │
│   ■ grass        [6]          │
│   ■ hill         [7]          │
│   ■ rock         [8]          │
│   ■ steep_rock   [9]          │
│   ■ wall         [0]          │  ← placeholder colour, see GROUND_TYPES.md
│   ■ wall_high    [-]          │  ← placeholder colour, see GROUND_TYPES.md
└───────────────────────────────┘
```

Why a named picker, not colour-swatch-only:

- Some palette colours are deliberately **placeholders** (the
  red walls — see `color_status: "placeholder"` on those entries
  in `palette.json`).  A picker that only shows colour gives the
  player no name for "the red one"; with the name, the player
  reads `wall_high` and the placeholder colour stops being
  load-bearing.
- The picker IS the palette's UI vocabulary.  Names appear in
  the inspection HUD (plan 02 V5), in save files (E4), and in
  later structures spec.  The picker exposes the same names so
  the player learns them naturally.
- Hotkeys `1` through `0` then `-` cover the 11 entries; click
  still works for mouse-first users.

Open Q (E2-internal): horizontal vs vertical layout (vertical
read better for ≥10 entries); sub-palette headers (e.g. a
divider line + "water" / "land" / "structure" group label
between sections) — lean **yes**, makes the palette structure
visible.  Make in E2; cheap to revisit.

## Open questions

1. **Hex layout** — axial flat-top (matches moros) or offset
   pointy-top (matches `audience_crystal` / the 2023 proto)?
   Pick one before E1 and record the reasoning.
   **Lean axial flat-top** for future moros-data interop.
2. **Camera input mapping.** WASD pan, mouse-drag pan, scroll zoom
   — confirm before E1. Lock to a single convention so E2-E4
   don't have to support multiple.
3. **Palette file format.** Inline JSON inside `terrain.txt` (the
   2023 prototype already uses `{ name = "...", color = ..., slope = N }`
   — close to a loft struct literal) vs proper JSON `[{...}]`.
   Lean **proper JSON** so the loader is just `text as
   vector<GroundType>`. The 2023 file becomes the input shape, with
   a one-time conversion.
4. **In-game UI primitives.** Survey `lib/graphics` and the
   audience-demo projector's HUD pattern before E2 — if there is
   no shipped 2D-UI lib, the swatch picker may need a minimal
   helper inside dryopea. Note any gap as a P-issue in loft.
5. **Save format scaling.** JSON is fine for a hundred painted
   hexes; revisit when a base reaches ~10 000 painted hexes
   (binary or a custom format). E4's JSON is intentionally cheap
   and replaceable.

## Dependencies

- **loft** at a current version with `lib/graphics` GL bindings +
  a working game-loop. (Already shipped — both the audience demo
  and tic-tac-toe exercise these.)
- **No upstream lib-plan dependency** for E1-E4. The editor ships
  while terrain-heightmap and gridmesh Phase C remain on the
  design board. It will hand its painted grid up to those plans
  when they land.

## Why this plan is foundational

- **Owns the substrate.** Every dryopea phase from D0 onward
  assumes "a painted level exists." E1-E4 provide that.
- **Smallest dryopea-only scope** with no upstream blocks.
- **Exercises just enough of the eventual stack** (render, input,
  pan camera, sparse storage, save/load) to surface gaps in loft
  before bigger plans hit them — the dogfood loop applied
  immediately.
- **Sets the data shape.** The sparse `hash<GroundType[q,r]>` here
  is what the later override layer (D1 structures), flow field
  (D2 enemy guidance), and slope solver (lib-plan 20) all read or
  extend. Getting the shape right early avoids churn later.

## See also

- [`../../../docs/DESIGN.md`](../../../docs/DESIGN.md) — full
  master design.
- [`../../../examples/terrain.txt`](../../../examples/terrain.txt)
  — the palette seed (grass, hill, mountain, sea, sand, forest).
- **Upstream library plans** (gridmesh meshing + terrain
  height-map solver) — currently drafted in the loft tracker,
  expected to migrate to their own repos when loft drops
  outside-project references. The current placeholder URLs are
  recorded in [`../../../docs/DESIGN.md`](../../../docs/DESIGN.md)
  § See also and will be updated once the libraries move.
