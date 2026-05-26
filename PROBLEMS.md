<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Problems

Known bugs, limitations, and dryopea-side workarounds.  Mirrors
the style of loft's `doc/claude/PROBLEMS.md` so a reader bouncing
between repos doesn't have to relearn the format.

**dryopea-internal only.**  Problems that need loft to fix
(language gaps, runtime bugs, stdlib holes) go in
[`QUESTIONS_FOR_LOFT.md`](QUESTIONS_FOR_LOFT.md) instead — that
file is the outbound queue.  PROBLEMS.md is for issues whose fix
lives in *this* repo.

Each entry gets a stable identifier `@D<NNN>` (D for dryopea, so
references can't be confused with loft's `@P<NNN>` rows).  Once
allocated the number is never reused, even after a fix lands.

## Entry template

```markdown
### @D001 — <short title>

- **Severity:** High | Med | Low
- **Found while:** <what dryopea was doing when this surfaced>
- **Repro:** <minimal steps, ideally a path to a script>
- **Expected:** <…>
- **Observed:** <…>
- **Workaround:** <…or "none yet">
- **Fix plan:** <one sentence; "deferred" is OK with a reason>
- **Test:** <path/to/regression, once a guard exists>
```

Severity tiers:
- **High** — data loss, silent corruption, crash on a common
  code path, blocks a plan's current phase.
- **Med** — wrong output / missing feature on a code path that's
  exercised but not yet load-bearing.
- **Low** — cosmetic, edge-case, future-only.

## Open

*(none yet)*

## Fixed

*(none yet)*

## See also

- [`QUESTIONS_FOR_LOFT.md`](QUESTIONS_FOR_LOFT.md) — problems
  whose fix is upstream in loft.
- [`plans/README.md`](plans/README.md) — plans (multi-phase work,
  not bugs).
