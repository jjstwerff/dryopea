<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Plan 03 — Marker layer + multi-direction spawn points

**Status:** Future (design drafted 2026-05-26; no code).

## Goal

A **second sparse data layer** parallel to the painted ground
palette (plan 01), holding **markers** — placed entities the
*game runtime* reads but the painted palette doesn't represent.
The first marker type is the **spawn point**, with these
properties:

- **Multiple spawn points per base, not one.**  Enemies should
  not always arrive from the same direction; the designer
  places several spawns around the perimeter (or beyond it) so
  pressure can come from multiple sides at once.
- **Each spawn has a rough approach direction.**  A spawn point
  is not just a hex coordinate; it's a hex + one of the **6 hex
  cardinal directions** indicating which way enemies are
  *approaching from*.  Enemies appear at (or just outside) the
  spawn hex and initially head along that direction, which only
  later resolves into flow-field guidance once they're close
  enough to a base to "see" it.

A spawn isn't a "drop here" pin.  It's a **zone of pressure with
a heading**: "enemies are coming from over there."

## Two load-bearing design choices

### 1. A separate sparse marker layer, not a palette extension

Markers do *not* belong in the painted ground palette
(GROUND_TYPES.md).  Reasons:

- A spawn marker is **content**, not terrain.  It sits at a hex
  but doesn't render as the hex's colour — the hex underneath
  keeps its painted ground type (grass, sand, water…).  Markers
  *overlay* terrain rather than replacing it.
- Markers carry **structured data beyond a single enum value** —
  a spawn has a direction; an item position has an item id; a
  patrol marker has a path.  Trying to encode this in the
  `GroundType` enum bloats the palette.
- The marker layer's data shape differs from the ground layer.
  Ground = `hash<GroundType[q,r]>`; markers =
  `hash<Marker[q,r]>` where `Marker` is a tagged union (today
  just `Spawn { direction }`; later `Item`, `Patrol`, etc.).

Both layers are **sparse** in the same sea-default sense: a hex
with no marker has no marker.  Most hexes have no marker, so
storage scales with placed-marker count, not world size.

### 2. Editor is a two-mode tool, not two tools

The editor (plan 01) gets a **mode toggle** between:

- **Ground mode** (today) — paint the `hash<GroundType[q,r]>`
  layer with palette swatches.
- **Marker mode** (this plan) — place / rotate / remove markers
  in the `hash<Marker[q,r]>` layer.

Same executable, same camera, same hex grid, same
selection-and-click mechanics; the only difference is *which
data layer* the click writes to.  This keeps the in-game-editor
discipline (DESIGN.md § Updates) without splitting into two
tools.

## Scope (validation tier)

In:
- A sparse `hash<Marker[q,r]>` layer parallel to plan 01's
  painted ground layer.  Same sparse / sea-default semantics.
- One marker variant: **spawn** (`{ direction: 0..5 }`).
- Editor: mode toggle (ground ↔ marker) via hotkey.
- Spawn placement: in marker mode, click a hex → spawn marker
  appears; click again → removed.  Hotkey **R** rotates the
  marker's direction one step clockwise; **Shift+R** rotates
  counter-clockwise.
- Spawn visual: a small **triangular arrow** rendered on the
  marker's hex, pointing along its direction.  Distinctly
  off-palette colour (default **`#ff3060`** — a vivid hot pink
  / magenta, so spawn markers can't be mistaken for terrain
  even on sand or wall hexes).  Visible at any zoom.
- Save / load: spawns persist in the same save file as the
  painted layer (plan 01 E4).
- Runtime: at validation, a constant trickle of enemies from
  each placed spawn marker.  Each enemy appears at the marker
  hex with heading = marker's direction; it travels in that
  direction at constant speed until it enters the flow-field
  range (see § Approach-mode vs engage-mode below).

Out of scope (deferred to later plans):
- **Multiple marker variants** (item positions, patrol nodes,
  treasure pins).  The marker layer is *built* to host them;
  the validation tier only places spawns.
- **Enemy "approach AI" — the real one.**  The shaped
  approach-direction behaviour is the **placeholder**; the
  enemy "no base nearby" AI mentioned by the user is its own
  later plan (see § Approach mode below).
- **Stencil markers** (multi-hex authored regions).  Single-hex
  markers cover this plan.

## Waves — a simple count list

For validation, **waves are a flat list of enemy counts**.
That's the whole schedule:

- A wave is just an **integer** — how many enemies to release
  in this wave.
- A scenario has an **ordered list of waves**:
  `[5, 8, 12, 20, 30, 50, 80]` — first wave is 5 enemies, the
  last is 80.
- Direction is **NOT** in the wave list.  Where each enemy
  comes from is decided **per-enemy at spawn time**, by picking
  a random spawn marker from the set placed on the map.  The
  picked marker's direction governs the enemy's approach
  heading.
- Wave separator: a fixed inter-wave delay (e.g. ~15 s) for now,
  long enough that the player can survey damage, repair towers,
  and reposition.
- Wave clear condition: the wave is "active" while at least one
  of its emitted enemies is alive on the map; once the last
  enemy dies, the wave is cleared.  Next wave starts after the
  inter-wave delay.

Authored in [`../../../examples/waves.json`](../../../examples/waves.json)
— a simple JSON array of integers + a single `inter_wave_delay`
seconds value.

Why a flat count list (not a richer schema):
- It's the **smallest thing that creates an ascending
  difficulty curve** for the validation scenario.  Each wave is
  larger; the player has to defend longer / better as the run
  progresses.
- Direction-randomness comes from the map's spawn markers, not
  the wave data.  Two scenarios with identical wave lists but
  different spawn-marker layouts feel completely different to
  play — which is the validation: that map authoring matters.
- Easy to extend later: a wave can grow extra fields
  (`enemy_kind`, `burst_pattern`, `boss: true`, `delay`) without
  breaking the integer-only short form (treat a bare integer as
  `{ count: N }`).

What this is NOT (yet):
- No enemy type variety — every enemy in every wave uses the
  same proxy.  Multi-type waves slot in later by tagging waves
  with kinds.
- No per-wave delay override (uniform `inter_wave_delay`).
- No boss waves; no "swarm vs single elite" pacing.
- No procedural scaling — the list is **authored**, not
  generated.

## Phases

| # | Scope | Proves |
|---|---|---|
| **M1** | **Marker data layer.** Add `hash<Marker[q,r]>` parallel to the painted layer.  `Marker` is a tagged union — for now only `Spawn { direction: 0..5 }`.  Save / load includes both layers (plan 01 E4 extension). | The data model + the parallel-layer concept. |
| **M2** | **Editor mode toggle.** Hotkey (`Tab` proposed) flips between ground mode (paints palette) and marker mode (places markers).  HUD shows which mode is active. | The two-mode editor pattern; future marker variants slot in. |
| **M3** | **Spawn placement + rotation.** In marker mode, click → place / remove; **R** / **Shift+R** rotate the placed direction.  A faint *ghost* arrow appears at the hovered hex so the designer sees where the marker will go before clicking. | The placement UX. |
| **M4** | **Spawn render in-game.** The painted-layer view (plan 01) and the validation viewer (plan 02 V3+) both render the spawn-marker triangle on top of the ground colour.  Visible at any zoom. | The overlay render — markers don't replace terrain colour. |
| **M5** | **Runtime spawn execution.** When the game starts (or a validation scenario triggers), each spawn marker emits enemies at a constant rate (e.g. one every ~2 s).  Each spawned enemy carries an **initial heading** = marker's direction. | The spawn pipeline; the heading hand-off into approach behaviour. |

M5 closes the validation loop: paint a base, place spawns
around it pointing inward, run the scenario, watch enemies
flow in from multiple sides.

## Approach mode vs engage mode (the future-AI hand-off)

This plan ships a **placeholder approach behaviour** that gives
the player the right *feel* for now — multiple directions of
attack — and creates a clean hand-off point for the future
"enemy AI when no base nearby" the user mentioned.

**Approach mode** (placeholder, this plan's M5):
- Enemy spawns at marker, heading = marker's direction.
- Enemy walks in that direction at constant speed.
- After N hexes (default ~10) OR when the enemy enters a hex
  within the flow-field's computed region (within range of a
  wall or the core), the enemy **switches to engage mode**.
- In approach mode the enemy is essentially dumb — straight
  line; bumps into terrain by simple slope-gated movement
  rules.

**Engage mode** (existing — DESIGN.md § Systems #4):
- Enemy samples the flow field at its current hex.
- Walks toward the descent neighbour.
- Standard tower-defence behaviour.

**Future replacement of approach mode — the "enemy AI" plan.**
The user has signalled that enemies will eventually get their
own AI for when no base is nearby (the planet-scale
roam-the-world behaviour in DESIGN.md § Future expansion).
That AI replaces *only* approach mode; engage mode and the
spawn-marker data shape remain unchanged.  The hand-off point
(approach → engage when within range) is the architectural
seam that lets the future AI plug in without touching the
spawn pipeline or the base-defence flow field.

So the design constraint here is: **the spawn marker is
forever; approach behaviour is replaceable.**  Keep their
boundary clean.

## Editor visual — what spawn markers look like

When in marker mode and hovering over an empty hex, a **faint
ghost arrow** previews where the spawn will land (and which way
it will point — current rotation state).  Clicking commits;
clicking on a placed marker removes it.

```
                    Painted ground hex (any palette colour)
                    underneath; the arrow does NOT replace
                    the ground colour, it overlays.
       ┌─ hex ─┐
       │   ▲   │      ← spawn arrow ▲ at hex centre,
       │ ◣ ▲ ◢ │        pointing in the marker's
       │   ▲   │        chosen direction (0..5).
       └───────┘
       direction 0  → arrow points "up" (+r in axial)
       direction 1  → +60° clockwise
       …
       direction 5  → 300° clockwise (= 60° counter-clockwise)
```

The arrow is `#ff3060` so it stays unambiguous against any
palette hex — including the sand `#f0d860` (which would absorb
a yellow arrow) and the wall placeholder reds (which would
absorb a red arrow).  Hot pink doesn't appear anywhere else.

Hotkeys (proposed; settle in M3):

| Key | Action (marker mode) |
|---|---|
| Click hex | Place / remove spawn marker |
| `R` | Rotate active marker direction +1 (clockwise) |
| `Shift+R` | Rotate active marker direction -1 (counter-clockwise) |
| `Tab` | Switch back to ground mode |
| `Esc` | Cancel hover; no commit |

## Dependencies

- **Plan 01** — `hash<GroundType[q,r]>` painted layer; this
  plan adds a parallel `hash<Marker[q,r]>` layer using the same
  sparse / sea-default discipline.  M1-M3 can start once plan
  01 E1-E3 ship.
- **No upstream lib-plan dependency.**  The marker layer is
  pure dryopea data + UI — no slope solver, no gridmesh
  meshing involved.
- **Plan 02 (viewer)** — co-renders the markers via its V3
  overlay pass.  No coupling; the viewer just reads the same
  marker layer.

## Why this plan, why now

- The base game can't be played without spawns.  Plans 01 + 02
  + this one are the **minimum content + authoring set** for a
  validation scenario.
- A multi-spawn, multi-direction design is the **cheapest** way
  to make the base feel pressured by something other than "the
  one direction enemies always come from."  At validation tier,
  three spawn markers pointing at different sides of a base
  produce visibly different gameplay than a single spawn —
  without any wave-scheduling or AI work.
- The **marker layer** is a recurring substrate (item positions,
  patrol nodes, scripted-event triggers, future-enemy-AI
  waypoints all live here).  Building it once, for spawns, sets
  the pattern.

## Open questions

1. **Spawn off-grid?** Should enemies appear AT the marker hex,
   or at a hex one or two steps OUT from the marker in the
   marker's direction (so it reads as "they came from over
   there")?  Lean **slightly out** — visually less abrupt; an
   enemy fading in 1-2 hexes away from the marker, walking
   toward the marker, then past it.  Mark hex itself is the
   *anchor*, not the *spawn location*.
2. **Concurrent spawns from one marker?** Validation tier:
   one-at-a-time trickle.  Later: bursts (3-5 enemies emerge
   close together) — needs only a per-marker `burst_size` /
   `burst_interval` pair.
3. **Direction granularity — 6 or 12?**  6 hex cardinals is
   the natural fit.  12 (with intermediate diagonals) would let
   the designer pick "from between NE and E" precisely.  Lean
   **6** for validation; revisit if pressure-feel needs more
   resolution.
4. **Marker count cap?**  No technical cap (sparse hash), but a
   *design* cap (e.g. "no more than 8 spawn markers per base")
   helps content discipline.  Leave open until V5 inspection
   shows actual usage.
5. **Should the placement preview show the spawn's expected
   first-N-hexes trajectory?**  In M3, hover with marker mode
   active could draw a faint line in the marker's direction
   showing where enemies will walk.  Useful UX; cheap; lean
   **yes**.
6. **Marker variants in the same layer?**  Yes by design — the
   `Marker` type is a tagged union from M1.  But validation
   doesn't need any variant besides `Spawn`.  Item / patrol /
   trigger variants ship in later plans without re-doing the
   layer.

## See also

- [`../01-ground-editor/README.md`](../01-ground-editor/README.md)
  — the painted-ground sibling plan; this plan parallels it
  with a marker layer.
- [`../02-solver-validation-viewer/README.md`](../02-solver-validation-viewer/README.md)
  — the viewer; renders markers as an overlay on top of the
  ground-and-mesh stack.
- [`../../../docs/DESIGN.md`](../../../docs/DESIGN.md)
  § Systems #4 — engage-mode flow field; the hand-off target
  for the future enemy AI that replaces approach mode.
- [`../../../docs/PROXY_ART.md`](../../../docs/PROXY_ART.md)
  § Enemy — the enemy proxy that this plan's spawns produce.
