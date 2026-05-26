<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# dryopea — design (canonical)

This is the dryopea-side master design. It originated as
@PLAN46 in the loft tracker (drafted 2026-05-21) and is **mirrored
verbatim below** with three adjustments:

1. Cross-tracker links currently point to absolute URLs into the
   loft repo. **These are TEMPORARY** — loft will soon drop
   consumer-project references (only language / runtime bug
   fixes stay), at which point the upstream library plans
   (gridmesh, terrain-heightmap) will move to their own repos
   and these URLs will need updating. Treat any
   `github.com/jjstwerff/loft/blob/main/doc/claude/…` link as
   placeholder.
2. An "Updates since 2026-05-21" callout listing dryopea-side
   decisions that supersede statements in the original. The body
   text is kept intact for traceability; consult the callout for
   the current position when reading.
3. **This file is now canonical** — loft's copy is the historical
   draft. Edits to dryopea's design land here, not in loft.

## Updates since 2026-05-21

- **2026-05-26 — Authoring is in-game.** The original document
  proposed using the **moros editor** for terrain authoring (see
  the editor/game-split table below). This is superseded:
  dryopea owns its own **in-game editor**. The editor is a mode
  of the dryopea executable, not a separate binary, and shares
  the game's render pipeline, input system, camera, and hex
  math. First plan: [`plans/future/01-ground-editor/README.md`](../plans/future/01-ground-editor/README.md).
- **2026-05-26 — Sea-default infinite world.** Worlds start as
  an endless flat sea; only painted hexes occupy storage
  (`hash<GroundType[q,r]>`, miss = sea). Editor and game share
  this data model. See plan 01.
- **2026-05-26 — World scale: hexes are 1.5 m diameter.** A hex
  is ~1.5 m vertex-to-vertex (side ≈ 0.75 m, flat-to-flat ≈
  1.3 m). Concrete implications below in § World scale.
- **2026-05-26 — Canonical ground-type palette.** Eleven types
  in three sub-palettes (water 4 + land 5 + structure 2 walls).
  See [`GROUND_TYPES.md`](GROUND_TYPES.md) for the full design
  and [`../examples/palette.json`](../examples/palette.json) for
  the loadable form.  Wall colours (red) are explicit
  placeholders.
- **2026-05-26 — Walls have drivable ends + topological
  entrances.**  A wall hex with exactly one wall neighbour
  (an "end") renders a drivable ramp on its open face — so an
  unfinished wall lets enemies roll up onto it.  Two wall ends
  within 1-2 tiles of each other form a recognised
  **entrance**, which the flow-field routes enemies through.
  A fully closed wall has no path; enemies fall back to
  **nibbling the nearest wall hex** until it breaks.  See
  [`GROUND_TYPES.md` § Entrances](GROUND_TYPES.md#entrances--two-wall-ends-near-each-other).
- **2026-05-26 — Proxy art convention.**  Placeholder geometry
  for testing gameplay before final art lands lives in
  [`PROXY_ART.md`](PROXY_ART.md).  Current entries: enemy
  (magenta cuboid, black front), player vehicle (white cuboid
  with hover + boost + auto-impact-protection), NPC helper
  (grey version of the player — builds walls/towers and
  salvages loot), loot drop (gold cube), tower
  (almost-black cone, red top, peeks over `wall_high`), core
  building (dark-blue tower variant).
- **2026-05-26 — Combat: pulsed-laser towers, nibble-melee
  enemies.**  All towers fire the same primitive weapon: a
  pulsed laser beam with a recharge pause between shots.
  Enemies have **nibble** (damage-per-second melee) when they
  reach the core or are blocked at a wall.  Enemy target
  priority (highest first): **a player or NPC physically
  blocking the enemy's path to the core** → the core itself
  (via entrance / broken wall) → the nearest wall hex when no
  path through exists.  In the absence of a blocker, the
  player and NPCs are otherwise ignored.
- **2026-05-26 — Input philosophy: movement / position triggers,
  not key presses.**  The player should *feel* they activated
  something through their motion, not by typing.  Most actions
  are **bumping into things** (drive into the core =
  force-launch; drive over loot = pick up; drive to a tower =
  pickup / deposit / repair / boost) or **leaving trails**
  (driving with wall-paint active marks the trail as walls for
  helpers to construct).  Key presses are reserved for *mode
  toggles* (paint-walls on/off, palette index) and the rare
  intent that has no spatial form.  This holds across the whole
  game; design new mechanics in spatial terms first, fall back
  to keys only when no position-trigger fits.
- **2026-05-26 — Wave-start triggers: walls or provocation
  (whichever fires first).**  Enemies activate (wave 1 begins)
  by EITHER of two spatial conditions:

  (a) **Walls-built threshold.**  The player has built **N
  walls** (exact N TBD).  The act of laying perimeter IS the
  commitment — the player marks the ground they intend to
  defend, and the enemies arrive in response.

  (b) **Player provokes by visiting a distant spawn marker.**
  The player drives their vehicle ONTO a spawn marker hex that
  sits a *fair distance* from the starter tower / core
  (distance TBD).  Touching the marker = poking the enemy.
  Wave 1 fires.  **Spawn markers very close to the core
  never trigger** activation — those are safe to explore /
  inspect without commitment.

  Either trigger fires wave 1; once activated, the wave list
  proceeds via its scheduler (inter-wave delay etc.).  No
  "Begin Wave" key; no fixed pre-wave timer.  Pacing is set
  by how fast the player chooses to commit OR to provoke — a
  cautious settler builds slowly; a brave scout reaches out and
  touches a far spawn marker; either gesture brings the fight.
  Aligns with the movement-trigger philosophy above; the map
  author shapes the pacing by placing close (safe) vs. far
  (provocation) spawn markers.
- **2026-05-26 — Numbers are TBD (intentionally).**  Every
  numerical value mentioned in this design — tower fire rate,
  shot budget, damage, range, HP, movement speeds, starting
  budget, build times, the wall-count wave-start threshold N,
  inter-wave delay seconds, scramble-inventory effect size,
  decay rates — is a placeholder.  A coherent set of starting
  numbers will be picked together (not per-mechanic in
  isolation) and refined through playtest.  This Updates list
  records *shapes*, not *values*.
- **2026-05-26 — New towers placed via beacon ferry; single
  pickup/drop key.**  The player orders a new tower by carrying
  a **tower beacon** from the core to the chosen build site:

  (1) Drive next to the core, press the **single pickup/drop
  key** → a beacon is removed from the core's stock (cost is
  points, taken from the wallet at pickup time) and floats
  above the vehicle as a carried object.

  (2) Drive to the chosen 7-hex centre, press the same key →
  the beacon is placed; a tower lander touches down on it (same
  separate-lander idiom as the starter); helpers handle any
  remaining construction time on the deployed tower.

  The key is the **only non-movement/non-camera key** the game
  uses for *interactions*: it picks up whatever the vehicle is
  next to (beacon at core, tower-top at a healthy tower, etc.)
  and deposits whatever is currently carried (beacon onto a
  build spot, tower-top onto another black tower or into the
  core for scramble inventory).  Empty-handed = pickup;
  carrying = deposit.  Loot drops (gold cubes) remain
  auto-pickup on drive-over — too cheap a decision to need an
  explicit press.
- **2026-05-26 — Free starter tower via a separate lander.**
  Every base starts with **one free tower**, delivered by its
  own **separate lander** (visually distinct from the core's
  rocket, smaller) that touches down **close to the core** at a
  position the *player does not choose* — random within a small
  radius of the core's footprint.  Same "area + random within"
  shape as the core's landing, applied to the starter tower's
  drop.  Resolves the wave-1 deadlock: the player cannot fight,
  but the starter tower is ready to fire as soon as it lands;
  the player's starting budget funds any *additional* towers /
  helpers they want to order before wave 1.  Future expansion:
  more separate landers can deliver supplies / helpers /
  additional towers, mirroring the planet-scale supply theme.
- **2026-05-26 — Boss enemies: 2×2 footprint forces structural
  play; phase-3 leader commands; tower-attack retaliation.**
  Boss-class enemies occupy a **2×2-hex footprint** (twice the
  width of a regular enemy) and therefore **cannot path
  through 1-hex entrance gaps** — they fit only through 2-hex+
  openings or by **breaking walls** to make their own.  Wall
  topology becomes a *tactical* lever against bosses: a
  perimeter that funnels regulars through 1-hex gaps still
  leaks bosses through whatever is breakable or 2-wide.
  Bosses have higher HP, and (phase 3) two unique behaviours:
  ordering nearby regular enemies to **guard** them (formation
  play); **localised tower-attack retaliation** — a tower that
  fires on the boss is *marked*, and regular enemies in the
  boss's immediate vicinity (short communication radius)
  re-target the marked tower.  The boss itself never attacks
  towers; it stays focused on the core.  Player options:
  isolate the boss from its escorts to cut the order chain;
  salvage tower tops to silence specific towers and keep them
  unmarked.  All of this is **deferred to phase 3** — captured
  now so entrance authoring + the marker / enemy / tower data
  models leave room.
- **2026-05-26 — Core has six sides: three functional, three
  plain.**  The core building is rendered as a hexagonal prism
  (matching its 7-hex footprint) with 6 distinct flat faces.
  **Three** of those carry a function and have a visible icon
  on the placeholder geometry:

  - **Output / lift-off face** — rocket lifts off here at
    scramble; landers (helpers, supply drops) emerge here.
    Icon: red flame / chevron.
  - **Tower-core retrieval face** — dispenses tower beacons.
    Icon: small red disc.
  - **NPC ordering face** — accepts helper orders (points
    debited; an NPC lander arrives at the lift-off face).
    Icon: small silver-grey rectangle.

  The other **three faces are visually plain** (no markings, no
  interaction).  The player learns the core's layout in ~5 s
  by walking the perimeter — function comes from *which side
  you drove to*, no menu.  **Core's flat top** signals NPC
  order status by colour (black = no order; red → amber →
  green interpolates as arrival approaches; white flash on
  landing).  No HUD; the visualisation is diegetic.

  Both tower-core and NPC-order pickups use the **single
  pickup/drop key**.  Tower-core pickups produce a carried
  beacon (deposit it elsewhere to call a tower lander);
  NPC-order pickups debit points immediately, no carry — the
  helper self-deploys at the lift-off face when the lander
  arrives.

  Helper-roster cap of 6 remains in force; NPC orders that
  would exceed the cap fail at the press.
- **2026-05-26 — Helpers are persistent characters; damage
  needs retrieval, not auto-respawn; stranded helpers are
  future rescue targets.**  Each helper is an **identity**
  (eventually a name + skill profile; for validation, just an
  opaque persistent id).  When a helper vehicle is too
  damaged, it **wrecks** and the helper inside is *downed
  but alive*.  The player or another helper retrieves them by
  driving to the wreck + pickup → carry them back to the core
  (same single-carry-slot idiom).  After recovery time at the
  core they rejoin the roster.  **No automatic respawn** —
  retrieval is the only way back.  Helpers not retrieved by
  force-launch are **stranded** at their wreck hex on the
  planet; they persist as **rescue-quest targets** for the
  same player on a later run OR (multiplayer) for a different
  player who lands nearby.  This integrates with the
  abandoned-bases mechanic in § Future expansion: stranded
  helpers are one of the things you didn't manage to bring
  along.  For validation, stranded-state is data only; the
  rescue-quest UI / planet integration is future.  Replaces
  the earlier "corpse + auto-respawn" sketch.
- **2026-05-26 — Helper roster: 2 starting, 6 max.**  When the
  core lands, **2 NPC helpers** are inside the rocket and
  emerge to start work.  The player can later add more (via
  point-funded build orders / drops; carryover from a previous
  base is possible too), but the roster is **hard-capped at 6
  helpers**.  This keeps labour scarce — a closed perimeter
  takes meaningful time even at max roster, and the player
  must triage which orders (walls, towers, salvage runs)
  matter most.  Helpers in excess of 6 can't be ordered; the
  cap is a design pressure, not a soft target.
- **2026-05-26 — Core landing is "area + random within."**  The
  core building is always present in every base — it isn't
  authored in the editor; it's placed at base start by the
  game itself.  The player chooses a **starting LOCATION** (a
  general area on the map / planet), and the game **lands the
  rocket at a random hex within a small area** around that
  chosen point.  Same shape as DESIGN.md § Future expansion's
  "Players pick start spots" — agency on the *region*, variance
  on the *exact tile* — but applied to every base, not just
  planet-scale picks.  Consequence: the player must adapt the
  defence plan to wherever the core actually lands.  Validation
  rule of thumb: ~3-hex radius around the chosen centre, land
  hexes only (re-roll if random pick is water / impassable
  terrain).  Editor (plan 01) therefore does NOT paint a core
  marker — the core's location is a runtime decision, not
  authored content.
- **2026-05-26 — Carry-over scope: points only for now; richer
  later.**  The validation-tier scramble carry-over is the
  player's **unspent points** (added to the next base's
  starting budget per the budget rule above).  Tower-tops
  deposited in the core travel along the *mechanic* (they are
  collected, parked at the core, survive force-launch) but
  their **effect on the next base is deliberately left open**
  for now — the validation scenario doesn't depend on it.
  When the carry-over economy expands, it will gain:

  - **Multiple material / point types** — the game's economy
    diversifies beyond a single point pool; different
    materials represent different resources (TBD; no taxonomy
    yet).
  - **Orbital launch banking — a *secondary* launch outside
    the scramble phase.**  The player will be able to send
    cargo pods (materials / points) to orbit *during play*,
    instantly converting them into safely-banked resources.
    Banked materials persist and are usable later (next base,
    or the planet-scale meta).  Distinct from the rocket-and-
    everything scramble: the scramble takes the *player +
    whatever's onboard*; the cargo pod takes *just resources*,
    no exit.  This lets the player bank gains mid-base without
    leaving — a counter to "stay too long and lose what you
    gathered."

  All deferred — captured here so the data model leaves room.
- **2026-05-26 — Starting points budget per base; scales with
  previous base's haul.**  Every base begins with a points
  budget the player can spend before / during the first wave —
  the budget is the first move in the build economy, not a
  zero-start dig-out.  On subsequent bases (after a successful
  scramble), the starting budget is **higher**, scaling with
  points the player carried out of the previous base.
  Concrete rule (validation tier): the budget = a fixed base
  amount + the player's unspent points at the moment they
  entered the rocket.  Unspent points NOT carried (because the
  player force-launched and left some helper-held loot behind)
  are forfeit, same as un-evacuated tower tops.  Net effect:
  scramble inventory now has TWO carrying lanes — tower tops
  (parked in the core) and the player's wallet (carried with
  them) — both grow the next base's strength, both subject to
  the "what made it onboard" gate.  This also resolves the
  validation deadlock: the player can spend the starting budget
  to order their first tower(s) and helper(s) before wave 1
  arrives; a free pre-placed starter tower is still likely
  needed because helpers take time to build the ordered one.
- **2026-05-26 — Player is a noncombatant manager.**  The
  player vehicle cannot harm enemies (no weapon) and is not
  hunted by them in the general case.  Combat is entirely
  between **towers and enemies**; the player choreographs.
  Exception: the **conditional damage rule** above — being in
  the path between an enemy and the core makes the vehicle (or
  an NPC helper) a target until they move.  Consequence: a
  validation scenario must start with at least one free
  pre-placed tower (else wave 1 deadlocks); the vehicle has a
  minimal damage model that activates only in the blocker case.
- **2026-05-26 — Tower lifecycle: shot-budget decay + repair +
  boost.**  Towers degrade per **attack count**, not per time:
  each laser shot consumes one unit of a per-charge shot
  budget; when spent, the tower's top turns black and it stops
  firing.  Player repairs to refill (top → red).  Player can
  also boost a tower (top → pink) for time-limited enhanced
  performance.  Idle towers never decay.
- **2026-05-26 — Enemy salvage + NPC helpers.**  Killed enemies
  drop loot (gold cubes) at their death hex.  The player picks
  up directly by driving over; **NPC helpers** (grey versions
  of the player vehicle) auto-path to loot and carry it to the
  core, which converts it into the upgrade resource pool.  NPC
  helpers also execute build orders for both walls and towers
  (DESIGN.md § Systems #2 generalised).
- **2026-05-26 — Multi-direction spawns + marker layer.**  A
  second sparse data layer holds **markers** parallel to the
  painted palette.  First variant: **spawn point** = hex + one
  of 6 hex directions.  A base typically has multiple spawn
  markers; enemies appear at each, heading along the marker's
  direction; once close to a base they switch to flow-field
  guidance.  See plan
  [`../plans/future/03-marker-layer-and-spawns/`](../plans/future/03-marker-layer-and-spawns/README.md).
- **2026-05-26 — Wave list = flat count list, progressively
  harder; final wave gates a free scramble.**  Waves are a
  simple ordered list of integers (each = enemy count for that
  wave).  Per-enemy spawn-marker selection is **random** at
  spawn time; direction comes from the picked marker.  Authored
  in [`../examples/waves.json`](../examples/waves.json).
  Successive waves get **progressively harder** — for now by
  count (the validation list ramps 5 → 80), later by
  composition (bosses, mixed types).  After the **final wave**
  is cleared with the core alive, the player enters a **free
  scramble phase**: no more enemies are coming, so they can
  ferry tower-tops at leisure, top up the wallet via remaining
  loot, and launch the rocket with full carry.  **Most plays
  will not reach the final wave** — the curve is designed so
  the scramble decision usually has to be made mid-list, not
  after.  Reaching the final wave is the "perfect run" outcome.
- **2026-05-26 — Wave spawn-visible interval before enemies
  walk.**  When a wave begins, enemies **appear at their picked
  spawn markers and stand visible for a few seconds** before
  starting to walk toward the base.  The interval is the
  player's **scramble decision window**: see what's coming
  (how many, from which directions, what kinds — eventually
  boss vs. regular), assess the defence, and decide to stand
  or scramble before any enemy has moved.  During the interval
  the active spawn markers pulse / glow so the player can
  spot them from any zoom.  Once the interval expires, enemies
  start their approach-mode path along the marker direction.
  Interval length TBD (likely a handful of seconds — long
  enough to read the threat, short enough not to drag pacing).
- **2026-05-26 — Tower-top salvage = the scramble mechanic,
  played tactically.**  A tower's red top is a detachable carry
  object.  Player-initiated pickup: drive to a healthy tower,
  pickup → the tower goes black (stops firing); the top floats
  above the player.  Deposit at **another black tower** = fast
  repair (instantly restores it).  Deposit at the **core** =
  add to scramble inventory for the next base.  The same
  carried disc, two destinations, mutually exclusive use — the
  scramble decision lived inside every combat sortie.
- **2026-05-26 — Points fund towers AND helpers.**  Salvaged
  loot from killed enemies (delivered to the core) becomes the
  player's **point pool**.  Points spend on **two things**:
  (a) ordering new towers, (b) ordering new NPC helpers.
  Both are queued as build orders; existing NPC helpers
  construct towers, and the core spawns new helpers when their
  order completes.  Same currency, two destinations — analogous
  to the carried-top "fast repair vs scramble inventory"
  tradeoff but at the base-economy scale.  Total score visible
  to the player is the running point total.
- **2026-05-26 — Walls cost time, not points.**  Walls (both
  `wall` and `wall_high`) and **bridges between walls** are
  **free** in the point economy — no cost from the player's
  point pool — but they are **not instant**: an NPC helper must
  spend construction time at the build site before the wall hex
  actually appears.  This makes walls a *labour* resource
  (helper-seconds) rather than a *currency* resource (points),
  and the bottleneck on perimeter expansion is the helper
  roster, not the score.  Pre-painted walls in the editor
  (plan 01) are instant — runtime orders are not.  **Bridges
  between walls are a second-phase feature** (the `cy`-layer
  deck mechanic in @PLAN46 § Systems #3 + #4); same free-but-
  timed economics when they ship.
- **2026-05-26 — Vehicle destroyed = respawn inside the core,
  which doubles as a launch prompt.**  When the player vehicle
  is destroyed (blocker-damage edge case is currently the only
  damage path), the player **respawns inside the core**.
  Because they're now inside the lift-off footprint, the
  **launch countdown starts immediately** (same pulse, same
  hold sequence as a normal entry).  The player has two
  options:

  - **Drive out through the opening** → cancels the launch,
    returns to the base, vehicle restored.  No further
    consequence beyond having been knocked back to the core.
  - **Stay inside** → liftoff fires with whatever is currently
    onboard.  The scramble decision was made for them by the
    destruction event, but they get to ratify (stay) or veto
    (leave) it.

  Net: vehicle "death" is never a game-loss; it's a forced
  return-to-base + a free "are you ready to leave?" prompt.
  Fits the no-run-loss design and keeps the scramble decision
  in the player's hands even at the moment of greatest stress.
- **2026-05-26 — No hard run-loss condition.  A "lost run" is
  the player's own judgment, not a game state.**  dryopea does
  not have a fail screen.  Every base ends with the player
  launching the rocket — sometimes with a full carry, sometimes
  with almost nothing.  The next base always starts.  A run
  the player feels was *bad* is simply a run that produced
  meagre carryover; a *good* run produced a lot.  The
  difference is felt across the sequence, not announced by the
  game.

  Mechanical consequences:

  - No "Game Over" screen, no forced exit from a run.
  - The run is the **continuous sequence of bases the player
    chooses to play**; it ends only when the player stops
    playing.
  - Bad performance still produces *some* carryover (an empty
    wallet, no tower-tops; the next base falls back to the
    fixed baseline starter loadout — starter tower + 2
    helpers + baseline budget).
  - Removes any need for a points-zero or vehicle-destroyed
    "lose" trigger — those become *bad outcomes*, not run-
    ending events.

  The closed-by-decision register for the game-loss question:
  the player's expectations are the only meter.  The earlier
  "core destroyed = run ends" framing in @PLAN46 is fully
  retired by this rule.
- **2026-05-26 — Core is invulnerable; nibbling drains POINTS,
  not core HP.**  The central tower **cannot be destroyed**.
  Enemies that reach the core (or nibble it during the launch
  countdown) **do not damage the core's structure** — instead
  each nibble tick **drains the player's point wallet**.  This
  overturns the earlier @PLAN46 framing of "core destroyed =
  run ends."  New loss model: the player is never forced out
  by structural collapse; they choose when to scramble.  The
  *cost* of staying too long is bleeding points to nibbles
  (eroding the wallet that funds towers, helpers, and the
  next base's starting budget).  An emergent "run end"
  condition (e.g. wallet hits zero or some negative threshold,
  or the player vehicle is destroyed in the blocker-damage
  edge case) is **TBD** — captured here as a deliberate open
  decision.
- **2026-05-26 — Force-launch is a hold sequence with visible
  pulse.**  Launch is triggered by **driving INTO the core
  through its opening** — the doorway on the lift-off face
  (one of the three functional faces; the other two are
  external dispensers).  The player can't enter the core
  through any other side.  The moment the vehicle crosses the
  opening into the core's interior, the core's **bottom
  begins to pulsate** (placeholder: a bright orange / red ring
  at the base of the cylinder brightens and beats faster as
  the countdown progresses).
  After a fixed number of seconds (TBD), **liftoff fires**
  with whatever is currently onboard (carried items, deposited
  scramble inventory, wallet, helpers who've made it back).
  **Exiting the footprint at any time before liftoff CANCELS**
  the sequence — the pulse fades, the countdown resets, and
  the player can return to the base.  This countdown is also
  a **hazard window** during a wave: enemies that reach the
  core continue nibbling (draining points) while the player
  sits inside; the longer the launch takes, the more points
  the player loses to nibbles.  Net: the launch decision
  costs *time* (helpers reaching the rocket, last carry runs)
  + *points* (whatever nibble drain occurs during the
  countdown).
- **2026-05-26 — Rocket launch trigger: enter the core.**
  Launching the rocket is a **player position trigger**: drive
  the vehicle into the core building (its 7-hex footprint) and
  the launch sequence starts immediately.  NPC helpers
  *normally* board the rocket on their own when their work
  list is empty (no salvage to fetch, no builds queued, no
  outstanding orders).  Entering the core as the player
  **forces** the launch right then — any NPC helpers not yet
  onboard, and any loot / scramble inventory not yet
  delivered, are **left behind**.  The launch decision is
  therefore another scramble tradeoff: wait for the helpers
  to finish their loops (more carried over, but the base
  weakens during the wait) or force-launch (immediate exit,
  lose what didn't make it).

## World scale

| Quantity | Value | Notes |
|---|---|---|
| **Hex diameter** (vertex-to-vertex) | **~1.5 m** | The canonical unit. |
| Hex side length | ~0.75 m | = diameter / 2 |
| Hex flat-to-flat | ~1.30 m | = diameter × √3 / 2 ≈ 1.299 m |
| Hex area | ~1.46 m² | ≈ (3√3 / 2) × side² |
| 32×32 chunk footprint | ~48 m × ~42 m | One gridmesh chunk; about a city block |

**Why 1.5 m.** Small enough that the painted resolution feels
tactical — a hex is roughly "where one person stands". A small
vehicle covers 2-3 hexes; a tower base is 1-2; a wall is 1 hex
wide and several long; the core building footprint is a small
cluster. Large enough that authoring a base doesn't drown in
hex count.

**Comparisons.**
- A person's footprint: 1 hex.
- A medium vehicle: 2-3 hexes wide.
- A wall section: 1 hex wide, walkable along its length.
- An enemy mob: 1 hex.
- Sniping distance (rough): 20-30 hexes ≈ 30-45 m.
- Across a 32×32 chunk: ~48 m — visible at a glance from the
  3rd-person camera.

These scale assumptions feed back into camera height, vehicle
hover clearance, weapon range, wave spawn radii, etc.

---

# @PLAN46 — dryopea: sci-fi free-build / tower-defence game

**Status:** Future (design drafted 2026-05-21; no code). Depends on
[lib-plan 20 terrain height-map](https://github.com/jjstwerff/loft/blob/main/doc/claude/lib_plans/future/20-terrain-heightmap/README.md)
+ [lib-plan 19 gridmesh](https://github.com/jjstwerff/loft/blob/main/doc/claude/lib_plans/19-gridmesh/README.md) Phase C.
**Likely the FIRST real consumer of both** — it validates the
terrain→mesh→render stack at low *content* cost (algorithmic terrain, small
material palette), so building dryopea's vertical slice doubles as the
acceptance test for those primitives.

## Goal

A non-standard sci-fi tower-defence. At the **start of a match the player
places their core building** — the thing the enemies attack and the player
must defend (lose it = lose). The player rides a **semi-floating vehicle**
(over-the-shoulder 3rd-person camera; it hovers above terrain to avoid
clipping cliff edges), and rather than placing structures directly, **issues
build ORDERS** — towers, walls, bridges — that **NPC workers** then construct
over time. The player reacts in real time: repairing and buffing towers as
enemy waves and a boss approach, and **travelling the landscape** to find
hidden treasures that speed up upgrades. Walls are **≥1 hex wide and
walkable**, so the vehicle can drive along them to reach the core under
attack; **bosses can break walls**, severing those routes and re-opening the
enemy path.

What sets dryopea apart from every other tower-defence is the **scramble
phase**: a base is never a simple win-or-lose. When it's about to be
overrun, the player fires a rocket out of the core building, **evacuating key
components** to start the *next* base with an advantage. The game is a
**run** of bases, strung together by what you manage to carry out — see
[§ The scramble phase](#the-scramble-phase--the-signature-mechanic).

## The scramble phase — the signature mechanic

dryopea's identity. A base is **not** win-or-lose-forever; it's one round of
a longer **run**. When a base is about to be overrun, the player can
**scramble** — fire a rocket out of the core building and evacuate to the
next base.

- **The core building is also the escape rocket.** Defending it gains a
  second meaning: keep it alive long enough to launch. If the core is
  destroyed *before* you scramble, the **run ends** (the true loss). A
  successful scramble is a *tactical retreat*, not a defeat.
- **Salvage is a live tradeoff.** Evacuating a key component takes it with
  you but **disables the tower it came from** — so grabbing salvage weakens
  your remaining defence and *hastens* the overrun. Hold longer for more
  salvage, or launch now to keep what you already have: that tension is the
  core decision of the whole game.
- **Carry-over → the next base starts ahead.** Evacuated components give an
  advantage at the next base (stronger / earlier towers). A run is a
  **sequence of bases**, each a TD round, chained by what you carry out — a
  roguelike structure rather than a single defended base.

**Implications for the build:**
- The game is **multi-level / run-based**: each base is an editor-authored
  level (terrain + spawn points + item markers, per the editor/game split
  below); a run chains them. The cross-base **meta-state is the
  evacuated-component inventory** — the only thing that persists between
  bases.
- This is almost entirely **game logic** (run structure, the launch
  trigger/animation, component inventory, the salvage UI) — it adds little to
  the terrain / gridmesh / flow-field primitives. It's the meta layer on top,
  and the reason the whole engine exists: to make the scramble decision feel
  good.

## Design principle — bounded sessions (the rogue-lite opt-out)

A single base must be a **bounded, one-sitting mission**, and the boundaries
between bases must be **clean save-and-quit points**. This is a first-class
design constraint, not an afterthought — and a deliberate strength:

- **Short sessions are the rogue-lite appeal.** Much of why people love
  rogue-lites is the graceful opt-out: when you're short on time you reach a
  natural stopping point without losing progress. dryopea's **scramble IS that
  exit** — bail out of a failing base, keep your salvage, stop; resume the run
  later. A time-pressured player is *rewarded* for leaving, not punished.
- **Between-base = the save point.** The only cross-base meta-state is the
  evacuated-component inventory (§ scramble), so persisting a run between bases
  is tiny and clean. A base-in-progress need not be resumable mid-mission; the
  run is resumable at **base boundaries**, which keeps save-state trivial.
- **Pace a base to a target sitting.** Tune wave count / build time so a base
  resolves (win, scramble, or loss) within a bounded window. Treat "how long
  is a base" as a **tunable pacing parameter**, not an emergent accident —
  echoing @PLAN36's "sluggish by design" pacing principle (bounded tempo as a
  first-class lever).

## The editor / game split (architectural spine)

> **Note 2026-05-26** — The "moros editor" row is superseded; see
> "Updates since 2026-05-21" at the top of this file. dryopea owns
> its own in-game editor.

**The editor authors only TERRAIN; the running game places everything else.**

| | Authored in the editor (static) | Placed by the game at runtime (dynamic) |
|---|---|---|
| **Owns** | hex **terrain features** (ground types + slope, lib-plan 20) **+ a small set of static gameplay markers** — enemy **spawn points**, findable-**item positions** | **buildings, walls, bridges, towers** + spawned mobs |
| **Tooling** | the moros editor (hex paint + slope solver + the **existing item-layer** placement tool) | dryopea runtime build-order system |
| **Mutability** | baked content; re-saved with the level | mutable override layer; built + destroyed during play |
| **Data** | the solved height field + material per hex + markers via the **existing `h_item` item layer** | a separate structure/override store keyed by hex |

This split is the load-bearing decision:
- **Authored content vs runtime state.** The level file carries the terrain
  AND the static markers (spawn points, item positions); a save game carries
  the runtime structures + live mobs. They never mix, so a level can be
  replayed and structures reset without touching terrain or markers.
- **The editor's game-authoring is small and bounded** — terrain plus a few
  static markers (enemy spawn points, findable-item positions, and probably
  about the most of it). It has **no building/wall tool**: structures are
  placed only at runtime, so the bulk of dryopea-specific systems live in the
  game, not the editor.
- **Markers reuse moros's EXISTING item layer — no new editor work.** Spawn
  points and findable items are just entries in the moros item palette,
  placed onto a hex's `h_item` field with the item-placement tool that's
  already there. They're authored *positions*; the game decides what
  spawns/appears at each. **The more complex stencil machinery
  (`PlaceStencil` / `stencil_stamp`) is NOT needed yet** — single-hex item
  placement covers all the markers dryopea wants for now.
- **Structures are an OVERRIDE LAYER on top of solved terrain** (see lib-plan
  20 § "Built structures are a separate override layer"): a wall is
  raised-terrain (walkable top, steep sides), a bridge is a deck on a higher
  `cy` layer over preserved low ground; both reuse the terrain height +
  slope-face + gridmesh dirty-re-mesh machinery.

## Systems (game-specific scope)

0. **Match setup — place the core.** At the start of a base the player
   places the **core building** (the defend objective): it becomes the
   **flow-field goal** all mobs path toward, and it is **also the escape
   rocket** (see § scramble). Keep it alive long enough to scramble; if it's
   destroyed first, the **run** ends. It is the first runtime structure;
   everything else (towers/walls/bridges) is built to defend it.
1. **Floating vehicle + over-shoulder camera** — a hover controller that
   samples terrain height under the vehicle footprint (`world→hex →
   h_height`, max over the footprint, + clearance) so it rides above terraced
   steps; a 3rd-person follow camera.
2. **Build-order system** — the player marks a placement (tower / wall /
   bridge); NPC workers path to the site and construct it over time (not
   instant). Build-validity gated by `md_slope`/material (no towers on cliffs
   or water).
3. **Structure override layer** — walls (walkable hex-width ramparts),
   bridges (`cy`-layer decks toward other walls), towers; all mutable +
   destructible. Building/destroying = a height-override edit → dirty chunk →
   gridmesh incremental re-mesh.
4. **Multi-level pathing + enemy flow field** — a traversal graph over
   natural ground (slope-gated, `md_slope` = cost) **+ wall tops + bridge
   decks**, connected where adjacent at compatible heights.
   - **Enemy guidance = a flow field ("direction markers"), defined at
     runtime.** Compute a distance-from-goal field (BFS/Dijkstra from the
     **player-placed core building** — the fixed defend goal) over the
     *mob-walkable* graph; each cell's "direction marker" is the descent
     toward the nearest-to-goal neighbour. Mobs just sample the marker at
     their cell → O(1) per mob, scales to a horde with one field. This is the
     canonical TD flow field. **The goal is the (static) core, not the roaming
     vehicle — so the field recomputes only when WALLS change, never per
     frame.**
   - **Walls funnel mobs to gaps automatically.** A wall is a steep raised
     hex → impassable to *ground* mobs by the same `md_slope` gate that blocks
     cliffs (the floating vehicle ignores it — traversal is per-agent-type).
     The distance field routes around the obstacle, so its markers point
     through the **holes** in a wall line — no explicit gap-finding needed;
     it's a property of the field. Building a wall reshapes the markers;
     leaving a gap is how you choose where mobs come through.
   - **Recompute shares the wall dirty-regions.** A wall built or
     boss-broken dirties chunk(s) → the SAME dirty signal that triggers
     gridmesh re-mesh also re-solves the affected region of the flow field +
     re-routes. One dirty event, two consumers (mesh + field).
   - **Vehicle + NPC workers** use point-to-point routes (A* over the same
     graph), not the enemy flow field.
5. **Combat** — enemy waves spawned at the **editor-authored spawn points** +
   a boss that **breaks walls** (→ dirty re-mesh + path re-route); tower
   targeting; reactive player **repair/buff** of towers.
6. **Exploration / economy** — free-roam the terrain for hidden treasures (at
   the **editor-authored item positions**) → faster upgrades.
7. **Scramble + run meta** (the signature mechanic, see § above) — the launch
   trigger when the base is failing; the salvage selection (which components
   to evacuate, disabling their towers as you pull them); the
   evacuated-component **inventory** carried between bases; loading the next
   base with the carry-over advantage; the run win/lose bookkeeping
   (scramble = continue; core destroyed first = run over).

## Phases (vertical-slice first)

| # | Scope | Proves |
|---|---|---|
| **D0** | Terrain consumer — load an editor-authored level, render it via gridmesh Phase C, drive the floating vehicle over it (hover + over-shoulder camera); place the **core building** at a chosen hex. | the lib-plan 20 + gridmesh stack end-to-end (the dryopea-first validation). |
| **D1** | Structure override layer + build orders — mark a wall/tower, NPC worker constructs it, chunk re-meshes; build-validity from `md_slope`. | the override layer + dirty re-mesh on a built structure. |
| **D2** | Flow field + multi-level pathing — distance-from-core field guides mobs (funnels to wall gaps); vehicle + NPC point-to-point routes over ground + wall tops + bridge decks. | the flow field (recompute on wall change) + the traversal graph + bridge `cy`-layer. |
| **D3** | Combat slice — one enemy wave (spawns at authored points, flows to the core) + towers + a boss that breaks a wall (re-mesh + flow-field re-route). | destruction as a runtime dirty-rebuild driver for BOTH mesh + field. |
| **D4** | Economy / exploration — treasures + upgrades. | the loop closes. |
| **D5** | **Scramble + run** (the signature mechanic) — launch trigger, salvage selection (pull components → disable towers), carry-over inventory, load next base with the advantage, run win/lose. | the design THESIS — that the scramble decision is the fun. Build as soon as the single-base loop (D0-D3) is playable. |

Vertical slice (engine) = **D0 + minimal D1 + D2 + D3**: place the core, drive
in, order a wall (mobs funnel to the gap), a wave spawns and flows to the
core, a boss breaks the wall and re-opens the path. That slice exercises every
shared primitive.

**Fun slice = + D5 (minimal):** the single-base loop is only the *substrate*;
the game isn't proven fun until you can scramble out of a failing base and
arrive at the next one ahead. So although D5 builds last (it needs the base
loop first), prototype a minimal scramble the moment D0-D3 is playable —
that's the soonest the core design bet can be tested.

## Dependencies + shared primitives

- **lib-plan 20 terrain height-map** — REQUIRED (the height field dryopea
  drives over). dryopea supplies its own small material palette + drainage
  seeds.
- **lib-plan 19 gridmesh Phase C** — REQUIRED (per-chunk meshing, T4 auto
  slope-faces, dirty incremental re-mesh for wall build/destroy).
- **moros editor** — *superseded by dryopea's in-game editor (see Updates).*
- **Likely needs** (open): A*/flow-field pathfinding over the multi-level hex
  graph; an entity/update loop. Evaluate whether the override layer +
  multi-level pathing are dryopea-only or lib-worthy (moros may also gain
  runtime structures later) before building — keep game-specific systems
  (towers, waves, economy) in dryopea, lift genuinely shared mechanics to a
  lib only when a second consumer appears (the gridmesh "toolkit not
  framework" discipline).

## Open questions

1. **Multi-level pathing representation** — how the ground + wall-top +
   bridge-deck graph is stored and queried (per-hex walkable-surface list?
   the `cy`-layer model directly?).
2. **Build-order UI in 3rd person** — how the player targets a hex / line for
   a wall from an over-the-shoulder camera.
3. **Save/level format** — confirm the terrain-content vs structure-state
   split on disk.
4. **Enemy / wave / boss design** — out of scope until the slice works.
5. **Lib vs game boundary** — which of {override layer, multi-level pathing}
   become shared libraries vs stay in dryopea.

## Future expansion — planet-scale enemy economy + multiplayer (addons, post-core)

**Out of scope for the initial game; recorded so the core design doesn't
foreclose it.** The base-hopping run is the foundation; the long-horizon
vision opens it onto a whole planet:

- **The enemy is a faction with an ECONOMY** — robots and/or insects with
  **supply lines, mines, and factories** that *produce* the waves. Instead of
  only defending against waves, players push outward to **disrupt that
  economy** (cut a supply line, take a mine, knock out a factory) to weaken
  what spawns against them.
- **Get a foothold on the planet.** A persistent **planet map** frames the run
  as territorial: bases are positions on it. The early bases sit in **rural
  parts of the planet (easier)**; missions get **much harder** as players push
  toward the enemy's industrial heartland (the supply/mine/factory network).
  So the run's escalating difficulty has an in-world cause — you're nearing
  their production.
- **Multiplayer.** **Multiple players** operate on the same planet,
  coordinating to disrupt the enemy economy and establish footholds.
- **Players pick start spots — including persistent ABANDONED bases.** A run
  doesn't start from nowhere: the player chooses a spot on the planet, and
  those spots can be **bases abandoned earlier — by themselves OR a fellow
  player.** When you scramble out, the base **persists** on the planet with
  whatever you *didn't* evacuate (left-over resources + structures), and it's
  **saved and revisitable**. But it doesn't sit frozen: **mobs encroach over
  time**, so revisiting an abandoned base means inheriting its leftover
  resources (a head start) *and* an enemy presence already gathered nearby (a
  danger). This makes the scramble's "take vs leave" decision ripple across
  the *whole persistent world*: what you leave seeds a future restart — for
  you or an ally — but rots into a mob-infested spot the longer it's left.
  The same risk/reward tension as the scramble, now at planet scale.

**Architectural notes (so the core build leaves room):**
- The per-base game already produced by D0-D5 is the **unit** the planet
  campaign composes — a planet mission is "a base + an economy objective on
  the planet map." Keep base state self-contained (it already is: terrain
  content + structure/run state) so the campaign layer can place + sequence
  bases without reaching inside them.
- **Multiplayer reuses loft's shipped stack** — `lib/server` (multi-client
  WebSocket) + `lib/web` (WS client), the same infrastructure validated by
  @PLAN36 (audience) and the tic-tac-toe plans. The expansion is strategic
  game logic + a planet meta-map on top of proven netcode, not new transport.
- The **enemy economy as a wave SOURCE** generalises the D3 spawn model: waves
  stop being authored set-pieces and become *output of* the economy state
  (disrupt the factory → fewer/weaker waves). The flow field, terrain, and
  scramble all carry over unchanged.
- **Persistent abandoned bases = server-side world state.** An abandoned base
  saves a small snapshot: the un-evacuated structure/run state (already
  self-contained) + a timestamp / encroachment level. The "mobs gathered
  nearby" needn't be a live simulation — it can be *derived on revisit* from
  elapsed time + the base's exposure (cheap, deterministic), so the planet
  doesn't have to tick abandoned bases continuously. Shared revisiting (a
  fellow player's abandoned base) is server-authoritative persistent state on
  the same `lib/server` stack + loft's store — no new persistence layer, just
  per-base snapshots keyed by planet position.

## See also
- [lib-plan 20 terrain height-map](https://github.com/jjstwerff/loft/blob/main/doc/claude/lib_plans/future/20-terrain-heightmap/README.md)
  — the terrain primitive dryopea consumes (+ its § "Built structures are a
  separate override layer" boundary note).
- [lib-plan 19 gridmesh](https://github.com/jjstwerff/loft/blob/main/doc/claude/lib_plans/19-gridmesh/README.md) — per-chunk
  meshing + dirty re-mesh dryopea renders with.
- [@PLAN36 audience-generative-art](https://github.com/jjstwerff/loft/blob/main/doc/claude/plans/36-audience-generative-art/README.md)
  — sibling app-plan; the projector's 3rd-person GL camera + GPU mesh pipeline
  are reference material.
- `lib/moros_*` — terrain editor, map, render, sim packages (in the loft monorepo).
