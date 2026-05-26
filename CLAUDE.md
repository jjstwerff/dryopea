<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Claude Code Instructions for the dryopea Project

## What dryopea is

**dryopea** is a sci-fi free-build / tower-defence game built on
[loft](https://github.com/jjstwerff/loft).  The defining mechanic
is **scramble-and-salvage**: when a base is about to be overrun,
the player fires a rocket out of the core building and evacuates
key components — each carried-out component disables the tower it
came from, so grabbing salvage *hastens* the overrun.  Evacuated
components give an advantage at the next base.  A run is a
sequence of bases, chained by what you carry out.

Status: **pre-alpha, design only**.  No playable code yet; only
design documents, plans, and salvaged 2023-prototype artefacts.
The full design lives in [`docs/DESIGN.md`](docs/DESIGN.md).

## Relationship to loft

loft is the language + runtime; dryopea is a consumer project.
The design originated as `@PLAN46` in the loft tracker but the
canonical version now lives here (loft will soon drop
outside-project references and keep only language / runtime bug
fixes).  Any link to
`github.com/jjstwerff/loft/blob/main/doc/claude/…` in this repo
is a **temporary placeholder** that will need updating once the
upstream library plans (gridmesh, terrain-heightmap) migrate to
their own repos.

When dryopea surfaces a need from loft — a language feature, a
stdlib gap, a runtime bug — file it in
[`QUESTIONS_FOR_LOFT.md`](QUESTIONS_FOR_LOFT.md).  Do **not** fix
it locally by patching loft from this repo; the loft project has
its own contribution flow.

## Repo layout

```
README.md                      — public-facing project intro
LICENSE                        — LGPL-3.0-or-later
CLAUDE.md                      — this file
QUESTIONS_FOR_LOFT.md          — outbound queue to the loft project
loft.toml                      — package manifest (deps empty until plan 01 starts)

docs/
  DESIGN.md                    — canonical master design (current truth)
  DESIGN_HISTORY.md            — design seeds salvaged from the 2023 prototype

plans/                         — loft-style plan tracker
  README.md                    — index + workflow (current at top level,
                                 future/, finished/, deferred/)
  DEFERRED.md                  — parked-plan index
  future/01-ground-editor/     — first plan: in-game ground-type editor

examples/                      — sample input data
  terrain.txt                  — 2023 ground-type palette
  map.png + map.xcf            — 2023 map art + GIMP source

archive/                       — preserved 2023 prototype artefacts
  README.md                    — explainer for what's here vs not
  world.gcp, main.gcp          — proto-loft game schema + CLI
  gameplay.data, terrain.data  — 2023 filled-in game data
  world-prototype.loft         — partial loft port of world model

src/                           — game source (empty until D0 / plan 01 ships)
```

## Documentation index

| File | Topic |
|---|---|
| [README.md](README.md) | Public-facing project intro — what dryopea is, status, repo layout |
| [docs/DESIGN.md](docs/DESIGN.md) | Master design — scramble phase, bounded sessions, editor/game split, the validation-tier mechanics, dependencies, planet-scale future expansion; long Updates 2026-05-26 list records every refinement decision |
| [docs/SETTING.md](docs/SETTING.md) | Setting / lore — haywire colonization robots, military cordon, permit-bound sorties; insects + sap economy; how the fiction frames every mechanic |
| [docs/GROUND_TYPES.md](docs/GROUND_TYPES.md) | 11-type ground palette (water + land + structure) — colours, slope / drop / height-override, wall topology + entrance rule |
| [docs/PROXY_ART.md](docs/PROXY_ART.md) | Placeholder geometry for testing gameplay before final art lands — enemy, boss (phase 3), player vehicle, NPC helper (with retrieval + skills), loot, tower beacon, tower (state machine + salvage), core building (6 sides + top status + bottom pulse), wall outline, construction state |
| [docs/DESIGN_HISTORY.md](docs/DESIGN_HISTORY.md) | Design seeds salvaged from the 2023 prototype — original README paragraphs, hex/terrain notes, game-data schema, with mapping into the current design |
| [plans/README.md](plans/README.md) | Plan tracker index + workflow |
| [plans/future/01-ground-editor/README.md](plans/future/01-ground-editor/README.md) | Plan 01 — in-game ground-type editor (sea-default infinite world, sparse storage) |
| [plans/future/02-solver-validation-viewer/README.md](plans/future/02-solver-validation-viewer/README.md) | Plan 02 — dual-layer 3D viewer for height-solver validation |
| [plans/future/03-marker-layer-and-spawns/README.md](plans/future/03-marker-layer-and-spawns/README.md) | Plan 03 — marker layer + multi-direction spawn points |
| [plans/future/04-map-library/README.md](plans/future/04-map-library/README.md) | Plan 04 — hand-authored map library + per-map objectives + event variance |
| [archive/README.md](archive/README.md) | What's preserved from the 2023 repo and what was deliberately dropped |
| [QUESTIONS_FOR_LOFT.md](QUESTIONS_FOR_LOFT.md) | Outbound queue to loft |

## Reading by goal

| Goal | Start here |
|---|---|
| Understand the game | [README.md](README.md) → [docs/DESIGN.md](docs/DESIGN.md) |
| Understand WHY a design choice is what it is | [docs/DESIGN.md](docs/DESIGN.md) § Updates since 2026-05-21 → [docs/DESIGN_HISTORY.md](docs/DESIGN_HISTORY.md) |
| Pick the next thing to work on | [plans/README.md](plans/README.md) (current table → future table) |
| Start implementing | [plans/future/01-ground-editor/README.md](plans/future/01-ground-editor/README.md) (the first plan) |
| Mine 2023 game data | [archive/README.md](archive/README.md) → `archive/world.gcp` + `archive/gameplay.data` |
| Send loft a request | [QUESTIONS_FOR_LOFT.md](QUESTIONS_FOR_LOFT.md) |

## Conventions

### Plans — loft-style

| Location | Status |
|---|---|
| `plans/<NN>-<slug>/` (top level) | **Current** — actively worked |
| `plans/future/<NN>-<slug>/` | **Future** — drafted, not started |
| `plans/finished/<NN>-<slug>/` | **Finished** — closed |
| `plans/deferred/<NN>-<slug>/` | **Deferred** — parked behind a trigger |

A plan is promoted from `future/` to top-level when work starts
(move the directory + update [`plans/README.md`](plans/README.md)).
When the plan's last phase ships, move it to `finished/`.
Effort tags: XS / S / M / MH / H / VH / L.

### Design changes

Update [`docs/DESIGN.md`](docs/DESIGN.md) directly — that file is
canonical.  Significant supersedes go under § "Updates since
2026-05-21" with a date, so the change history stays visible
without rewriting the body.

### Salvaged prototype material

[`archive/`](archive/) is **historical reference only**.  Files
there do not build and are not maintained.  When a design element
in DESIGN.md derives from archive material, link to it from
[`docs/DESIGN_HISTORY.md`](docs/DESIGN_HISTORY.md) — that
document is the bridge between past and present.

## Branch policy

### Current phase — pre-game-shippable: commit + push directly to `main`

**Until a runnable game build exists, direct commits to `main`
are the normal flow.**  The repo is small, single-author, and
the cost of branching ceremony outweighs its benefit while the
foundation is being laid.  Commit locally, push when the user
asks (`feedback_one_branch_per_cycle` still applies — no
automatic pushes).

**Trigger for switching to the formal flow below:** the moment
there's a runnable game — even a minimum-playable validation —
this section is retired and the **MANDATORY** rules below
become the policy.  Until then, the design corpus + plan
implementation work commits straight to main.

### Future phase — once a runnable game exists — MANDATORY

**Direct commits to `main` will not be allowed.**

All changes — features, design updates, plan edits — must land
on a feature branch and reach `main` only through a pull
request.  CI gates each PR.  `main` becomes the release branch,
every commit on it expected to be shippable, PRs the review
gate.

#### Rules (active once the policy switches)

1. **Never `git commit` directly on `main`.**  If you accidentally
   land on `main`, move the change to a feature branch before
   anything else.
2. **Pushing commits is OK by default — unless there's an open PR
   on the branch that the push would disturb.**  For a long-lived
   working branch with no open PR, push freely after each green
   commit so the remote stays in sync.  When the branch has an
   open PR, do NOT push without an explicit user instruction —
   force-pushes, rebases, or unexpected commits disrupt
   review-in-progress.
3. **Never create a branch or open a PR unless the user
   explicitly asks.**  Default mode is: work on the current
   branch, commit locally (or push per Rule 2), report what
   changed, and wait.  "Implement plan 01 phase E1" is *not* a PR
   instruction.  Only run `gh pr create` or `git checkout -b`
   after the user explicitly says "create PR", "open a PR",
   "merge", or "switch to a new branch".
4. Default branch name for general work: a GENERAL slug
   (`work`, `cleanup`, `housekeeping`) so the branch can host
   cross-theme commits.  ONLY a substantial plan (well-defined
   arc with its own design doc — e.g. `01-ground-editor`,
   `terrain-solver`) earns a specific branch name.
5. Merging to `main` is via a GitHub pull request — not a local
   `git merge`.

## Git safety — MANDATORY

### Never use `git stash pop` or `git pull` with uncommitted changes

Both can produce unrecoverable working-directory states.  Always
commit before any operation that changes the working tree.  To
compare with main, use `git diff main -- <file>` or
`git show origin/main:<file>` — no branch switch needed.

### Never use `git bisect` or `git checkout HEAD -- <files>`

Both routinely destroy multi-session work-in-progress.  To
investigate a regression, read the relevant code paths directly
or use `git show <commit>` / `git diff <commit>^ <commit>`.

## When this CLAUDE.md needs to grow

This file is intentionally light because dryopea has no code yet.
When the first plan (`01-ground-editor`) starts producing source,
add sections analogous to loft's CLAUDE.md:

- **Key commands** — how to run / test the game.
- **Architecture** — execution path through the source tree.
- **Key data structures** — the central types (`GroundType`,
  `WorldGrid`, etc.).
- **Important conventions** — naming, ordering, anything
  surprising.

Until then, the design + plans + archive layout above is the
whole working context.
