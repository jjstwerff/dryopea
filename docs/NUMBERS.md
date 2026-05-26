<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Numbers — first-pass values

A coherent placeholder set for every numerical parameter
referenced in the design.  **Verify and refine through actual
gameplay** — these values are meant to *exist together
sensibly*, not to be balanced.  Adjust freely.

The set targets a single-base session of **~15-25 minutes**:
~45 s pre-wave commitment → 7 waves (15 s inter-wave) → ~5-6 min
wave phase → free scramble or earlier exit.

## World

| Parameter | Value | Notes |
|---|---|---|
| Hex diameter (vertex-to-vertex) | **1.5 m** | DESIGN.md § World scale |
| Hex side | **0.75 m** | = diameter / 2 |
| Hex flat-to-flat | **1.30 m** | = diameter × √3 / 2 |
| Hex layout convention | **axial flat-top** | Q13 settled.  Matches loft's `lib/moros_*` / `lib/audience_crystal` tradition. |
| Default map play-area | **~50 × 50 hexes** (~65 × 60 m) | Plan 04 open Q.  Map bounded but visible only within haze. |
| Atmosphere haze radius | **40 hexes** (~50 m) | Bounded camera view distance; SETTING.md § The atmosphere is thick |

## Player vehicle

| Parameter | Value | Notes |
|---|---|---|
| Length × Width × Height | 2.4 m × 1.1 m × 0.9 m | PROXY_ART.md |
| Hover clearance (idle) | 0.4 m | |
| Hover clearance (boosted) | 3.0 m | Max during boost |
| Movement speed (normal) | **3 hex/s** (~4 m/s) | Brisk drive |
| Movement speed (boost) | **6 hex/s** (~8 m/s) | 2× normal |
| Boost duration | **2.0 s** | Sustained, then auto-end |
| Boost cooldown (post-end) | **5.0 s** | Time before next boost available |
| HP (blocker-damage edge case only) | **100** | ~100 s of nibble before destruction |
| Damage rate when blocking core path | **5 HP/s per enemy** | From PROXY_ART.md conditional damage rule |
| Respawn after destruction | **instant** at core; launch countdown begins per usual rule |

## Enemy regular

| Parameter | Value | Notes |
|---|---|---|
| Footprint | <2 × <1 hex | PROXY_ART.md |
| Move speed (engage mode) | **1.5 hex/s** (~2 m/s) | Slow enough to react |
| Move speed (approach mode) | **1.5 hex/s** | Same; only direction differs |
| HP | **30** | = 3 tower shots |
| Nibble damage to player wallet (at core) | **1 point / s** | Slow drain — most pressure comes from compound effects |
| Nibble damage to walls (when blocked) | **1 HP / s** | Walls fall slowly to lone enemies; cluster pressure matters |
| Nibble damage to blocker (player / helper) | **5 HP / s** | Conditional damage rule |
| Loot value on death | **10 points** | Cheap individual reward; volume scales income |
| Pre-walk standstill at spawn | **5 s** | Scramble decision window (SETTING.md) |

## Enemy boss (phase 3 — values for planning)

| Parameter | Value | Notes |
|---|---|---|
| Footprint | 2 × 2 hex | DESIGN.md |
| Move speed | **1.0 hex/s** (~1.3 m/s) | Heavy industrial repair platform |
| HP | **200** | = 20 tower shots |
| Wall-break damage | **5 HP / s** | Bosses are the wall-breakers |
| Repair rate on nearby regulars (phase 3) | **+5 HP / s** | Range 3 hexes; per-repaired-unit |
| Repair range | **3 hexes** | Tight cluster around boss |
| Loot value on death | **50 points** | 5× a regular |

## Tower

| Parameter | Value | Notes |
|---|---|---|
| Footprint | 7 hex (centre + 6 neighbours) | PROXY_ART.md |
| Height | 6 m | Peeks over `wall_high` 5 m |
| Range | **15 hexes** (~20 m) | LOS blocked by `wall_high` + `steep_rock`, NOT by `wall` |
| Fire interval | **1.0 s** | Pulsed laser; one shot per second |
| Damage per shot | **10** | = 3 hits to kill a regular |
| Shot budget per charge | **30** | = 30 s of continuous fire before decay |
| Order cost (beacon) | **100 points** | Debited at pickup at the core |
| Construction time (after beacon drop) | **30 s** | One helper |
| Repair time (helper rebuild) | **20 s** | Helper repairs a black tower from scratch |
| Repair time (transplant from carried top) | **instant** | Salvage-and-deposit fast repair |
| Boost duration | **15 s** | While pink top |
| Boost effect | **2× fire rate, 1.5× damage, +5 hex range** | Aggressive but time-limited |
| Boost engage time (player must hold key while next to tower) | **2 s** | Player commits attention |

## Wall

| Parameter | Value | Notes |
|---|---|---|
| `wall` height | 3.0 m | |
| `wall_high` height | 5.0 m | Anti-insect barrier |
| `wall` HP | **100** | |
| `wall_high` HP | **200** | |
| Construction time (per hex) | **10 s** (wall) / **20 s** (wall_high) | One helper per hex |
| Build cost | **free** (helper time only) | DESIGN.md |
| End-of-line drivable ramp slope | matches `hill` slope (~12) | GROUND_TYPES.md § Wall ends |
| Entrance gap recognition window | **1-3 hex** | GROUND_TYPES.md § Entrances |

## Helper

| Parameter | Value | Notes |
|---|---|---|
| Roster starting | 2 | Inside the core on landing |
| Roster cap | 6 | Hard cap |
| Move speed | **2.5 hex/s** (~3.3 m/s) | Slightly slower than player |
| HP | **50** | Halfway between player and regular enemy |
| Order cost | **100 points** | Same as tower order |
| Order delivery time (lander) | **20 s** | Top-color signal interpolates over this |
| Retrieval pickup speed | instant on adjacent | |
| Recovery time at core (post-retrieval) | **60 s** | Then rejoins roster |
| Construction tick (wall) | **10 HP / s** | Net = 10 s per wall (matches construction time) |
| Construction tick (tower) | proportional | 30 s total (PROXY_ART.md) |
| Carry capacity | 1 slot | Same as player |

## Core (central tower)

| Parameter | Value | Notes |
|---|---|---|
| Footprint | 7 hex hex-prism | PROXY_ART.md |
| Height | 8 m | Taller than max-decay tower (6 m) |
| Diameter (flat-to-flat) | 3.9 m | |
| HP | **∞ (invulnerable)** | DESIGN.md |
| Scrambler bubble radius | **25 hexes** (~33 m) | Approach→engage handoff = this boundary |
| Launch countdown duration | **6 s** | Player must stay inside to launch; exit cancels |
| Launch-cancel fade | **0.3 s** | Pulse fades to dark on opening exit |
| Core-landing area radius | **3 hexes** around player's pick | Random within; land hexes only |
| Starter-tower landing radius | **5-10 hexes** from core | Random within; visible from core |
| NPC-order top colour cycle | 30 % red, 40 % amber, 25 % green, 5 % white-flash | Interpolates smoothly across 20 s |

## Wave system

| Parameter | Value | Notes |
|---|---|---|
| Wave list | `[5, 8, 12, 20, 30, 50, 80]` | examples/waves.json |
| Inter-wave delay | **15 s** | |
| Pre-walk visibility interval | **5 s** | Player decision window |
| Wave-1 wall trigger (N walls built) | **8** | Either trigger fires wave 1 |
| Wave-1 provocation distance (hexes from core) | **≥ 12** | Markers within < 12 hexes are "safe to inspect" |
| Final-wave-cleared free-scramble grace | **unlimited** | No more enemies; player decides launch time |
| Active spawn marker pulse rate | 1 Hz | Subtle, gentle |

## Economy

| Parameter | Value | Notes |
|---|---|---|
| Starting points budget (first base) | **200** | Fund first tower + helper order |
| Carryover (unspent points → next base) | **1 : 1** | All unspent points carried to next base's budget |
| Tower order cost | 100 | (above) |
| Helper order cost | 100 | (above) |
| Loot value per regular enemy | 10 | (above) |
| Loot value per boss | 50 | (above) |
| Helper-delivered loot to core | same as direct pickup | No transit discount |
| Tower-top carryover effect on next base | **TBD; validation = no effect** | DESIGN.md Q4 |
| Sap value (deferred) | TBD | SETTING.md § The other enemy |

## Camera (game, not viewer)

| Parameter | Value | Notes |
|---|---|---|
| Default mode | 3rd-person follow | Behind/above the vehicle |
| Default height above vehicle | 15 m | Looking down |
| Default angle (downward) | 50° | |
| Zoom range | 10-30 m height | Scroll to adjust |
| FOV | 60° | |
| Visible radius (effective) | ~haze radius (40 hexes) | Beyond, fade to atmospheric fog |

## Input scheme

| Action | Key | Controller (sketch) |
|---|---|---|
| Move | **W A S D** | Left stick |
| Look / camera orbit | mouse | Right stick |
| Pickup / drop (single key) | **E** | A / X |
| Wall paint mode toggle | **Q** | B / circle |
| Vehicle boost (hold) | **Shift** | RT / R2 |
| Tower boost (hold while adjacent) | **Shift** *(same key, context resolves)* | RT (same; context) |
| Camera zoom | scroll wheel | RB/LB |
| Mode toggle (editor: ground ↔ marker) | **Tab** | Y / triangle |
| Palette select (editor) | **1 2 3 4 5 6 7 8 9 0 -** | D-pad cycle |
| Cancel / exit menu | **Esc** | Start |

**Open keybinds (settle when in-engine):** quick-rebind UI, hold-vs-tap distinctions for boost, controller-glyph variants.

## How to use this file

- Treat values as **placeholder constants**.  Change any one
  without ceremony — the design doesn't depend on the
  *value*, only on the *shape*.
- When a value changes, **note here why** in a one-line entry
  (helps future tuning).
- Once the engine is live, mirror these into a runtime config
  file (`examples/numbers.json` or similar) — but this
  document stays as the **rationale** companion.

## See also

- [`DESIGN.md`](DESIGN.md) — every mechanic these numbers attach to.
- [`PROXY_ART.md`](PROXY_ART.md) — geometry that some numbers reference.
- [`GROUND_TYPES.md`](GROUND_TYPES.md) — slope / drop / height-override numbers per ground type (separate from this file).
- [`../examples/palette.json`](../examples/palette.json) — palette values in loadable form.
- [`../examples/waves.json`](../examples/waves.json) — wave counts in loadable form.
