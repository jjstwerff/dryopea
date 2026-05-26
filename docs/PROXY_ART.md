<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Proxy art — placeholder geometry for gameplay testing

This document records the **placeholder shapes** that stand in
for real art while dryopea's gameplay systems are being built.
Each entry exists for one reason: **a system needs to be testable
in-game before the art for it is ready**.

When real art lands for an entry, its row is moved from
**Active** to **Retired**, with a note pointing at where the
final art lives.

## Conventions

- **Primitive geometry first.**  Cuboids and cylinders unless a
  shape is *load-bearing for gameplay* (a wall section needs to
  read as a wall; a hill profile doesn't need to read as
  anything until lib-plan 19 meshes it).
- **Honest proportions.**  Always sized to the real game scale
  (DESIGN.md § World scale, hexes ~1.5 m).  Painting tests with
  the right footprint catches a class of "looks fine but won't
  actually fit through the gate" bugs.
- **Facing signalled by colour contrast, not detail.**  A black
  front face on an otherwise plain body is enough to read
  direction from any zoom; no headlights / eyes / antennae
  needed yet.
- **Body colour distinct from the
  [palette](GROUND_TYPES.md).**  Pick a hue that does NOT appear
  in the 11 ground types — so a proxy enemy is unambiguous
  against any terrain.  Magenta / purple `#a040c0` is the
  default proxy body colour; rotate to a different
  off-palette hue per entity class if more proxies are needed.

## Active proxies

### Enemy — basic ground unit (first wave class)

The first enemies to be testable on a painted map.  Purpose:
**validate movement** — flow-field guidance through wall
entrances, slope-gated traversal, vehicle-vs-ground-mob path
differences.

| Property | Value |
|---|---|
| Shape | Cuboid (long box) |
| Length (along facing axis) | **~2.7 m** — slightly under 2 hexes (`< 2 × 1.5 m`) |
| Width (across facing axis) | **~1.3 m** — slightly under 1 hex (`< 1.5 m`) |
| Height | **1.0 m** — short enough to fit under walls visually, tall enough to read from the 3rd-person camera |
| Body colour | `#a040c0` (placeholder magenta-purple) |
| **Front face colour** | **`#000000` (black)** — the only side with a different colour; reads as "this is the front" at any zoom |
| Other 5 faces | body colour, flat shaded |
| Origin / pivot | centre of the footprint (so rotation around the central hex axis is natural) |

**Why these dimensions.**

- **< 2 hexes long:** a single enemy occupies *roughly* one hex
  but spans into an adjacent one when in motion, which exercises
  the multi-hex collision + flow-field sampling path (an
  enemy's "current hex" is its centre, but its body touches
  neighbours — important for the entrance-detection mechanic in
  [GROUND_TYPES.md § Entrances](GROUND_TYPES.md#entrances--two-wall-ends-near-each-other),
  where a 1-hex gap is a tight squeeze and a 2-hex gap is roomy).
- **< 1 hex wide:** lets two of them pass each other in a 2-hex
  gap or stand abreast in a 2-hex-wide column.  Forces the
  player's entrance design to *matter* — a 1-hex gap funnels
  enemies single-file, a 2-hex gap lets them flood.
- **Black front:** the moment you can see which way an enemy is
  *pointing*, you can see whether the flow-field actually turned
  it toward the core or sent it past — visual debugging for the
  AI is free.

**What this is NOT yet.**

- No animation rig, no movement bob, no projectile, no death
  animation.
- No faction colour variation.
- No size tiers (boss enemies, fast scouts, etc.) — those are
  later proxies (with their own off-palette colours).
- No top decoration — the user can tell it's an enemy because
  it's the only off-palette purple thing on the map; no need
  for a faction icon.

**Lifetime.**  Retire when actual enemy art lands.  The proxy
sits in the game's render path; final art replaces it 1:1 (same
hex footprint, same pivot, same facing convention).  No
gameplay-side changes when art arrives.

### NPC helper — grey version of the player

The autonomous construction + salvage unit (DESIGN.md § Systems
#2 + § Updates 2026-05-26 on salvage).  Purpose: **validate the
auto-build flow + the loot pickup path** with the cheapest
possible visual differentiation from the player.

| Property | Value |
|---|---|
| Shape, size, hover behaviour | **identical to the player vehicle** below (~2.4 m × 1.1 m × 0.9 m, ~0.4 m hover clearance) |
| Body colour | **`#c0c0c0`** (silver-grey) — clearly a "grey version of the player white"; distinct from terrain greys (`rock` `#b0b0b0`, `steep_rock` `#555555`) by hue lightness and by virtue of being a moving vehicle, not a hex tile |
| Front face colour | `#000000` (black) — same facing convention as player + enemy |
| Boost capability | **none** (workers stay on-task; only the player boosts) |

**Why a colour-swap proxy, not a different shape.**

- The player and the worker share **all** the same locomotion
  primitives — hover, path, climb-the-same-slopes, ignore-water,
  same-vehicle-footprint-rules.  Same code path; only the
  *driver* differs (player input vs path-following AI).
- A separate shape would imply separate behaviour; the
  colour-swap honestly signals "this is a player-shaped thing,
  controlled by the game."  When workers get real art later it's
  free to diverge; the proxy doesn't pretend otherwise.

**Helper behaviour (gameplay, captured here so the proxy can
exercise it).**

- **Build orders** — when the player marks a structure
  (wall / wall_high / tower) for construction, idle helpers
  path to the build site and apply construction ticks until
  the structure is complete (DESIGN.md § Systems #2).
- **Salvage path** — when an enemy dies, loot appears on its
  death hex.  Idle helpers path to the nearest loot, pick it
  up, and carry it back to the core building.  Loot delivered
  to the core becomes the **upgrade resource** pool (DESIGN.md
  § Systems #6).
- **No combat role** — helpers do not fight.  They are
  noncombatants; if enemies reach them, they die without
  resisting.  The player decides whether to defend helper
  paths or let them run risk.

**Carry visibility — same rule as the player.**  Anything a
helper is carrying — loot cube, tower-top, beacon, future
carry objects — is **rendered above the helper as part of its
geometry**.  At a glance the player can see which helpers are
loaded vs. idle without any HUD: an NPC walking back toward the
core with a gold cube floating above it is visibly carrying
loot home; one en route to a build site with nothing above is
visibly going to work.

### Tower beacon — carry object for placing new towers

The carried order ticket the player ferries from the core to a
chosen build site (DESIGN.md § Updates 2026-05-26 on beacon
ferry).  Purpose: **make tower placement physical** — the
player drives the order to its destination, rather than
"clicking a hex from a menu."

| Property | Value |
|---|---|
| Shape | Short vertical cylinder ("pylon" / "tent peg") |
| Diameter | ~0.5 m |
| Height | ~0.8 m |
| Body colour | `#d04848` (same placeholder red as the tower top — the carry signals "this becomes a tower") |
| Position when carried | floats above the vehicle, same slot as a carried tower-top (gentle bob); only one carry-slot — the player can't carry a beacon AND a tower-top simultaneously |
| When placed | the beacon stays at the deposited hex visually for the moment between drop and lander arrival; then the lander touches down on it and the beacon is consumed |

**Pickup at the core:** drive adjacent to the core, press the
single pickup/drop key.  Costs points (debited from the
wallet immediately at pickup).  If the wallet is short, pickup
fails (no beacon spawns; the press is a no-op).

**Deposit at the build site:** drive to the chosen 7-hex
centre, press the same key.  A tower lander is summoned to that
hex; the beacon is consumed.  If the chosen spot is not
buildable (water, steep_rock, occupied), deposit fails — the
beacon stays carried, no points are returned.

**Always visible on screen.**  The carried beacon (and any
other carry object — tower-top, future beacons of other kinds)
is **rendered as part of the vehicle** in the 3rd-person view,
so the player can never lose track of what they're holding.
There is no separate "carried inventory icon" HUD — the carry
is part of the world geometry and stays in frame because the
camera follows the vehicle.

### Loot drop — proxy collectible

When an enemy dies it leaves a **loot marker** on its death hex.
Visually:

| Property | Value |
|---|---|
| Shape | small upright cube |
| Size | ~0.4 m on a side (clearly visible on a 1.5 m hex) |
| Colour | **`#ffd000`** (bright gold) — off-palette, signals "pick me up" |
| Behaviour | sits stationary at the death-hex centre; despawns when picked up |
| Pickup rule | player drives over → instant pickup, points credited; OR worker delivers to core → points credited there |
| Despawn | if not collected within a generous timeout (e.g. 60 s), the loot vanishes (anti-clutter; tunable) |

Open question: pickup priority when player + worker race for the
same loot.  Lean **player wins** (player presence at the hex
trumps worker AI), with the worker reverting to "look for the
next loot" automatically.

### Player vehicle — the over-the-shoulder hover unit

The thing the player rides (DESIGN.md § Systems #1).
Purpose: **validate vehicle hover, the 3rd-person camera, the
boost mechanic, and movement-with-impact-protection** while
final vehicle art is years out.

| Property | Value |
|---|---|
| Shape | Cuboid (same chassis primitive as the enemy proxy) |
| Length | **~2.4 m** — slightly smaller than the enemy (~2.7 m) |
| Width | **~1.1 m** — slightly smaller than the enemy (~1.3 m) |
| Height | **~0.9 m** — flatter than the enemy (a more vehicle-like silhouette) |
| Body colour | **`#f0f0f0`** (near-white) — the universal "this is the player" colour |
| **Front face colour** | **`#000000`** (black) — same facing convention as the enemy proxy; black = front |
| Hover clearance above ground | **~0.4 m** standard; up to **~3 m** while boosting |
| Origin / pivot | centre of the footprint, at terrain height (vehicle position interpolated above) |

**Why these dimensions.**

- **Smaller than the enemy** in every axis — at a glance the
  player is the *agile* one; the slight size delta is enough to
  read.  Doesn't matter what colour the enemy is; what matters
  is the player is consistently *smaller and brighter*.
- **Same front-face convention** (black) means the player and
  enemies share a single facing rule.  When testing the AI's
  flow-field guidance, you can compare the enemy's pointing
  direction to the player's reference at a glance.
- **Hover clearance ~0.4 m** is the *visible* baseline (sits
  noticeably above the terrain even on flat ground, so you can
  see it isn't a ground unit).

**Combat role — none.**  The player vehicle **cannot harm
enemies** and is **not hunted by them** in general either.  No
weapon, no ramming damage, no melee.  In normal play enemies
ignore the vehicle in targeting (the player is invisible to
their AI); the vehicle can drive *past* enemy formations
without taking or dealing damage.

This makes the player a **noncombatant base manager**:
positioning, timing of repairs / boosts, where to place
towers and helpers, when to salvage tops, when to force-launch.
Combat itself is entirely between **towers and enemies**; the
player choreographs but does not fight.

**Conditional damage — blocking access to the core.**

The "enemies ignore the player" rule has one exception.  If the
player vehicle (or an NPC helper) is **physically blocking an
enemy's path to the core building**, the enemy attacks the
blocker instead of the wall / core it can't reach.  The blocker
takes nibble damage until it moves out of the way (or is
destroyed).

Implications:

- The player **cannot use the vehicle as a tank** to soak hits
  for the core — parking in front of the core does NOT pull
  enemies off it; it just makes the enemies attack the player
  *en route* to reaching the core (the enemy nibbles through
  the blocker).  Same for helpers.
- Genuine accidental obstruction (a helper standing in a narrow
  entrance corridor, an idle player parked across a kill funnel)
  becomes a *liability*, not a defence.  Player movement
  discipline matters even though the player is otherwise
  invulnerable.
- The vehicle therefore *does* need a minimal damage model —
  but it's **inactive in the common case** and **activated only
  by player positioning choices**.  Settle the exact HP /
  destruction-on-zero behaviour in plan 04 alongside the
  starter-loadout decision.

**The base must START armed.**  With the player unable to fight
in the general case, a validation scenario that begins with zero
towers and zero points DEADLOCKS on wave 1 — enemies walk to the
core uncontested.  The validation scenario therefore needs a
**starter loadout** (likely one free pre-placed tower + 1-2
helpers + zero points; settle in plan 04).

**Movement mechanics** (gameplay, not just art — captured here
because the proxy must visibly demonstrate them):

- **Hover** — the vehicle's bottom face sits at
  `local_terrain_height(footprint) + clearance` where the
  height is the **max** over the footprint's hexes.  This is
  why it can ride over terraced cliffs without clipping
  (DESIGN.md § Systems #1).
- **Boost key — fly for a stretch.**  Pressing the boost key
  lifts the vehicle to ~3 m clearance for a short window
  (tunable — start at ~2 s sustained, with cooldown).  While
  boosting the vehicle ignores ground-slope constraints — it can
  cross over a `steep_rock` cliff, a wall, a closed perimeter.
  This is the OUTBOUND scramble / scouting mobility tool, and
  it's also how the player can recover from being trapped.
- **Automatic impact protection on the ground.**  When boost ends
  and the vehicle descends back through the clearance zone, the
  landing is softened automatically — no damage from the
  height-drop, no momentum penalty.  The player never has to
  *manage* landing; boost is a "go up, come down" lever, not a
  flight-sim discipline.

**Why these mechanics in the proxy doc.**  The player can be
fully tested with a white box if the BEHAVIOUR is right.  Art
can wait; the boost / landing curves need to feel correct first,
and that's a proxy-tunable.

**Lifetime.**  Retire when actual vehicle art lands (chassis +
wheels-or-thrusters + glowing-cockpit-equivalent + boost VFX +
damage state).  The proxy's hover clearance + boost height + soft
landing carry into final art unchanged.

### Tower — defensive structure (placed by build orders)

The defensive tower the player orders built around the core.
Purpose: **validate placement + flow-field interaction +
line-of-sight** before tower art lands.

| Property | Value |
|---|---|
| Footprint | **7 hexes** — a centre hex + its 6 neighbours (axial-radius-1 hex disc) |
| Footprint diameter | ~3.9 m flat-to-flat (3 hexes × 1.30 m per hex) |
| Shape | **Truncated cone** (cone frustum) — wider at base, narrower at top |
| Base diameter | ~3.9 m (matching the footprint) |
| Top diameter | **~1.7 m** — "slightly bigger than a tile" (1 hex ≈ 1.5 m flat-to-flat); a slight overhang above the surrounding terrain |
| Height | **~6 m** — slightly taller than the highest wall (`wall_high` = 5 m) so the tower peeks over it |
| Body colour | **`#1a1a1a`** ("almost black") — body stays this colour across all states |
| Top colour | **state-dependent** — see "Tower state visuals" below |
| Origin / pivot | centre hex of the footprint at terrain height |

**Tower state visuals.**

A tower's top reads its lifecycle state at any zoom:

| State | Top colour | Meaning |
|---|---|---|
| **Healthy** (just built or just repaired) | **`#d04848`** (red, matching wall placeholder) | Tower operates at standard fire rate; the default state. |
| **Degraded** (needs repair) | **`#1a1a1a`** (totally black — top *and* body now identical) | Tower has fired its **per-charge shot budget** and **stops firing**.  Decay is NOT time-based — an idle tower never degrades; only attacking does.  Player must visit and repair, then the top reverts to red and the shot budget resets.  Visually the whole tower goes uniformly dark, so a black-topped tower is instantly readable from across the base as "spent — needs restocking". |
| **Boosted** (player-buffed) | **`#ff80c0`** (pink) | Player has actively buffed this tower.  **Cost is player time only** for now — drive to the tower, hold a boost key for a short duration; no points spent, no carried-top consumed.  Higher fire rate / damage / range while pink (exact tunings TBD).  Reverts to red (healthy) when the boost duration expires.  The cost model is intentionally placeholder; later balance work may introduce a points or inventory cost. |

The **care loop** this enables:

1. NPC helpers build the tower → top starts red, tower fires
   normally.
2. Each shot the tower fires consumes one unit of a per-charge
   **shot budget**.  When the budget hits zero the top turns
   black and the tower stops firing.  An idle tower in a quiet
   corner of the base **never degrades**; a tower covering a
   busy entrance burns through its budget fast.
3. Player drives to the dark tower → repairs it (key press) →
   top reverts to red and the budget refills.
4. In critical moments (a heavy wave hitting an entrance, or
   defending the core during a scramble launch) the player can
   **boost** key-positioned towers → top turns pink → temporary
   peak performance.

The player is therefore *always* doing some maintenance pass +
strategic boost.  This is the "reactive player repair / buff of
towers" mechanic from DESIGN.md § Systems #5, made concrete:
**watch the tops**.

**Why attack-count, not time.**  Time-based decay punishes the
player evenly regardless of base activity — a quiet hour costs as
much repair as a hectic one.  Attack-count decay ties the
maintenance load directly to *where the enemy pressure is*: a
ring of towers around a busy entrance needs repair often; a row
of towers behind a closed wall (no shots fired) needs no attention.
The player's repair priorities **emerge from the geography of the
fighting**, not a uniform timer.

**Tower-top salvage — the scramble mechanic, made tactical.**

A tower top is a **detachable object** the player (or an NPC
helper) can pick up and carry.  This is the concrete form of the
scramble-and-salvage thesis (DESIGN.md § Scramble): the "key
component" you evacuate from a base IS the tower top, and
removing it from a tower disables that tower — exactly the
"weakening your remaining defence" tradeoff the design calls for.

Flow (player-initiated):

1. Player drives to a healthy tower, presses **pickup**.  The
   tower's red top detaches; that tower is now "topless" — its
   visual goes to the same dark / black state as a decayed
   tower (uniform `#1a1a1a`); it stops firing.
2. The detached top becomes a **carried object** floating just
   above the player vehicle (a flat red disc, ~1.5 m diameter —
   visibly the same disc that *was* the tower's top).
3. The player drives to a destination and presses **deposit**.
   Two valid destinations:

   - **Another black tower (decayed *or* topless).**  The
     carried top installs onto it → that tower goes red /
     healthy / firing again, **instantly** — much faster than
     the helper-rebuild repair path.  This is a **fast repair**
     using salvaged stock: swap a top from a quiet tower at the
     back to a hot tower at the front.
   - **The core building.**  The top goes into the core's
     **scramble inventory** — the cargo manifest for the next
     base (DESIGN.md § Scramble: "Evacuated components give an
     advantage at the next base").  This is the long-term play
     at the cost of permanently losing the tower it came from
     for the current base.

4. NPC helpers can perform the same flow autonomously when
   directed (auto-salvage tag on the source tower; helper picks
   up and delivers).  For validation, the player-initiated
   path is the priority.

**The tactical tension.**

The same carried disc has two completely different uses.  At any
moment, the player holding a top is choosing between:

- *Fast repair* (deposit at another tower) — *immediate*
  battlefield help.  The carried top is consumed; nothing
  carries into the scramble.
- *Stockpile* (deposit at the core) — *future* help.  The
  current base's defence is permanently weaker, but the next
  base starts ahead.

That choice is the scramble decision, lived **inside every
combat sortie**.  The player doesn't have to wait for the launch
moment to start trading current strength for future strength —
they're doing it constantly, hex by hex.

**Visual — carried top.**

| Property | Value |
|---|---|
| Shape | Flat disc (the same truncation-top disc that was on the tower) |
| Diameter | ~1.7 m (matching the tower top) |
| Thickness | ~0.2 m (a thin disc, not a sphere) |
| Colour | **`#d04848`** (red, identical to the source tower top) — so the same "red equals firepower" semantic survives intact |
| Position | floats ~1.5 m above the carrier vehicle's centre, slightly forward so you can read the carry pose at a glance |
| Animation | gentle bob (~10 cm amplitude) so it reads as carried, not painted-on |

**Why these dimensions.**

- **7-hex footprint** is large enough to be a serious commitment
  (the player can't carpet a base with towers); small enough that
  several fit inside a closed wall perimeter on a typical-sized
  base.
- **Peeks over the highest wall** by ~1 m — the top has a sight
  line over a `wall_high` rampart, which is necessary for the
  tower to shoot at enemies on the other side.  Drop this and a
  tower behind a tall wall becomes useless.
- **Top slightly bigger than a tile** is the *gameplay* readable:
  the tower's "business end" is visibly a one-hex platform, so
  the player intuits where the weapon sits without needing a
  separate turret model yet.
- **Cone shape** (vs cylinder) makes the body silhouette
  unambiguously a tower at any zoom, even with no detail.  Also
  hides any wall-corner clipping at the base.

**Data model — open question.**  Whether a tower is stored as
**one record** keyed at its centre hex (with an implicit 7-hex
footprint) OR as **7 painted-hex entries** under a `tower`
sub-palette is not yet decided.  Lean **one record**: multi-hex
structures don't fit the sparse `hash<GroundType[q,r]>` model
(painting a single hex doesn't make a tower; the 7 must move /
remove as a unit).  Settle this in plan 02 follow-on or in @PLAN46
D1's structure-layer design.

**Combat — placeholder laser weapon.**

All towers, regardless of future variations, currently fire the
same primitive weapon: a **pulsed laser beam** with an energy
recharge cycle.  This is the *one* offence mechanic until the
weapon system grows.

| Property | Value |
|---|---|
| Beam origin | tower's red top, centre of the truncation face |
| Beam target | a single enemy's centre point |
| Beam visual | thin straight line from origin to target, bright red (matching the tower top's `#d04848`), ~1 frame visible per shot |
| Range | **~15 hexes** (~20 m at 1.5 m hex diameter) — tunable |
| Targeting | nearest enemy in range with line-of-sight; line-of-sight blocked by `wall_high` and `steep_rock`, NOT by `wall` (tower peeks over a normal wall by ~1 m) |
| Fire cycle | **fire** (single beam, instantaneous hit, small damage tick) → **recharge pause** (~0.8 s, no beam) → repeat |
| Damage feedback | enemy proxy flashes briefly on hit; no health-bar visualisation yet |

**Why pulsed, not continuous.**

- A continuous beam reads as "perpetually killing things" — hard
  to balance, hard to see fire-rate problems.  A pulsed beam
  with a visible recharge gap makes the firing rate *visible*:
  the player can see "this tower is shooting too slow / too
  fast" without a debug overlay.
- The recharge pause is also the player's mental clock for
  *how many enemies the tower can stop per second* — useful for
  estimating defence strength against a wave.
- Pulse + recharge is the simplest "weapon" loop that exercises
  targeting, hit detection, damage, and reload — all four
  mechanics on one primitive, no fancy ammo / projectile-flight
  simulation needed.

**What this is NOT yet.**

- No tower variants (no slow-but-heavy, no fast-but-weak, no AOE,
  no air-vs-ground split).  One weapon for now.
- No projectile travel time — the laser hit is instantaneous.
- No upgrade / buff state (DESIGN.md § Systems #5's "reactive
  player repair / buff of towers" is a later mechanic).
- No firing arc / cone limit — the tower can shoot in any of 360°
  while LOS is clear.  Final art (a rotating turret) will impose
  arc limits naturally; for now any-direction firing exercises
  the targeting math at its broadest.

**Lifetime.**  Retire when actual tower art (with a recognisable
weapon mount, scaling damage state, faction trims, destruction
animation) lands.  Final art replaces it 1:1 (same footprint,
same height, same pivot).

### Core building — the defend objective + escape rocket

The base centre (DESIGN.md § Match setup, § Scramble).  Purpose:
**make the defend goal visible from any camera distance, with no
ambiguity about which structure is the special one.**

| Property | Value |
|---|---|
| Footprint | **7 hexes** — the centre hex + its 6 neighbours (same hex disc as a tower) |
| Shape | **Hexagonal prism** — an upright pillar with **6 distinct flat sides**, one per outer hex of the footprint.  Distinct from the tower's truncated cone in silhouette. |
| Diameter (flat-to-flat) | **~3.9 m** — matching the 7-hex footprint |
| Height | **~8 m** — taller than a max-decay tower (~6 m) so the silhouette reads core-vs-tower even when both are uniformly black |
| Body colour | **`#1a1a1a`** (uniform black) — placeholder per the simplification of 2026-05-26 |
| Top | flat hexagonal face — **dynamic colour** signals NPC-order status (see § Top colour signal below) |
| Origin / pivot | centre hex of the footprint |

**Why a hexagonal prism, not a cone.**

- **Shape distinguishes core from tower at any colour state.**
  A tower in salvaged or decayed state goes uniform `#1a1a1a`;
  a uniform-black tower would otherwise be visually identical
  to the core if both were cones.  Making the core a **prism**
  (vertical flat sides, no taper) keeps the silhouettes
  unambiguous even at silhouette-only zoom — the core is the
  rocket-pillar shape; towers are the cone-on-pad shape.
- **Six distinct sides** match the 6 outer hexes of the 7-hex
  footprint — so each face *is* a hex-aligned interaction
  surface (see § Six sides below).
- **Prism silhouette also reads "rocket"** in placeholder
  geometry without needing fins / nose-cone detail.

**The six sides — three functional, three plain.**

The hexagonal prism has 6 faces.  **Three of them carry a
function** (the player drives next to the corresponding outer
hex to interact); **three are visually plain** (the same flat
black surface, no markings, no interaction).  Per the spatial
philosophy: the function of a face is read from its position +
its visible icon, never from a menu.

| Face role | What the face does | Player interaction |
|---|---|---|
| **Output / lift-off** | The opening from which the rocket lifts off at scramble; new NPCs emerge here when delivered by a lander; landed loot / supplies arrive here | Force-launch trigger: drive *into* the core's footprint (any hex) — the launch animation plays from this face.  No pickup interaction at this face. |
| **Tower-core retrieval** | The face that dispenses **tower beacons** (the "core" of a future tower) | Drive next to this face's outer hex, press pickup → points debit, a tower beacon spawns floating above the vehicle (per the beacon-ferry rule).  Carry to a chosen build site to deposit. |
| **NPC ordering** | The face that accepts **helper orders** | Drive next to this face's outer hex, press pickup → points debit immediately; an NPC helper lander touches down on the lift-off face shortly after; the new helper joins the roster (no carry needed — helpers self-deploy). |
| Plain face × 3 | (no function) | None.  These are part of the structure and read as "normal tower wall." |

**Visual indicators.**

Each functional face carries a **distinct icon** (placeholder —
final art replaces with real signage / glow):

| Face role | Icon placeholder |
|---|---|
| Lift-off | **flame / chevron pointing up**, painted on the face in red `#d04848` |
| Tower-core retrieval | **small red disc** centred on the face (echoing the tower top + carried beacon) |
| NPC ordering | **small silver-grey rectangle** centred on the face (echoing the helper body colour) |
| Plain face | nothing — uniform black |

The three functional faces give the player a stable mental map
of the core ("the flame side is where things come out; the disc
side is where I get towers; the helper-grey side is where I get
helpers").  Walking the perimeter of the core teaches the
layout in ~5 seconds.

**Top colour signal — NPC order status.**

The core's flat top face is a **diegetic status display** for
the player's NPC order queue.  Visible from any distance / any
camera angle (the player almost always sees the top from the
3rd-person camera) → no separate HUD needed.

| Top colour | Meaning |
|---|---|
| **Black** (`#1a1a1a`, body uniform) | No NPC order is pending.  The roster is either at the cap (6) or no order has been placed since the last delivery. |
| **Red** (`#d04848`) | An NPC has been ordered but their lander is *far from arrival* — the long-wait band of the timer. |
| **Amber / yellow** (`#ffd000`) | The lander is *en route*; arrival is mid-way through its timer. |
| **Green** (`#4caf50`) | Arrival is *imminent* — the next few seconds. |
| **White flash** (~`#ffffff` for ~0.3 s) | The lander has just touched down at the lift-off face; the new helper emerges; immediately after, the top returns to black (or to the next-in-queue colour if more orders are pending). |

The colour **interpolates smoothly** between red → amber →
green as the order's timer ticks down, so the player can read
progress at any glance, not just at threshold crossings.

If multiple orders are queued, the top reflects the **next**
order's status; later orders queue up invisibly until they
become "next."  (Open Q: should there be a queue indicator
showing how many are waiting?  Lean **no** for validation —
keeps the visual simple; the player can just look at the helper
roster vs. the cap.)

**Open question — face orientation on landing.**

When the core lands at a random hex (DESIGN.md § Updates on
area-pick + random-within), does its **rotation** also
randomise (each face points at a random hex direction), or is
the rotation deterministic (e.g. lift-off face always points
"north" / away from the largest spawn-marker cluster)?  Lean
**deterministic, lift-off-faces-away-from-nearest-spawn** so
the player can't be unlucky and have the wrong face pointing
into a hostile sector; settle in plan 04 alongside the landing
algorithm.

**Lifetime.**  Retire when actual core building art lands (which
needs to include the rocket-launch animation — the core IS the
escape rocket, DESIGN.md § Scramble).

## Retired proxies

*(none yet)*

## See also

- [`GROUND_TYPES.md`](GROUND_TYPES.md) — the palette the proxy
  body colour deliberately avoids.
- [`DESIGN.md`](DESIGN.md) § World scale — the 1.5 m hex
  diameter that anchors proxy dimensions.
- [`../plans/future/02-solver-validation-viewer/README.md`](../plans/future/02-solver-validation-viewer/README.md)
  — the first place proxy enemies will visibly walk around once
  flow-field validation joins the viewer.
