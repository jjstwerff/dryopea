<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# dryopea — design (canonical)

The current master design for dryopea.  Originated as
@PLAN46 in the loft tracker (2026-05-21); refined and made
canonical here.  The original @PLAN46 draft is preserved as
an [appendix](#appendix--original-plan46-2026-05-21) at the
bottom of this file for traceability.

**Companion docs:**

- [`SETTING.md`](SETTING.md) — fiction (haywire robots, cordon,
  station, insects + sap, elementals + stones, history)
- [`GROUND_TYPES.md`](GROUND_TYPES.md) — 11-type ground palette
- [`PROXY_ART.md`](PROXY_ART.md) — placeholder geometry
- [`NUMBERS.md`](NUMBERS.md) +
  [`../examples/numbers.json`](../examples/numbers.json) —
  runtime parameters

**Plans** in `plans/future/`: 01 ground-editor, 02 viewer,
03 spawns, 04 maps, 05 validation-scenario.

---

## Contents

- [1. Status + scope](#1-status--scope)
- [2. The pitch](#2-the-pitch)
- [3. World](#3-world)
- [4. The core — the scrambling tower](#4-the-core--the-scrambling-tower)
- [5. Ground + walls](#5-ground--walls)
- [6. Spawn system + waves](#6-spawn-system--waves)
- [7. Combat dynamics](#7-combat-dynamics)
- [8. Player vehicle](#8-player-vehicle)
- [9. Helpers](#9-helpers)
- [10. Three enemy tiers](#10-three-enemy-tiers)
- [11. Movement + input philosophy](#11-movement--input-philosophy)
- [12. Camera + HUD](#12-camera--hud)
- [13. Economy + progression](#13-economy--progression)
- [14. Run structure](#14-run-structure)
- [15. Landing flow](#15-landing-flow)
- [16. Meta-game hub](#16-meta-game-hub)
- [17. Moddability](#17-moddability)
- [18. Numbers](#18-numbers)
- [19. Validation tier scope](#19-validation-tier-scope)
- [20. Future expansion](#20-future-expansion)
- [21. Open questions](#21-open-questions)
- [Appendix — Original @PLAN46 (2026-05-21)](#appendix--original-plan46-2026-05-21)

---

## 1. Status + scope

**Pre-alpha, design only — no code yet.**  Plans 01-05 in
`plans/future/` cover the system designs.  The runtime
parameters live in
[`../examples/numbers.json`](../examples/numbers.json); the
fiction in [`SETTING.md`](SETTING.md).

**Validation tier** = the buildable goal.  One base, one
mission, robots only, one tower type, one enemy type.  Targets
a single base session of **~15-25 minutes**: ~45 s pre-wave
commitment → 7 waves with ~15 s gaps → ~5-6 min wave phase →
free scramble or earlier exit.  Validation passes when a cold
player can play one base end-to-end with no critical
contradiction in 30 minutes of play.  Full scope in
[`plans/future/05-validation-scenario/README.md`](../plans/future/05-validation-scenario/README.md).

Everything below describes the design **including its future**.
What is in validation tier vs deferred is called out in
[§ Validation tier scope](#19-validation-tier-scope).

## 2. The pitch

A non-standard sci-fi tower-defence.  The player is a
**field-head of a small mining cooperative**, hired on a
**permit-bound sortie** into a planet sealed by a military
cordon.  In each sortie they drop into a base, paint walls,
order towers + helpers, defend against waves of haywire robots
(and eventually insects and elementals), and **scramble out**
when the time is right — launching the central building as a
rocket, carrying whatever they managed to grab.

The signature mechanic: **scramble-and-salvage**.  A base is
not win-or-lose-forever; it is one round of a longer **run**.
Evacuating a tower-top takes it with you but **disables the
tower it came from**, so grabbing salvage *hastens* the
overrun.  Hold longer for more haul; launch now to keep what
you already have.  That tension is the core decision of the
whole game.

Setting + tone in [`SETTING.md`](SETTING.md).

## 3. World

### Sea-default infinite world

Worlds start as an **endless flat sea**; only painted hexes
occupy storage (`hash<GroundType[q,r]>`, miss = sea).  Editor
and runtime share this data model — the in-game editor (plan
01) is a mode of the dryopea executable, not a separate
binary.  Painting walls + terrain happens in the same render
pipeline the game uses.

### Hex layout + scale

- **Axial flat-top** (matches loft's `lib/moros_*`
  convention; the gridmesh `HexLayout` adapter lets it
  coexist with offset pointy-top in shared code).
- **Hex diameter ~1.5 m** vertex-to-vertex (side ≈ 0.75 m,
  flat-to-flat ≈ 1.30 m).  Small enough that the painted
  resolution feels tactical (one hex ≈ "where one person
  stands"); large enough that authoring doesn't drown in
  count.

Implications: vehicle 2-3 hexes; tower 7 hexes; wall section
1 hex wide and several long; sniping ≈ 15-30 hexes; chunk
(32×32) ≈ 48 m across.

### Atmosphere — bounded view distance

The planet's air is **dense / hazy**.  Long visual sight lines
are physically blocked beyond ~40 hex (`atmosphere_haze_radius`
in NUMBERS.md).  Players must **scout** to learn what's beyond
the haze.  Also explains the prior humans' retreat to mountain
caves for breathing (SETTING.md § History); rendering bonus —
the engine never draws the whole map, just the haze radius
around the player.

## 4. The core — the scrambling tower

The central building is the **design hinge** — every other
mechanic attaches to or is gated by it.

### What it is

In the fiction, the core is a **signal-scrambling tower** (see
SETTING.md § The core is a scrambling tower).  It carves a
**bubble of broken comms** around the base in which robots
cannot reach their faction-master command links and fall back
to local per-unit behaviour.  Outside the bubble, robots
regain coordination; scouting beyond it is a risk.

Etymological convergence: the player's force-launch is called
**scramble**; the core is the **scrambler**.  Same word, same
thing — the scrambling tower the player ultimately rides home.

### Geometry — hexagonal prism, 6 sides

The core is a **black hexagonal prism**:

- **7-hex footprint** (centre + 6 neighbours).
- **~3.9 m diameter** flat-to-flat, **~8 m tall** (taller than
  a max-decay tower so silhouettes stay distinct).
- **6 distinct flat sides**, one per outer hex of the
  footprint.  **Three are functional, three are plain.**

Functional sides + their meaning:

| Face | Icon | Player interaction |
|---|---|---|
| **Output / lift-off (the opening)** | red flame/chevron | Drive **through** this opening to enter the core's interior and trigger launch.  Also where landers (helpers / supplies) emerge.  The only side the vehicle can pass through. |
| **Tower-core retrieval** | red disc | Drive next to it + pickup key → tower beacon spawns above the vehicle (cost in points). |
| **NPC ordering** | silver-grey rectangle | Drive next to it + pickup key → helper order placed (cost in points; lander touches down at the opening face shortly after). |

Plain sides are uniform black, no markings, no interaction.

### Two surface signals

- **Top colour** signals NPC-order status (validates pending
  orders at any zoom): black (no order) → red → amber → green
  → white flash on landing.  Colour interpolates smoothly
  across `lander_delivery_time` (default 20 s).  Diegetic; no
  HUD.
- **Bottom pulse** activates when the player enters the core's
  interior → orange-red ring at the base brightens and beats
  faster as the launch countdown elapses (default 6 s).  White
  flash at liftoff; fade to dark on cancel.

### Invulnerability + nibble → points

The core **cannot be destroyed**.  Enemies that reach the core
and "nibble" it do **not** damage its structure; each tick
**drains the player's point wallet** instead.  This retires
the @PLAN46-original "core destroyed = run ends" framing.
The player is never *forced* out by structural collapse; they
choose when to scramble.  The cost of staying too long is
bleeding points to nibbles.

### Force-launch — drive in, hold, exit to cancel

The only way to leave a base is to launch the rocket.  The
sequence:

1. Player drives **through the opening** into the core's
   interior.
2. Bottom pulse activates (orange-red ring at the base lights
   up + beats slowly).
3. Pulse rate accelerates as the countdown elapses.
4. At T = `launch_countdown_duration` (default 6 s), white
   flash → liftoff fires with whatever is currently onboard
   (carried items, deposited scramble inventory, wallet, any
   helpers that have made it back).
5. **Exiting the opening at any time before liftoff cancels**
   the sequence — pulse fades over 0.3 s, countdown resets.

NPC helpers normally board the rocket on their own when their
work list is empty.  Entering as the player **forces** launch
right then; any helpers not yet onboard, loot not yet
delivered, and stranded helpers not yet rescued are **left
behind**.

The countdown is also a **hazard window** during a wave —
enemies that reach the core keep nibbling (draining points)
while the player sits inside.  Stay longer for more carried
items + helpers boarding; launch sooner to keep what you
have.

### Vehicle respawn at core

When the player vehicle is destroyed (blocker-damage edge
case is the only damage path; see [§ Player vehicle](#8-player-vehicle)),
the player **respawns inside the core**.  This **starts the
launch countdown automatically** — the player must drive out
the opening to cancel (vehicle restored, return to base) or
stay to ratify the scramble.  Vehicle "death" is never a
game-loss; it's a forced return-to-base + a free "ready to
leave?" prompt.

## 5. Ground + walls

The painted hex layer is the substrate; full design in
[`GROUND_TYPES.md`](GROUND_TYPES.md).

### Palette

**Eleven ground types** in three sub-palettes:

- **Water** (4): sea / water / rapids / waterfall —
  drainage seeds with progressive drop.
- **Land** (5): sand / grass / hill / rock / steep_rock —
  progressive slope.
- **Structure** (2): wall / wall_high — height-override
  structures, placeholder red colours (the chosen colour will
  change; the placeholder is meant to stand out during
  development).

Loadable form in
[`../examples/palette.json`](../examples/palette.json).

### Walls — economy + topology

Walls (both heights) are **free in points** but **not
instant** — an NPC helper must spend construction time at the
build site (default 10 s for `wall`, 20 s for `wall_high`).
Bridges between walls (the `cy`-layer deck mechanic from
@PLAN46 Systems #3 + #4) are a **second-phase feature**; same
free-but-timed economics when they ship.

### Wall topology — drivable ends + recognised entrances

A wall hex with **exactly one wall neighbour** is a wall
**end**.  The face of the wall hex opposite that neighbour
renders as a **ramp** (drivable, slope-value of `hill`); the
other non-wall faces remain sheer.  Open ends therefore let
enemies roll up onto the wall — to actually defend, the
player must close the perimeter (every wall hex has ≥ 2 wall
neighbours).

**Two wall ends within 1-3 hexes of each other form a
recognised ENTRANCE.**  The non-wall hex(es) between them
become a preferred entry point — the flow field routes enemies
through; the player concentrates defensive fire there.  A
fully closed perimeter has **no entrance**, so enemies have no
path to the core and fall back to **nibbling the nearest
wall** (slow attrition, but the wall *will* fall).

### Wall climbability per enemy type

Heights aren't just visual variety:

| Wall type | Stops regular robots | Stops boss robots | Stops insects |
|---|---|---|---|
| `wall` (3 m) | Yes (sheer) | No (2×2 forces gaps or break) | **No — climbs easily** |
| `wall_high` (5 m) | Yes | No (still 2×2) | **Yes — anti-insect barrier** |

`wall_high` is **vital** when insects are part of the threat.
Mixed perimeters (`wall` on robot sides, `wall_high` on
insect-facing sides) become tactical.

## 6. Spawn system + waves

Plan 03 designs the spawn marker layer; plan 04 places markers
in maps.

### Multi-direction spawn markers

A second sparse data layer (`hash<Marker[q,r]>`) parallel to
the painted ground.  First marker variant: **spawn point** =
hex + one of 6 hex directions (the approach heading).  A base
typically has multiple spawn markers; enemies appear at each
and head along the marker's direction until they enter the
scrambler bubble, at which point they pivot to engage mode
(flow field toward the core).

**Close-spawn auto-disable.**  At landing, markers within
`close_spawn_disable_radius` (default 10 hex) of the core are
**silenced for the mission** — the visible marker remains as
map atmosphere but produces no enemies.  Map authors place
enough markers (~4-6 spread across a starter map) that any
reasonable landing leaves ≥ 2 active.

### Wave list (validation placeholder)

Authored as a flat sequence of integers in
[`../examples/waves.json`](../examples/waves.json) — each
wave's enemy **count**, with a fixed `inter_wave_delay`
between waves.  Per-enemy spawn-marker selection is **random**
at spawn time among active markers; direction comes from the
picked marker.  Default: `[5, 8, 12, 20, 30, 50, 80]` —
seven progressively-larger waves.

This is a **placeholder** for the eventual economy-driven
model (see § Future expansion): waves stop being authored and
become *output of* the robot economy state — supply lines
deliver, factories fabricate, mines fuel.  Players can alter
the economy to thin the waves.

### Wave-1 triggers — walls or provocation

Wave 1 fires when **either**:

(a) The player has built **N walls** (`wave_1_wall_trigger`,
default 8) — the act of laying perimeter is the commitment.

(b) The player has driven onto a spawn marker that sits
≥ `wave_1_provocation_distance` hex (default 12) from the
core — touching it = poking the enemy.

Markers **very close** to the core never trigger; map authors
shape pacing by close (safe) vs far (provocation) placement.
Once activated, the wave list proceeds via its scheduler.

### Pre-walk visibility — the scramble decision window

When a wave begins, enemies **appear at their picked spawn
markers and stand visible** for `pre_walk_visibility_interval`
(default 5 s) before walking.  Active markers pulse during
this window.  This is the player's window to see what's
coming (how many, from which directions) and decide whether
to stand or scramble before any enemy has moved.

### No wave HUD

There is **no on-screen wave indicator at all** in validation
— no wave-number display, no inter-wave countdown, no banners.
The player discovers wave shape and timing by **moving around**
(scouting active spawn markers, watching which pulse) and by
**internally learning the rhythm** across plays.  Diegetic
principle applied uncompromisingly to waves: the in-world
signals (marker pulse + pre-walk visibility) are the entire
wave UI.

### Wave 7 cleared → free scramble

If the player clears the final wave with the core alive, they
enter a **free scramble phase**: no more enemies, so they can
ferry tower-tops at leisure and launch with full carry.  Most
plays won't reach the final wave — the curve is designed so
the scramble decision usually has to be made mid-list.  The
final wave being cleared is the "perfect run" outcome.

## 7. Combat dynamics

### Towers — pulsed laser, attack-count decay

All towers ship validation as a single type: **pulsed laser**.

- **Range** 15 hex (~20 m); LOS blocked by `wall_high` +
  `steep_rock`, not by `wall` (the tower peeks 1 m over a
  normal wall).
- **Fire interval** 1 shot/s; **damage** 10/shot.
- **Shot budget** 30 shots per charge; once spent, the tower
  **goes black** and stops firing — *decay is per-attack, not
  per-time*.  An idle tower in a quiet corner never decays.
  A tower covering a busy entrance burns through its budget
  fast.  Player repairs to refill the budget.

Tower top colour signals state at any zoom:

- **Red** = healthy, firing.
- **Black** = decayed or salvaged (uniform with body — instantly
  readable as "spent" from across the base).
- **Pink** = boosted (cost: player time only for validation —
  drive to tower, hold boost key; no points, no carried-top
  consumed).  Higher fire rate / damage / range while pink;
  reverts to red on duration end.

### Tower-top salvage — the scramble mechanic lived tactically

A tower's red top is a **detachable carry object**.

1. Player drives to a healthy tower, presses pickup → top
   detaches, tower goes black (stops firing); the red disc
   floats above the player vehicle.
2. Player drives to a destination, presses pickup again.
   Two valid destinations:

   - **Another black tower** → top installs there, that tower
     goes red instantly (**fast repair**, consumed).
   - **The core building** → top added to **scramble
     inventory** for the next base (per Q4 closure: future
     model has specialised tops + a limited-loadout pre-mission
     pick from the persistent station inventory; validation
     places no effect yet).

The same disc, two mutually exclusive uses, decided every
sortie.  The scramble decision lived inside every combat run.

### New towers via beacon ferry

To order a new tower, the player **carries a tower beacon
from the core to the chosen build site**:

1. Drive to the core's **tower-core retrieval face**, press
   pickup → points debited from wallet, beacon spawns above
   vehicle.
2. Drive to the chosen 7-hex centre, press pickup → beacon
   placed; a lander touches down on it; helpers handle any
   remaining construction time.

The single pickup/drop key handles all intentional carries
(beacon at core, tower-top at healthy tower, deposit at
target).  Loot drops are auto-pickup on drive-over (too cheap
a decision to need an explicit press).

### Future tower types (deferred)

Validation ships the placeholder laser only.  Future tower
variants are **unlocked content** — found on the map through
scouting, brought back to the core, become orderable from
then on.  Different types specialise (anti-insect pulse,
anti-elemental dampener, anti-comms-priority disruptor,
area-effect splash, …; exact catalogue TBD).  See
[§ Economy + progression](#13-economy--progression).

### Enemy targeting + nibble

Enemies have **nibble** (damage-per-second melee) when they
reach a target.  Target priority (highest first):

1. **A player or NPC physically blocking the path to the
   core** (conditional damage — see [§ Player vehicle](#8-player-vehicle)).
2. **The core itself** (via entrance / broken wall) —
   drains the player's wallet, not the core's HP.
3. **The nearest wall hex** when no path through exists —
   slow attrition that eventually breaks the wall.

In the absence of a blocker, the player and NPCs are
**ignored**.

### Boss = mobile REPAIR PLATFORM (phase 3)

The boss class is, in the fiction, the **engineering / repair
role** in robot society (SETTING.md § Robot diversity) —
heavy industrial machinery, 2×2 footprint, **not a combat
unit**.

Its primary phase-3 mechanic: **heals nearby damaged regulars
over time** (range 3 hex, default 5 HP/s per repaired unit).
Killing the boss stops the heal pool — high-priority target.

Secondary phase-3 behaviours:

- **"Guard me" command** to nearby regulars (formation play).
- **Localised tower-attack retaliation:** towers that fire on
  the boss are *marked*; regulars in the boss's immediate
  communication vicinity (short range — the boss locally
  overcomes the scrambler) re-target marked towers.  Boss
  itself never attacks towers; stays focused on the core.

Player tactics: isolate the boss from escorts to cut the
order chain; salvage tower tops to silence specific towers
and keep them unmarked.

2×2 footprint **cannot fit through 1-hex entrance gaps** —
boss must use a 2-hex+ gate or **break the wall** to make
its own path.  Wall topology becomes a tactical lever against
bosses specifically.

Until phase 3 ships, towers cannot be damaged by enemies at
all.

## 8. Player vehicle

### Role — noncombatant manager

The player vehicle **cannot harm enemies** (no weapon) and is
**not hunted by them** in the general case.  Combat is
entirely between **towers and enemies**; the player
choreographs.  Their actions: positioning, timing of repairs /
boosts, ordering towers + helpers, salvaging tops, force-
launching.

This makes the player a **noncombatant base manager**, not a
gunner.

### Conditional damage — blocker exception

The only exception: if a player vehicle (or NPC helper) is
**physically blocking an enemy's path to the core**, the enemy
attacks the blocker instead.  The blocker takes nibble damage
until it moves out of the way (or is destroyed).

Consequences:

- The vehicle **cannot tank** for the core — parking in front
  of the core just makes enemies attack the player en route.
- Genuine accidental obstruction (helper standing in a narrow
  entrance, idle player parked across a kill funnel) becomes
  a *liability*, not a defence.
- The vehicle has a minimal damage model that **activates
  only by positioning choices**.

### Hover + boost

Vehicle hovers at `hover_clearance_idle` (default 0.4 m) above
the local terrain max under its footprint — rides over
terraced cliffs without clipping.

**Boost** (held key) lifts to `hover_clearance_boost` (default
3 m) for a fixed duration (default 2 s).  While boosting,
the vehicle ignores ground-slope constraints (can cross
`steep_rock`, walls, closed perimeters).  Landing on
descent is **automatically softened** — no damage from the
height drop.  Cooldown ~5 s before next boost.

### Paint-mode tint

When wall-paint mode is **on**, the vehicle body tints
red-near-white (placeholder `#e09090`); off, near-white
`#f0f0f0`.  Diegetic indicator — no HUD icon needed.  The
appearance of wall outlines while driving confirms.

### Respawn at core

When the vehicle's blocker-damage HP reaches 0, the player
**respawns inside the core** — which immediately starts the
launch countdown (see [§ The core § Force-launch](#force-launch--drive-in-hold-exit-to-cancel)).
Drive out the opening to cancel and continue; stay to ratify
the scramble.  Vehicle "death" is never a game-loss.

## 9. Helpers

NPC vehicles that do the cooperative's actual work.  Same
chassis as the player, **silver-grey** body, black front
(same facing convention).  No combat role.

### Roster

**2 starting** (emerging from the core's lift-off face on
landing), **6 maximum** (hard cap).  Helpers can be ordered
mid-mission at the core's NPC-ordering face (cost 100 points
per helper); a lander touches down at the lift-off face
~20 s later.

### Future skills

Eventually each helper carries a **per-character skill
profile** (validation: interchangeable, opaque id):

- **Building** — faster wall / tower construction.
- **Mining** — gather raw materials from terrain hexes.
- **Scouting** — faster movement / wider visibility.
- **Hacking** — (a) subvert enemy structures (planet meta);
  (b) hack enemy **robots directly** in combat (disable /
  redirect / convert).  Robot enemies are hackable; insects
  / elementals are not.
- **Engineering** — faster repair + boost on towers.
- **Crafting** — produce items from gathered materials.

Data model carries the per-helper id today so future skills
hang off existing characters without re-engineering.

### Damage → wreck → retrieve → recover

Helpers take damage in the same edge cases as the player
(blocking + phase-3 boss consequences).  When a helper
vehicle is too damaged:

1. Helper vehicle **wrecks at its hex**.  Helper inside is
   **downed but alive**.  Visible as a damaged silver-grey
   cuboid; mid-task work (carried loot, partial structure)
   freezes for another helper to resume / pick up.
2. **Retrieval** — player or another helper drives to the
   wreck + presses pickup → downed helper becomes a carry
   object floating above the carrier.  Deliver to the core →
   recovery state for ~60 s → helper rejoins the roster.
3. **No automatic respawn** — retrieval is the only way back.

### Stranded helpers — future rescue quests

A downed helper **not retrieved by force-launch** is
**stranded** at their wreck hex.  They are not lost
permanently — they become a **rescue-quest target** for the
same player on a later run, or (multiplayer) for a different
player who lands nearby.  Persists with the abandoned-bases
mechanic (§ Future expansion).  For validation: stranded is a
data state only; the rescue-quest UI is deferred.

### Carry visibility — universal rule

Anything a helper (or the player) is carrying — loot cube,
tower-top, beacon, downed helper — is **rendered above the
carrier as part of its geometry**.  No HUD; the world reads
loaded vs idle at a glance.

## 10. Three enemy tiers

Tiers **stack** rather than replace.  Each is a distinct
interaction loop the player can engage with or avoid.  Full
fiction + per-tier behaviour in
[`SETTING.md`](SETTING.md).

| Tier | Kind | Default state | Trigger to engage | Counter |
|---|---|---|---|---|
| 1 | Robots (haywire) | Territorial — react to encroachment | Encroach on their factories / mines / supply lines (future) | Walls + towers; hackable by helpers (future) |
| 2 | Insects | Passive (fly among trees) | Gather sap (smell tracking) | `wall_high` blocks; outrun delivery; or skip sap |
| 3 | Elementals (4 kinds: water / fire / wind / earth) | Dormant — keyed to stone proximity | Author-placed stones near them; disturb a gem | TBD (deferred); player-stone interactions open by design |

**Boss (phase 3)** sits within tier 1 — the repair-platform
specialist (see § Combat dynamics).

Robot wave behaviour has a *lore* explanation that retroactively
explains the wave system: **robots in the bubble are
comm-cut and individually drawn to the scrambler tower trying
to "find their way home"**.  Waves are accumulating cut-off
units, not coordinated attacks.  The approach→engage handoff
is the **bubble boundary itself**.  Full explanation in
SETTING.md § Why waves happen.

## 11. Movement + input philosophy

### Position triggers, not key presses

The player should *feel* they activated something through
**motion**, not by typing.  Most actions are **bumping into
things** (drive into the core = force-launch; drive over loot
= auto-pickup; drive to a tower = pickup / deposit / repair /
boost) or **leaving trails** (driving with wall-paint mode on
marks the trail as walls for helpers to construct).

Key presses are reserved for *mode toggles* and the rare
intent that has no spatial form.  Design new mechanics in
spatial terms first.

### The handful of keys

| Key | Action |
|---|---|
| **WASD** | Move |
| **E** | Pickup / drop (single key, context-resolved: empty hands = pickup, carrying = deposit) |
| **Q** | Wall-paint mode toggle (acknowledged exception to the spatial principle; no clean spatial alternative surfaced — the wall-trail mode flip is keyed) |
| **Shift** | Boost (held; context: vehicle while moving, tower while adjacent) |
| **Tab** | Editor mode toggle (ground ↔ marker) |
| **1-0, -** | Palette select (editor) |
| **Esc** | Cancel / menu |
| Mouse / right stick | Reserved for UI clicks (landing-spot pick, editor click, map markers); **NOT camera orbit** |

Full mapping in
[`../examples/numbers.json`](../examples/numbers.json) §
`input`.

### Wall paint — trail outline + erasable

While paint mode is on, each hex the vehicle traverses gets a
flat red wall outline.  Re-driving over an outlined hex erases
the outline (only valid while no helper has started building —
construction commits the order).  The vehicle's body tints red
while paint mode is on (diegetic indicator).

## 12. Camera + HUD

### Camera — over-the-shoulder, locked, auto-reframe

Camera sits ~3 m above and ~5 m behind the vehicle with a
slight forward pitch.  **Locked in pose — no mouse orbit.**

Auto-reframes on two triggers:

- **Sudden vehicle movement** (sharp turn, boost start) —
  smooth swing to maintain framing.
- **Terrain blocks line-of-sight to the vehicle** (wall,
  `wall_high`, `steep_rock`) — smooth swing to a position
  that can see the vehicle.

Swing easing ~0.5 s — reads as "the camera adjusted," not
teleported.

Visible radius bounded by `atmosphere_haze_radius` (see
[§ World](#3-world)).

### HUD — diegetic + minimal numeric

Most game state is shown in the world:

- Tower state (red / black / pink top), NPC order status
  (core's top colour), launch countdown (core's bottom
  pulse), wave incoming (spawn markers pulse), what's carried
  (object floats above carrier), construction progress (wall /
  tower grows out of the ground), wall outline (red outline
  on hex), stranded helper (damaged silver-grey cuboid at
  wreck), paint mode on (vehicle body tinted red).

Numeric / state HUD reduced to the bare minimum:

- **Wallet** (points) — one corner number.  The only number
  the player must see to make build decisions.
- **Active palette entry** (editor only) — swatch + name
  highlight.
- **Paint-mode on/off** — *vehicle tint is the primary signal;*
  small icon optional.

That's the entire HUD.  No wave-number, no inter-wave
countdown, no minimap, no boost cooldown bar.

## 13. Economy + progression

### Currency — points

**Points** are the wallet currency, earned from enemy salvage
(loot drops on death; the player picks up by driving over, or
helpers carry to the core).  Loot value: 10/regular,
50/boss.

Points spend on **two things**:

- **Tower orders** (100 pts each) — at the core's tower-core
  retrieval face.
- **Helper orders** (100 pts each) — at the core's NPC-order
  face; hard cap of 6.

Walls (both heights) and **bridges between walls (future,
phase 2)** are **free in points** — helper-seconds is the
bottleneck.  Same economics for both wall heights.

### Starting budget + 1:1 carryover

Every base begins with a **points budget** (default 200) the
player can spend before / during wave 1.  On subsequent bases
(post-scramble), the budget = baseline + **the player's
unspent wallet at scramble time** (1:1 carry).  Unspent points
that the player did NOT manage to bring onboard at force-
launch are forfeit (mirrors the abandoned cargo rule).

### Tower-top loadout (future — Q4 closure)

Tower-tops carried to the core at scramble accumulate in a
**persistent between-mission inventory** at the cooperative's
rented spot on the station (see [§ Meta-game hub](#16-meta-game-hub)).
Each top is **specialised** by gun / ammunition type (anti-
insect pulse, anti-elemental dampener, anti-comms-priority
disruptor, etc.; future catalogue).

Before each next mission the player **selects a limited
number** of tops from inventory to load into the rocket.  That
selection is the mission's available top pool.  Tops not
selected stay at home for future missions.  Picking the
loadout is the meta-game.

Validation tier: mechanic carries (tops collected, parked at
core, survive launch), but the **effect on the next base is
placeholder** — no in-mission effect yet.

### Scouting — the primary discovery loop

The player's main path to **special materials, upgrades, and
new tower types** is **scouting**: driving out beyond the
haze radius into the unknown to find them.  This makes
scouting *the* progression activity (not building, not combat)
and motivates the helper scout skill.

**Every reward has its own pressure:**

- **Sap** (from huge trees) → **invites insect chase by
  smell**.
- **Special gems** (associated with elementals) → **awakens
  matching elementals**.
- **Future kinds** carry their own triggers (each authored
  per map).

Scouting is a **bet**: every find is high-value AND opens a
fight.  Stay near the core (no gains, low risk) vs push
outward (real rewards, real consequences).  Combined with the
bounded haze radius, every venture is a small commitment with
a known shape.

**New tower types via scouting.**  Validation ships only the
placeholder laser.  Future tower variants are *unlocked
content* — found on the map, brought back to the core, become
orderable from then on.

### Future expansion — orbital banking

Eventually the player will be able to **launch cargo pods
during play** (separate from the scramble rocket) — sending
materials / points to orbit and instantly banking them.
Distinct from the scramble: scramble takes the player + their
carry; the cargo pod takes resources, no exit.  A counter to
"stay too long and lose what you gathered."  Deferred.

## 14. Run structure

### No hard run-loss — the player decides

dryopea **does not have a fail screen.**  Every base ends with
the player launching the rocket — sometimes with full carry,
sometimes with almost nothing.  The next base always starts.
A run the player feels was *bad* is simply a run that produced
meagre carryover.  A *good* run produced a lot.  The
difference is felt across the sequence, not announced by the
game.

Consequences:

- No "Game Over" screen, no forced exit from a run.
- The run is the **continuous sequence of bases the player
  chooses to play**; it ends only when they stop playing.
- Bad performance still produces *some* carryover (an empty
  wallet, no tops; the next base falls back to the fixed
  baseline starter loadout).

This retires the @PLAN46-original "core destroyed = run ends"
framing.  A "lost run" is the player's own judgment, not a
game state.

### Base sequence

A run is a **sequence of bases**, chained by what the player
carries out.  Each base is a permitted sortie down to the
planet; between bases, the cooperative returns to the central
space station (see [§ Meta-game hub](#16-meta-game-hub)) to
pick the next sortie + loadout.

### Bounded session

A single base must be a **bounded, one-sitting mission**, and
the boundaries between bases are **clean save-and-quit
points**.  The session target is ~15-25 minutes; this is the
*permit duration* in the fiction (SETTING.md § The premise),
not a soft preference.  The scramble exit is what gives the
player the graceful opt-out — bail out of a failing base, keep
your salvage, stop; resume the run later.

### Scramble exit + cargo manifest

The scramble (force-launch) is the **only confirmed exit**
through the cordon (SETTING.md § The quarantine).  At launch,
the cargo manifest is *whatever made it onboard*:

- The player's wallet (unspent points, 1:1 carry).
- Tower-tops the player deposited at the core.
- Helpers who'd boarded by liftoff (others left behind →
  stranded).
- Loot helpers had delivered to the core (not the carried-but-
  not-delivered ones).

Force-launch leaves stragglers behind — by design.  The cost
of haste.

## 15. Landing flow

The complete landing sequence:

1. **Map selection.**  Player sees a **static planet view**
   (validation teaser of the eventual rotating-planet hub —
   see [§ Meta-game hub](#16-meta-game-hub)) with one
   clickable marker per available map.  Clicks one.
2. **Landing-spot pick.**  Player clicks ANY hex on the
   selected map (within `landing_pick_edge_buffer` from the
   map's playable-area boundary).  Picking a lake centre or
   mountain summit is *allowed* — no up-front rejection.
3. **Rocket descent — auto-steers off invalid hexes.**  The
   rocket lands at a random hex within
   `core_landing_area_radius` (default 3 hex) around the
   pick.  If the candidate hex is invalid (water,
   `steep_rock`, painted-impassable) OR fails the 7-hex
   footprint + `obstruction_clearance_buffer` (default 2 hex)
   test, the algorithm searches outward for a valid landing.
   Visually diegetic — the rocket appears to choose safe
   ground.
4. **Random rotation.**  The core's six faces (lift-off /
   tower / NPC / 3 plain) point at arbitrary hex directions.
   Acceptable because no walls exist yet at landing; player
   adapts.
5. **Close-spawn auto-disable.**  Spawn markers within
   `close_spawn_disable_radius` (default 10 hex) of the
   landed core are **silenced for the mission** — still
   visible as map atmosphere; produce no enemies.  Map
   authors guarantee enough markers survive (~4-6 spread
   across a starter map).
6. **Starter tower lands.**  A separate lander touches down
   5-10 hex from the core in a random direction, **already
   standing + firing-ready.**  This is the free defensive
   guarantee that prevents wave-1 deadlock.
7. **Helpers emerge.**  Two NPC helpers exit through the
   lift-off face within 2-3 s of landing.
8. **Player gains control.**  Wallet = starting budget +
   carried-over points from previous run.  Pre-wave window
   begins.

Wave 1 fires when either trigger satisfies (see [§ Spawn
system + waves § Wave-1 triggers](#wave-1-triggers--walls-or-provocation)).

## 16. Meta-game hub

### The central space station

Between sorties, the player's cooperative lives at a **shared
orbital space station** outside the planet's cordon.  The
cooperative **rents a spot**.  The rented spot holds:

- **Persistent inventory** — tower-tops carried out of past
  missions, points unspent, blueprints recovered through
  scouting, materials brought back.  Stranded helpers
  awaiting rescue are listed here too.
- **Pre-mission loadout selection** — the player picks from
  inventory which specialised tops to take down (the Q4
  limited-loadout pick).
- **Future shopping** — vendors / fabricators / brokers sell
  gear that doesn't exist in the cooperative's existing
  inventory.  Carry-out points become spending power.
- **Future shipping outward** — selling carry-outs, sending
  cargo to other clients, traveling to other quarantined
  sites or unrelated jobs.  The cooperative's business is
  *not* limited to this one planet.
- **Permit administration** runs through the station.

Tone: shared / working-class orbital, not the player's; other
operators visible; cordon battleships visible from observation
viewports.

### The rotating planet UI (future)

The long-term replacement for the abstract map-selection menu:
a **diegetic view of the planet** from the station's
observation deck.  Planet rotates below; day / night
terminator moves; information projected on the surface
(previous landing sites, abandoned bases fading
green-to-red over time, intel hotspots, faction territory
hints).  Player **clicks directly on the rotating planet** to
pick a sortie destination.

**Validation already ships a static teaser** — placeholder
sphere with one clickable marker per available map (plan 04
L3).  No rotation, no projected data — just planet + markers
+ click.  Sets the visual tone before the meta-game state is
implemented.

The full rotating version ships when multi-mission run state,
persistent surface, and the planet-scale meta from §
[Future expansion](#20-future-expansion) are in place.

## 17. Moddability

dryopea is open source (LGPL-3.0-or-later) and aims to let
other developers and players **mod the game immediately**
without rebuilds.  This shapes design + data choices
throughout:

- **All numerical values live in runtime config files** — see
  [`../examples/numbers.json`](../examples/numbers.json).
  Tuning damage / range / fire rate / budget / build time /
  scrambler radius / landing parameters is a config edit,
  never a code change.
- **All content lives in editable data files** —
  [`palette.json`](../examples/palette.json) (ground types),
  [`waves.json`](../examples/waves.json) (wave schedules),
  maps as JSON under `maps/` (plan 04), the future tower-type
  catalogue, etc.  Adding a new ground type, weapon variant,
  enemy stat block, or starter map is a data edit.
- **The in-game editor IS the modding tool.**  Players who
  want to create new maps do so in the same binary they play
  in.  Authoring is end-user; no separate developer
  toolchain.
- **Anti-mod choices are out of bounds** — no obfuscation, no
  signed-only content, no first-party content gates.  Save
  formats are stable and documented; data formats are
  text-first (JSON / loft literals) over binary blobs.

Net: a developer downloading the repo can change "tower fire
rate" by editing one line in `numbers.json` and re-launching.
A player can author a new starter map in the in-game editor
and share the resulting JSON.  Both are first-day-of-shipping
behaviours, not aspirational features.

## 18. Numbers

A coherent first-pass set covering every parameter is in
[`../examples/numbers.json`](../examples/numbers.json) (the
runtime config the game loads at startup) with
[`NUMBERS.md`](NUMBERS.md) as the overview + design-target
rationale.

Every value is **tunable** by the principle in [§
Moddability](#17-moddability).

## 19. Validation tier scope

The buildable goal.  In:

- **One base, one mission.**  No multi-mission run state
  beyond the wallet carryover.
- **Robots only** as enemies.  No bosses, no insects, no
  elementals.
- **One tower type** (placeholder laser).
- **One enemy type** (placeholder magenta cuboid regular).
- **One starter map** (hand-authored; plan 04 L4).
- **All systems wired:** editor + landing + waves +
  tower lifecycle + tower-top salvage + beacon ferry +
  helper roster + force-launch.

Out:

- Bosses (phase 3) and their repair / retaliation mechanics.
- Insects + sap (mechanics deferred; insects can appear
  visually as passive wildlife if useful).
- Elementals + gems (deferred).
- Tower variants (only placeholder laser).
- Robot diversity (all enemies identical).
- Helper skills (interchangeable).
- Tower-top carryover effect (mechanic carries; effect
  deferred per Q4).
- Stranded-helper rescue quests (data state only).
- Sap harvesting, gem collection.
- Multi-mission run state beyond wallet.
- Orbital banking, planet meta, multiplayer.
- Abandoned-base persistence.
- Rotating planet UI (static teaser only).
- Sound, animations beyond construction-rise.

These are tracked future-design items, not bugs to fix during
validation.  Full integration plan in
[`plans/future/05-validation-scenario/README.md`](../plans/future/05-validation-scenario/README.md).

## 20. Future expansion

The base-hopping run is the foundation.  The long-horizon
vision (recorded so the core design doesn't foreclose it):

- **Robot economy as wave source.**  Waves stop being authored
  set-pieces and become **output of** the robot economy
  state — supply lines deliver, factories fabricate, mines
  fuel.  Players push outward to **disrupt that economy**;
  fewer / weaker / later enemies are *consequences* of
  disruption.  This is also the wave-list retirement plan —
  waves.json is the placeholder.
- **Persistent planet map.**  Bases sit on a map of the
  planet.  Early bases are rural (easier); missions get
  much harder as players push toward the industrial
  heartland.  The escalating difficulty has an in-world
  cause.  The rotating planet UI (§ Meta-game hub) is the
  surface form.
- **Persistent abandoned bases.**  Scramble-and-leave bases
  *persist* on the planet with whatever wasn't evacuated.
  Mobs encroach over time.  Revisiting (same player or
  another) inherits the leftover resources AND the gathered
  threat.  Same risk/reward tension as the scramble, scaled
  to the whole world.
- **Multiplayer.**  Multiple players operate on the same
  planet — coordinated economy disruption + abandoned-base
  rescue + shared-territory missions.  Reuses loft's shipped
  netcode (`lib/server` + `lib/web`).
- **Three concentric truths about the cordon** (SETTING.md):
  public AI-contagion story, military naval-blockade
  reality, hidden faction-escape-rocket fact.  A player who
  discovers the truth holds future-content leverage.

Architectural notes (so the core build leaves room): keep
base state self-contained (already true: terrain + structure
+ run state); the per-base game is the **unit** the planet
campaign composes; abandoned-base derivation is cheap (state
+ timestamp + on-demand encroachment compute), no live
simulation needed.

## 21. Open questions

The design has settled almost everything.  A small residue:

1. **Liftoff visual transition.**  After T = 0, does the
   camera follow the rocket up + fade to the inter-mission
   screen, or a clean cut?  Settle in build.
2. **Multi-level pathing representation** (from @PLAN46
   open Q #1).  How the ground + wall-top + bridge-deck
   graph is stored and queried — per-hex walkable-surface
   list, the `cy`-layer model directly, or something else.
   Resolve when D2 / plan-level pathing lands.
3. **Lib vs game boundary** for the override layer +
   multi-level pathing (from @PLAN46 open Q #5).  Stays in
   dryopea until a second consumer appears.

Everything else routes back to a settled rule or a defaulted
value in `numbers.json`.

## See also

- [`SETTING.md`](SETTING.md) — fiction.
- [`GROUND_TYPES.md`](GROUND_TYPES.md) — palette.
- [`PROXY_ART.md`](PROXY_ART.md) — proxy geometry.
- [`NUMBERS.md`](NUMBERS.md) +
  [`../examples/numbers.json`](../examples/numbers.json) —
  runtime parameters.
- [`DESIGN_HISTORY.md`](DESIGN_HISTORY.md) — design seeds
  from the 2023 prototype.
- Plans 01-05 in `plans/future/`.

---

## Appendix — Original @PLAN46 (2026-05-21)

The original design draft, preserved for traceability.
Decisions that have evolved since are recorded in the body of
this file above; this appendix is the *origin* document.

> **Note.** The "moros editor" framing in the editor/game-split
> table is **superseded** — dryopea owns its own in-game
> editor.  The "core destroyed = run ends" framing in
> § Scramble is **retired** — the core is invulnerable and
> there is no hard run-loss.  Other content remains broadly
> accurate; the body above is the canonical reference.

### Goal

A non-standard sci-fi tower-defence.  At the **start of a
match the player places their core building** — the thing
the enemies attack and the player must defend (lose it =
lose).  The player rides a **semi-floating vehicle** (over-
the-shoulder 3rd-person camera; it hovers above terrain to
avoid clipping cliff edges), and rather than placing
structures directly, **issues build ORDERS** — towers, walls,
bridges — that **NPC workers** then construct over time.
The player reacts in real time: repairing and buffing towers
as enemy waves and a boss approach, and **travelling the
landscape** to find hidden treasures that speed up upgrades.
Walls are **≥1 hex wide and walkable**, so the vehicle can
drive along them to reach the core under attack; **bosses
can break walls**, severing those routes and re-opening the
enemy path.

What sets dryopea apart from every other tower-defence is
the **scramble phase**: a base is never a simple
win-or-lose.  When it's about to be overrun, the player
fires a rocket out of the core building, **evacuating key
components** to start the *next* base with an advantage.
The game is a **run** of bases, strung together by what you
manage to carry out.

### The scramble phase — the signature mechanic

dryopea's identity.  A base is **not** win-or-lose-forever;
it's one round of a longer **run**.  When a base is about to
be overrun, the player can **scramble** — fire a rocket out
of the core building and evacuate to the next base.

- The core building is also the escape rocket.  *(Retired:
  the core is invulnerable; the run does not end on its
  destruction.)*
- Salvage is a live tradeoff.  Evacuating a key component
  takes it with you but **disables the tower it came from**.
- Carry-over → the next base starts ahead.  A run is a
  **sequence of bases**, each a TD round, chained by what
  you carry out — a roguelike structure rather than a single
  defended base.

### Design principle — bounded sessions (the rogue-lite opt-out)

A single base must be a **bounded, one-sitting mission**, and
the boundaries between bases must be **clean save-and-quit
points**.  This is a first-class design constraint — and a
deliberate strength — see [§ Run structure](#14-run-structure)
for the canonical version.

### The editor / game split (architectural spine)

The original framing was: editor authors only TERRAIN; the
running game places everything else.  The editor was meant
to be the moros editor.

**Superseded by 2026-05-26:** dryopea owns its own in-game
editor (plan 01), and structures (walls, towers, the core)
are no longer placed solely by build orders — walls are
painted by the player via a trail mechanic, towers via the
beacon ferry, the core by the rocket landing.

### Systems (game-specific scope)

The original numbered system list is reorganised in the body
above (sections 4-14).  See § The core, § Spawn system + waves,
§ Combat dynamics, § Player vehicle, § Helpers.

### Phases (vertical-slice first)

D0-D5 from the original phase plan are subsumed into the
validation tier (D0+D1+D2+D3 minimal) and § Future expansion
(D4 economy, D5 scramble).  Validation success criteria are
in [`plans/future/05-validation-scenario/README.md`](../plans/future/05-validation-scenario/README.md).

### Dependencies + shared primitives

- **lib-plan 20 terrain height-map** — currently a loft
  tracker plan; will migrate to its own repo when loft drops
  outside-project references.
- **lib-plan 19 gridmesh Phase C** — same.
- *moros editor — superseded by dryopea's in-game editor.*
- **Likely needs:** A*/flow-field pathfinding over the
  multi-level hex graph; an entity/update loop.

### Open questions (from the original draft)

The original list of five open questions is largely closed
or migrated to [§ Open questions](#21-open-questions) above.
The two surviving items (multi-level pathing representation,
lib vs game boundary) appear there.

### Future expansion — planet-scale enemy economy + multiplayer

Documented above in [§ Future expansion](#20-future-expansion).
