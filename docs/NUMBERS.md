<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Numbers — runtime parameters

**Source of truth:**
[`../examples/numbers.json`](../examples/numbers.json) is the
runtime config the game loads at startup.  **Every parameter
has its value, units, and documentation inline in the JSON.**
Modders edit values there and re-launch — no rebuild required
(DESIGN.md § Moddability).

This document is the *high-level overview*: what's in the file,
why it's organised the way it is, and what the design targets
are.  For an individual parameter's meaning + tradeoffs, read
the JSON.

## What's in numbers.json

The file is a single JSON object with one section per system,
each section's leaves carrying `value` + `units` + `doc`:

| Section | Holds |
|---|---|
| `world` | hex grid scale, layout convention, map extents, atmospheric haze radius |
| `player_vehicle` | dimensions, hover heights, speeds, boost timings, blocker-damage model |
| `enemy_regular` | dimensions, speeds, HP, damage rates (core / wall / blocker), loot value, pre-walk standstill |
| `enemy_boss_phase3` | 2×2 footprint, speed, HP, wall-break + repair-on-regulars rates, loot value |
| `tower` | range, fire interval, damage, shot budget, costs + build/repair/boost timings + boost multipliers |
| `wall` | wall + wall_high heights, HPs, build times, the end-ramp slope, entrance gap window |
| `helper` | starting + cap roster, speed, HP, order cost, lander delivery + recovery times, construction tick |
| `core` | footprint + dims, invulnerability flag, scrambler bubble radius, launch countdown, all 5 landing geometry params |
| `wave_system` | wave list, inter-wave delay, pre-walk visibility, both wave-1 triggers (wall-count + provocation distance) |
| `economy` | starting budget, carryover ratio, all order / loot values, tower-top carryover effect (validation placeholder) |
| `camera` | over-the-shoulder pose, swing easing, FOV, haze visibility |
| `input` | key + controller binding map; mouse/right-stick reserved for UI clicks (camera is locked) |

## Design targets the parameters anchor

The defaults are picked to produce these *shapes* (verify in
play; tune freely):

- **Single base session ≈ 15-25 minutes.**  ~45 s pre-wave
  commitment → 7 waves with 15 s gaps → ~5-6 min wave phase
  → free scramble or earlier exit.
- **Tower DPS ≈ 10/s.**  Regular at 30 HP = 3-shot kill;
  cluster of 3 enemies dies in ~10 s under one tower.
- **Wall break-through ≈ rare.**  A lone enemy needs 100 s
  to break a wall; bosses 5× faster.  Wall-nibbling is the
  fallback when perimeter is fully closed; player intent is
  to leave deliberate entrances.
- **Economy ramps via loot.**  Wave 1 (5 enemies × 10 pts =
  50 pts) + 200 starting = 250 pts → 1 tower + 1 helper.
  Wave 2 (8 × 10 = 80 pts) plus carryover funds further
  expansion.  By mid-game the player should be running ~3-4
  towers + 4-6 helpers.
- **Movement scale.**  Player at 3 hex/s normal = ~4 m/s; an
  enemy at 1.5 hex/s gives time to react.  Boost (6 hex/s)
  is for crossing the base, not winning fights.
- **Combat economy ≈ 1 wave / 30 s of full-tower fire.**
  Tower shot budget 30 = the player needs to pace towers
  across the wave, salvage or repair between bursts.
- **Damage to wallet ≈ slow drain.**  At 1 pt/s per nibbling
  enemy, 5 enemies on the core = 5 pt/s; 200 pts buys 40 s
  before zero.  Encourages keeping enemies AWAY, not just
  outpacing the damage.

## What gets used by what

Cross-references between the parameter file and the design
docs:

| Parameter | Referenced by | Why |
|---|---|---|
| `world.hex_diameter` | every distance in the design | Canonical unit |
| `world.atmosphere_haze_radius` | SETTING.md § The atmosphere is thick; camera | Caps render + sight |
| `core.scrambler_bubble_radius` | SETTING.md § The core is a scrambling tower; wave engage-mode handoff | The bubble boundary IS the approach→engage trigger |
| `core.close_spawn_disable_radius` | DESIGN.md § Updates: free-pick landing | Auto-silenced spawn markers |
| `wave_system.wave_1_wall_trigger` + `wave_1_provocation_distance` | DESIGN.md § Updates: wave-start triggers | Either trigger fires wave 1 |
| `wall.entrance_gap_recognition_hexes` | GROUND_TYPES.md § Entrances | Two ends form a gate when within this range |
| `tower.shot_budget_per_charge` | PROXY_ART.md § Tower § lifecycle | Top goes black after this many shots |
| `helper.recovery_time_after_retrieval` | PROXY_ART.md § Helper § Damage | Time before retrieved helper rejoins |
| `economy.tower_top_carryover_effect` | DESIGN.md § Q4 | Mechanic carries, effect deferred — validation = "none" |
| `camera.swing_easing_time` | DESIGN.md § Updates: camera locked | Auto-reframe smoothing |

## Loading + modding

The intended flow:

1. Game starts → reads `examples/numbers.json` (or whatever
   path the install ships at).
2. Each section is bound to a strongly-typed config struct in
   loft code.
3. Player tweaks a value (e.g. raises `tower.range` from 15
   to 20) and re-launches.  Effect visible immediately.
4. Modders ship a forked numbers.json alongside a forked
   palette.json / waves.json / maps for a custom variant.

No code changes needed for any of this; the build is the
*engine*, not the *content*.  See DESIGN.md § Moddability.

## Updating values

When a value changes in `numbers.json`:

- Update the `doc` field if the *meaning* changed (not just
  the value).
- Note here in a one-line bullet if the change is
  *structural* (e.g., adding a new section, removing a
  parameter).
- Defer to the JSON's own inline docs for per-parameter
  rationale.

## See also

- [`../examples/numbers.json`](../examples/numbers.json) — the loadable config (source of truth).
- [`../examples/palette.json`](../examples/palette.json) — companion: ground-type palette.
- [`../examples/waves.json`](../examples/waves.json) — companion: wave count list (will fold into numbers.json eventually; kept separate for now to mirror plan 03's authoring shape).
- [`DESIGN.md`](DESIGN.md) — every mechanic the parameters attach to.
- [`PROXY_ART.md`](PROXY_ART.md) — geometry that some parameters reference.
- [`GROUND_TYPES.md`](GROUND_TYPES.md) — palette-internal slope/drop/height-override values (kept separate from numbers.json — they live with the palette content rather than the engine config).
