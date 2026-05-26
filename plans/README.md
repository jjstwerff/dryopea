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

## Current plans

| Plan | E | Depends on | Notes |
|---|---|---|---|
| *(none yet)* | | | |

## Future plans

| Plan | E | Depends on | Notes |
|---|---|---|---|
| [`future/01-ground-editor/`](future/01-ground-editor/README.md) | M | loft `lib/graphics` GL + game-loop | In-game editor for ground types. Sea-default infinite world, sparse storage. First plan — owns the substrate. |

## Finished plans

| Plan | Notes |
|---|---|
| *(none yet)* | |

## Deferred plans

See [`DEFERRED.md`](DEFERRED.md).

## Workflow

A plan is promoted from `future/` to top-level when work starts
(by moving the directory and updating the table above). When the
plan's last phase ships, move it to `finished/`. A plan that
loses its trigger but is worth keeping moves to `deferred/`
and a row is added to DEFERRED.md.

Effort tags follow loft conventions: XS / S / M / MH / H / VH /
L.

## See also

- [`../docs/DESIGN.md`](../docs/DESIGN.md) — master design.
- [`../docs/DESIGN_HISTORY.md`](../docs/DESIGN_HISTORY.md) —
  pre-@PLAN46 design seed material.
