<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# dryopea — setting and lore

The world the player lands in.  Mechanics live in
[`DESIGN.md`](DESIGN.md); this document explains **why those
mechanics are what they are** in the fiction of the game.

## History — the planet was already inhabited

Before the colonization robots arrived, the planet had
**already received an ancient landing ship**.  The history of
that earlier arrival shapes everything that came after.

- **An ancient landing.**  A vessel — origin unknown, era
  unknown, fate unknown — touched down on this planet at some
  point long before the events of the game.  The full story is
  not the player's to know; the *consequences* are.
- **Survivors retreated to mountain caves.**  Whatever
  happened to the ship and its crew, **some of them survived**
  and built lives in **caves high in the mountains**, because
  the upper-altitude air was the only place they could
  *breathe* — the planet's surface atmosphere did not match
  their needs without help.  The mountain caves are the first
  human settlements, the original refuges.
- **Air-quality control let them go deeper.**  Over generations
  the survivors developed **air-control technology**: closed
  environments, scrubbers, oxygen recycling — whatever the
  specifics, they perfected the means of breathing comfortably
  in spaces the planet's natural atmosphere wouldn't allow.
  Once that was solved, **they moved deep underground** — out
  of the mountain caves and into a true subterranean
  civilization, because below the surface there was *space,
  protection, and resources* the mountain caves couldn't
  match.  The mountain caves remain (some still inhabited or
  used), but the centre of gravity is below.
- **The colonization robots arrived later** — sent by some
  outside civilization to prepare the planet for new arrivals,
  with no working knowledge of the underground inhabitants
  already present.  This is the "haywire colonization robots"
  context from below.
- **The hidden humans hacked the robots.**  Over time, the
  underground civilization **gained control over the robots**
  — hacking them, repurposing them, bending the original
  colonization program toward their own ends.
- **Factions, and faction wars.**  The underground humans are
  **not a single civilization.**  They have **factions**, and
  the factions **use hacked robots to wage war on each
  other.**  The resulting chaos — robots fighting robots,
  some on no one's behalf — is what the outside cordoning
  authority sees as "haywire AI."  The truth is messier: the
  AI is being driven, just by people who are not officially
  acknowledged to exist.

This history reframes the situation:

- The **military cordon** isn't only about AI contagion.  It
  also keeps the *existence of the underground human factions*
  from leaking out.  Officially, the planet has a robot AI
  problem.  Unofficially, the cordoning government may or may
  not know there are humans down there directing the
  apparent chaos.
- **The robots are tools, not just broken machines.**  Their
  haywire behaviour is partly the residue of the original
  corruption, partly the active intervention of underground
  factions.  Different robot encounters may behave
  differently because they answer to different masters.
- **Permits exist in a fog of half-truths.**  The official
  reason for issuing permits may be intel, salvage, or
  containment; the operator on the ground may discover the
  underground humans, the faction wars, and the real shape of
  the planet only by being there.  This is future-content
  territory but the door is open.

## The premise — a quarantined colonization run

Before the events of the game, robots were dispatched to
**prepare the planet for colonization** — a standard
terraforming-and-construction package.  Mining, basic
infrastructure, atmospheric work, the kind of long unattended
labour that automated swarms do well.

**Something went wrong with their AI.**  The robots didn't
just fail; they went **haywire** — they kept *running* their
program, but in some corrupted form.  Mines, factories, supply
lines, defensive structures all still exist on the planet's
surface, but they answer to a will that is no longer the one
that sent them.

## The quarantine — the military cordon

The government's response is *containment*:

- The **military has blocked the planet** for ordinary entry.
  Approaches are turned away; orbital insertions without
  clearance are intercepted.
- Exit is *mostly* blocked too.  A ship that makes it back to
  orbit faces intense scrutiny.  Some craft slip out — the
  small, hardened, single-mission rockets the player rides
  are part of that exception — but the cordon is real and the
  margin is narrow.
- **The reason for the cordon is AI contagion, not the planet
  itself.**  The government is frightened that the haywire
  robots' AI will **spread to their own robots in orbit** —
  the construction drones servicing satellites, the logistics
  bots in stations, the maintenance swarms throughout the
  near-system.  A single carrier vessel returning with a
  compromised system could seed years of clean-up.  Better
  to seal the source.

This frames the *entire game loop*:

- **Players are in there on official permits — short,
  time-bounded sorties.**  The cordon is not bypassed; it is
  *navigated*.  Each run is a contracted mission for a fixed
  window: drop in, do the work, get out before the permit
  expires.  Sorties are explicitly short by design.  The
  bounded-session principle in DESIGN.md is the *contract
  duration*, not a soft pacing preference.
- Permits are issued by whatever authority is running the
  containment — the same body that placed the cordon.  Who
  gets a permit and why (salvage contractors, government
  scouts, scientific assays, private claims) is **flavour
  open to authoring** per mission; the mechanic is "the
  player is on the clock."
- **The rocket is the only confirmed exit.**  Scrambling is
  not a tactical retreat from a single base; it is the only
  way the *run* continues at all, and exit is gated by the
  permit + the cordon's narrow tolerance.  Stay past the
  permit window, lose too much, and the player is
  effectively trapped until the next base-and-rocket pairing
  can be reached.
- **Robots are the enemy, but they are not malicious.**
  They are *broken machines doing the job they were given,
  the wrong way.*  Their factories still produce; their
  supply lines still flow.  The player's defensive towers,
  their helper vehicles, their core rocket — these are
  scavenged or improvised on the same industrial substrate.

## The other enemy — insects + sap

The robots are tier 1.  **Tier 2 are insects** — biological,
not mechanical, and motivated by **sap**.

The planet hosts **huge trees** in the surrounding wilds.
Their sap is extraordinarily valuable:

- **A potent energy source** — high-density fuel for whatever
  burns it.
- **A life-prolonging medicine** — its medicinal properties
  are the real treasure; the kind of compound that humans go
  to a war-cordoned planet for.

The insects **gather sap from the huge trees** as part of
their own natural cycle.  Their hives presumably exist
somewhere in the wilds; they patrol, defend, and process the
trees.  They are not haywire — they are *normal fauna* doing
what they do.  That puts them on a collision course with two
groups: the haywire robots clearing terrain (which destroys
trees) and the human expeditions (which want the sap).

**Why this matters for gameplay:**

- **Insects can appear in early maps as passive wildlife.**
  Their presence is **not gated behind a difficulty phase** —
  a beginner map can have insects buzzing among trees as
  atmosphere, and the player can drive through them freely
  without combat ever starting.  This makes insects a perfect
  fit for the "hidden challenges off the guided road"
  authoring discipline in plan 04: the *threat* of insects
  is an optional engagement the player triggers themselves.
- **Insects ignore players who don't gather sap.**  They are
  not territorial in the robot sense.  Even a player driving
  through their wilds is fine — they are not threatened.
  Only when a player (or anyone friendly) **gathers sap**
  do the insects react.
- **They track by smell.**  A carrier holding sap exudes a
  scent the insects detect at range; they converge on the
  smell-carrying target and attack.  The moment the sap is
  delivered (banked / spent / handed off), the scent ends
  and the chase ends with it.
- Enemy *encounters* become an *interest choice*, not a
  constant pressure — distinct from robots, who don't care
  who you are.  Sap is a *bet*: the value is high, but the
  moment you pick it up you have to outrun or outfight what
  your scent attracts.
- The sap is a **player-harvestable resource**.  The helper
  **mining** skill can extend to sap collection (drive to a
  tree, helper extracts sap, helper carries it back like
  loot).  The **crafting** skill turns sap into useful
  things (medicine, fuel for special equipment).
- The sap is **also why people accept the permit risk** —
  the medicinal value is a serious economic motive.  Permits
  are often issued *because* there's a sap claim attached.
- The two enemy tiers play **different games**:
  - Robots are *territorial* — they react to encroachment
    on their infrastructure (factories, mines, supply lines).
  - Insects are *resource-protective* — they react to
    encroachment on trees and sap.  Avoid the trees and they
    avoid you.

This sets up the planet as **two overlapping ecologies** —
mechanical and biological — that share the same terrain but
have different rules of engagement.  The player chooses how
to interact with each.

## The third enemy — elementals + stones

Beyond robots (tier 1) and insects (tier 2), the planet hosts
**elementals** (tier 3) — four elemental kinds:

- **Water**
- **Fire**
- **Wind**
- **Earth**

Each elemental is a creature whose **attack patterns are
keyed to special stones of its element**.  The stones exist
on the planet as **rare environmental fixtures** — placed by
the map author (no auto-gen, per plan 04).  Each elemental
**senses stones of its own element at a distance** — they
*feel* them, in the user's words.

What this implies (with intentional design room left):

- An elemental's *behaviour* changes with proximity to a
  stone of its element.  A fire elemental near a fire stone
  is in its full attack pattern; far from any fire stone, it
  is muted or dormant.  Authoring a hot encounter is in part
  authoring the stone placements.
- The four elementals do **not** all wake together.  A map
  with only a water stone activates water elementals only;
  earth, fire, wind stay quiet without their stones.  Mixed-
  stone maps are tougher and *layered*.
- Elementals are a *spatially keyed* threat: where the
  stones are matters as much as which elementals are present.
  The same elemental on two different maps behaves
  differently depending on what's been placed.
- The stones are presumably **player-affectable** — destroyed,
  moved, harvested, used — but **how** the player interacts
  with them is open design space (a stone-disabling action
  could be a powerful weapon against a specific elemental
  type; harvested stones could be a player resource for
  upgrades; both are possible).

This makes the tier-3 layer the **mapped-encounter** tier:
robots are everywhere by default, insects appear where
trees do, elementals appear where their stones are.  The
three tiers stack rather than replace.

## How the setting shapes the mechanics

| Mechanic | Why it fits the setting |
|---|---|
| **Robots have factories / supply lines / mines** | They were *colonization machines*; that is the program they keep running.  Disrupting their economy (DESIGN.md § Future expansion) is disrupting a corrupted infrastructure, not invading a society. |
| **Hacking robots specifically** | They share an AI lineage with the haywire ones; a helper with hacking skill can *speak the same protocol* and turn or disable one.  Other enemy types (insects per § Future expansion) are not hackable — different category of threat. |
| **Persistent abandoned bases** | Other rocketed-in expeditions came before.  Their leftover structures are still in place, slowly being encroached by the haywire economy.  The persistent-world mechanic in § Future expansion is *not* a multiplayer convenience — it is the cordoned planet as a place where things accumulate because no one is cleaning up. |
| **Stranded helpers as rescue quests** | Helpers left behind aren't dead — they're in a place where rescue is *possible but expensive* (another rocket has to make it through the cordon).  The rescue mechanic in PROXY_ART.md § Helpers fits the cordon: helpers persist on the planet because the cordon means no easy retrieval. |
| **Scramble = the only exit** | Mirrors the one-way-mostly cordon.  Carrying out tower-tops, points, materials matters because every gram has to clear the military's net. |
| **Multiplayer disruption missions** (Future expansion) | Multiple players sneak in independently to coordinate against the broken-AI economy.  The cordon is permeable to small operators, not industrial fleets. |
| **Boss enemies as larger constructs** | Heavy mining / construction units that the haywire AI repurposes for hostility — they were never *designed* as combat units, which is why they don't (yet) directly fire at towers; they push toward objectives the corrupted program identifies (the core, the supply lines, the player's encroachment) and *retaliate* through their swarm. |

## What this is NOT

- A war story.  The robots aren't an enemy in the moral
  sense; they are infrastructure that broke.
- A pure resource grab.  The player isn't there to strip the
  planet; they're there to do something specific each run
  (per-map objectives in plan 04) within the larger constraint
  that *no one is coming to help*.
- A redemption arc for the robots.  The contagion fear is
  legitimate; the cordon is the right call from the
  government's perspective.  The player's exploits don't
  un-corrupt the AI.  At best they survive and bring out what
  they can.

## Tone

- **Cold-industrial-with-stakes**: the world is mechanical,
  practical, salvageable, and serious — not grimdark, not
  comedic.
- **Loner-with-tools-and-a-team**: the player is competent, the
  helpers are professionals, the core is reliable, the
  enemies are *broken systems running on inertia*.
- **The cordon is felt, not narrated**: don't have a cutscene
  about it; do have a sky that includes military overwatch
  silhouettes, an HUD that hints at signal jamming during
  scramble, abandoned bases with someone else's serial
  numbers stencilled on them.  Setting through environment,
  not lecture.

## See also

- [`DESIGN.md`](DESIGN.md) — mechanics this lore frames;
  § Future expansion is where the lore explicitly becomes
  gameplay (planet-scale supply disruption, multiplayer,
  abandoned bases).
- [`PROXY_ART.md`](PROXY_ART.md) — current proxies do not
  show the lore (everything is placeholder shapes); the lore
  applies when actual art lands.
- [`DESIGN_HISTORY.md`](DESIGN_HISTORY.md) — the 2023 README
  framed it as "tactical campaign with relatively short
  missions"; the haywire-AI quarantine is the 2026 expansion
  of that frame.
