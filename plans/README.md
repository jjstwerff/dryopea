<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Plans

Multi-phase initiatives for dryopea. Each subdirectory holds the
plan README (goal + phases + dependencies) and any per-phase
files.

Style mirrors the loft project's tracker, kept light. Active
plans live at the **top level** (`plans/<NN>-<slug>/`); drafted
ones at `future/`; closed ones at `finished/`; parked ones at
`deferred/`. The DEFERRED index lives at
[`DEFERRED.md`](DEFERRED.md).

For a comprehensive feature roadmap that includes mechanics
not yet promoted to plan slots, see
[`ROADMAP.md`](ROADMAP.md) — it answers the "what could we
do next?" question in 30 seconds.

## Current plans

| Plan | E | Depends on | Notes |
|---|---|---|---|
| [`future/01-ground-editor/`](future/01-ground-editor/README.md) | M | loft `lib/graphics` GL + game-loop | E1-E4 + integration smoke + E1-live shipped; human playtest pending |

## Future plans

| Plan | E | Depends on | Notes |
|---|---|---|---|
| [`future/02-solver-validation-viewer/`](future/02-solver-validation-viewer/README.md) | MH | plan 01 + lib-plan 19 gridmesh + lib-plan 20 terrain-heightmap | 3D solver-output viewer; painted layer + height mesh, 40% see-through |
| [`future/03-marker-layer-and-spawns/`](future/03-marker-layer-and-spawns/README.md) | M | plan 01 | Second sparse layer; multi-direction spawn points |
| [`future/04-map-library/`](future/04-map-library/README.md) | M | plan 01 + plan 03 | MapFile schema + map index + browser + content |
| [`future/05-validation-scenario/`](future/05-validation-scenario/README.md) | M | plans 01-04 | Minimum playable thing; integration spec |
| [`future/06-editor-stencil-pipeline/`](future/06-editor-stencil-pipeline/README.md) | MH | plan 01 + loft `lib/graphics` mesh API | Editor-as-content-pipeline; multi-layer + bridges + stencil mode + mesh baker + composition.  Brings the suite into rapid prototyping; two shipping paths (polish or strike).  Indie unlock: ship full games on stencil output alone — viable engine offering for devs without an art team |

Several Tier-B / Tier-C / Tier-D features in
[`ROADMAP.md`](ROADMAP.md) don't have plan slots yet
(tower-strain arc, insects, elementals, station hub,
contact arcs).  They're tracked in the roadmap and get
promoted to a `future/NN-...` slot when their trigger
fires.

## Finished plans

| Plan | Notes |
|---|---|
| *(none yet — plan 01 moves here once its human playtest confirms.)* | |

## Deferred plans

See [`DEFERRED.md`](DEFERRED.md).

## Workflow

A plan is promoted from `future/` to top-level when work starts
(by moving the directory and updating the table above). When the
plan's last phase ships, move it to `finished/`. A plan that
loses its trigger but is worth keeping moves to `deferred/`
and a row is added to DEFERRED.md.

A roadmap entry that doesn't have a plan slot yet gets one
when its trigger fires — usually "the previous tier's plans
are mostly shipped" or "a new consumer needs this mechanic
now."

Effort tags follow loft conventions: XS / S / M / MH / H / VH /
L.

## See also

- [`ROADMAP.md`](ROADMAP.md) — logical-order feature list
  across all tiers
- [`../docs/DESIGN.md`](../docs/DESIGN.md) — master design.
- [`../docs/DESIGN_HISTORY.md`](../docs/DESIGN_HISTORY.md) —
  pre-@PLAN46 design seed material.
