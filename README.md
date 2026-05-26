<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# dryopea

A non-standard sci-fi tower-defence built on
[loft](https://github.com/jjstwerff/loft).

Status: **pre-alpha, design only — no playable code yet.** Depends on
two upstream library plans (terrain height-map + gridmesh Phase C)
that are also pre-code. The design is canonical:
[`docs/DESIGN.md`](docs/DESIGN.md).

## What sets it apart — the scramble phase

At the start of each base the player places a **core building** —
the thing the enemies attack and the player must defend. The player
rides a **semi-floating vehicle** and rather than placing structures
directly, issues **build orders** that NPC workers construct over
time.

A base is **not** win-or-lose-forever. When it's about to be overrun,
the player can **scramble**: fire a rocket out of the core building,
evacuating key components — each evacuation **disables the tower it
came from**, so grabbing salvage *hastens* the overrun. Hold longer
for more salvage; launch now to keep what you already have. That
tension is the core decision of the whole game.

Evacuated components give an advantage at the **next** base. A run
is a sequence of bases, chained by what you carry out — a roguelike
structure on top of a tower-defence base loop.

If the core is destroyed *before* you scramble, the **run** ends
(the true loss). A successful scramble is a tactical retreat, not a
defeat.

## Why on loft

dryopea is the first **real consumer** of two upstream library
arcs, and so doubles as their acceptance test:

- **Terrain height-map** — slope-based height-field generation
  (will live in a shared world / graphics library).
- **gridmesh Phase C** — per-chunk meshing + dirty incremental
  re-mesh.

Both currently sit as design docs in the loft tracker; loft is
expected to drop outside-project references soon (language /
runtime bug fixes only) and the upstream library plans will
migrate to their own homes. Until then, links into the loft repo
are temporary placeholders.

dryopea's authoring cost is small (a handful of materials + one
drainage seed), so it exercises the **full** pipeline (per-chunk
meshing, frustum culling, LOD, slope faces, 3rd-person GL camera) at
low content cost.

## Repo layout

```
docs/                 — design + design-history references
  DESIGN.md           — canonical @PLAN46 design (mirrors loft tracker)
  DESIGN_HISTORY.md   — design seeds salvaged from the 2023 prototype
plans/                — phased work tracking, loft-style
  current/            — active phases
  future/             — drafted but not yet started
  finished/           — closed phases
  README.md           — index + workflow
  DEFERRED.md         — items parked behind a trigger
examples/             — sample input data (terrain palette, map.png/.xcf)
archive/              — preserved 2023 prototype artefacts (proto-loft .gcp,
                        partial world.loft, gameplay/terrain data)
src/                  — game source (empty until D0 starts)
loft.toml             — package manifest
```

## License

LGPL-3.0-or-later — see [LICENSE](LICENSE).
