<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# dryopea — roadmap

A logical-order list of remaining features.  **We will diverge
from it.**  The goal is to keep "what could we do next?"
answerable in 30 seconds rather than to lock a strict sequence.

Each row: short feature name, status, source-of-truth slot,
brief one-liner.  Status values:

- **shipped** — code landed, tests green.
- **partial** — some code landed; constrained or behind workarounds.
- **drafted** — design written, no code.
- **sketch** — referenced in docs, design not fully written.

Tiers are ordered by **player-impact-per-line-of-code**: Tier A
delivers a playable thing; subsequent tiers add depth on top.
Within a tier, ordering is a suggestion — you can pick any row.

---

## Tier A — Validation playable

One map, one mission, one tower type, one enemy type — but
end-to-end and *fun-shaped*.

| Feature | Status | Slot | Brief |
|---|---|---|---|
| Ground editor (sparse paint, sea default) | **shipped** | [plan 01 E1-E3](future/01-ground-editor/README.md) | Hex grid + camera + palette + click/drag paint |
| Save/load MapFile JSON | **partial** | [plan 01 E4](future/01-ground-editor/README.md) | 6-field schema; expanded once loft JSON-cast bugs land |
| Integration smoke test (cold-start cycle) | **shipped** | [plan 01](future/01-ground-editor/README.md) | 72/72 green under `scripts/test.sh` |
| Interactive GL editor (E1-live) | **shipped** | [plan 01 E1-live](future/01-ground-editor/README.md) | `src/main.loft`; human playtest pending |
| 3D solver-validation viewer | drafted | [plan 02](future/02-solver-validation-viewer/README.md) | Painted layer + height-solved mesh overlay, 40% transparent |
| Marker layer + spawn points | drafted | [plan 03](future/03-marker-layer-and-spawns/README.md) | Second sparse layer; multi-direction spawns |
| Map library + browser (planet-view UI) | drafted | [plan 04](future/04-map-library/README.md) | MapFile schema (L1), map index, content, selector |
| End-to-end validation scenario | drafted | [plan 05](future/05-validation-scenario/README.md) | The "minimum playable thing" spec |

When Tier A is done the game is **playable** — a player can
land, paint a base, defend through some waves, scramble.  Not
deep yet; just real.

---

## Tier B — Combat depth

Skilled play hooks.  Each row is opt-in; an entry-level player
can ignore the lot and still complete missions.  Documented at
[DESIGN.md § 7 Combat dynamics](../docs/DESIGN.md#7-combat-dynamics).

| Feature | Status | Slot | Brief |
|---|---|---|---|
| Tower attack-count decay + repair | drafted | DESIGN § 7 | 30-shot budget; goes black; refill on repair |
| Repair rule (firing tower can't be repaired) | drafted | DESIGN § 7 | Engineering realism: power-down before maintenance |
| Boost (timed, fire-and-forget) | drafted | DESIGN § 7 | Pink, held-key activation; validation ships free |
| Strain system (shot-density wear) | drafted | DESIGN § 7 | Per-shot wear scaled by output level |
| Boost cooldown + active-maintenance bypass | drafted | DESIGN § 7 | Pickup-drop-repair cycle doubles boost frequency |
| Overload (presence-locked input) | drafted | DESIGN § 7 | High-output mode; player must remain |
| Hot-swap cycle (two-top alternation) | drafted | DESIGN § 5 + § 7 | Sustain overload via swap-pit cycling |
| Swap-pit wall pattern | drafted | DESIGN § 5 | Authored indentation: spare top + safe parking + clear path |
| Tower variants (anti-insect / area / etc.) | drafted | DESIGN § 7 future-tower-types | Unlocked via scouting (Tier D) |
| Ammo for variant weapons | drafted | DESIGN § 7 | Per-shot consumable, distinct from decay |
| Tactical type-swap mid-combat | drafted | DESIGN § 7 | Different-type spare in swap pit |
| New tower order via beacon ferry | drafted | DESIGN § 7 | Carry beacon from core to build site |

Likely candidate for a single dedicated plan slot
(`plan 06 — Tower mechanics depth`?) covering the strain /
boost / overload / hot-swap arc together — they share
mechanics and graphics.

---

## Tier C — Enemy diversity

Make tier 1 fully alive, then extend to tier 2 + tier 3.
Currently all enemies render as the same placeholder magenta
cuboid.

| Feature | Status | Slot | Brief |
|---|---|---|---|
| Tier 1 economic-bot vs combat-bot wave split | drafted | DESIGN § 10 + SETTING § Combat bots | Typed wave mixes; combat-bots dormant by default |
| Combat-bot wake klaxon (diegetic activation cue) | drafted | SETTING § Combat bots | Audible signal when an AI reactivates its military |
| Boss = mobile repair platform (2×2) | drafted | DESIGN § 7 Boss | Industrial unit, not a soldier; phase 3 |
| Tier 2 — insects + sap | drafted | SETTING § Insects | Passive fauna; smell-tracking; `wall_high` blocks |
| Tier 3 — elementals + stones | drafted | SETTING § Elementals | Dormant; gem-keyed activation; 4 sub-kinds |
| Hacking helpers (subvert robot units) | drafted | DESIGN § 9 Helpers | Coordinator bots = highest-value target |
| Robot diversity — typed wave compositions | drafted | SETTING § Robot diversity | Workers / haulers / scouts / coordinators / etc. |

Likely candidate for two plan slots: `plan 07 — Tier 2 insects`
(largest mechanical novelty: passive fauna + smell-tracking) and
`plan 08 — Tier 3 elementals + stones` (gem mechanic, dormancy).
Tier-1 typing + boss + hacking probably fit into plan 03 or
plan 06 expansions.

---

## Tier D — Between-missions meta

Multi-mission play actually feels like a campaign.  Currently
each mission is independent; persistence isn't shipped.

| Feature | Status | Slot | Brief |
|---|---|---|---|
| Central space station hub | drafted | SETTING § Between missions | Rented bay; persistent state; pre-mission UI |
| Persistent inventory (tops, materials, points) | drafted | DESIGN § 13 | Carries across runs |
| Q4 loadout closure | drafted | DESIGN § 7 + § 13 | Pick towers from inventory before each sortie |
| Scouting unlocks new tower types | drafted | DESIGN § 7 + § 13 | Scouted intel persists; variants become orderable |
| Helper rescue quests | drafted | DESIGN § 9 Helpers | Stranded helpers from past missions, rescuable |
| Static planet-view map selector | drafted | [plan 04 L3](future/04-map-library/README.md) | Clickable markers per available map |
| Rotating planet-view UI (future UX) | sketch | SETTING § Future UX | Day/night terminator, overlay state |
| Bounded sessions + mission chaining | drafted | DESIGN § 14 | Time-windowed run shape |

Likely candidate for `plan 10 — Station hub + persistence`
covering hub UI + inventory + Q4 loadout + scout-unlock.  Mission
chaining (DESIGN § 14) may want its own slot once the persistent
inventory lands and its trigger fires.

---

## Tier E — Narrative arcs (deep content)

The world the validation mechanics live in.  Deliberately
gated behind player demonstrated competence — see
[SETTING.md § Future contact](../docs/SETTING.md#future-contact--humans-ais-and-the-no-shortcut-rule)
for the no-shortcut design rule.

| Feature | Status | Slot | Brief |
|---|---|---|---|
| Faction territory awareness | drafted | SETTING § Robot diversity | Maps tagged with AI faction; affects compositions |
| Side quests — underground human contact | drafted | SETTING § Future contact | Breadcrumb discovery → first contact → trade |
| Direct contact with an AI | drafted | SETTING § Future contact | Deep-lore: meet the girl-hacker AI as a person |
| Truth discovery — government cordon paradox | drafted | SETTING § Future contact | Off-planet leverage |
| Player-faction alignment | drafted | SETTING § Future contact | Ally with one AI vs another |
| Off-planet meta — orbital banking, vendors | sketch | DESIGN § 13 Future expansion | Shop at the station hub |
| Multi-player disruption missions | sketch | SETTING § How mechanics fit | Coordinate against the AI economy |

Likely candidate for `plan 11 — Future contact arcs`, but this
tier is **deferred** by design — it's the cap on the skill
ceiling, not the floor.  Authoring of breadcrumbs sits inside
the maps from plan 04 + plan 07-08, so the *content* lives in
the per-map authoring, while the *triggers + state machine*
deserve a plan when the trigger to start lands.

---

## How to use this

- **"What could we do next?"** — scan the table for the nearest
  drafted row whose dependencies are shipped.  Pick whichever
  seems most appealing.
- **"Is X in the plan?"** — search for X here.  If it's not
  here, either it's not yet design-thought or it lives in a
  lib_plan (loft library scope — outside dryopea).
- **"What's the dependency between X and Y?"** — the tier
  ordering is a hint but not a strict gate.  Concrete
  dependencies live in each plan's `## Dependencies` section.

Diverging from the order is expected.  The dogfood loop
(per [CLAUDE.md](../CLAUDE.md) dev cadence) often pulls a
later-tier feature forward when it sharpens an earlier-tier
demo.  Update this file when something ships or when a new
candidate is added.

---

## See also

- [`README.md`](README.md) — plans admin (workflow, file layout)
- [`DEFERRED.md`](DEFERRED.md) — parked plans
- [`../docs/DESIGN.md`](../docs/DESIGN.md) — master design
- [`../docs/SETTING.md`](../docs/SETTING.md) — fiction
- [`../QUESTIONS_FOR_LOFT.md`](../QUESTIONS_FOR_LOFT.md) — outstanding loft-side asks
