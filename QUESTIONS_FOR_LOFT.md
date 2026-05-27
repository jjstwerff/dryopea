<!--
Copyright (c) 2026 Jurjen Stellingwerff
SPDX-License-Identifier: LGPL-3.0-or-later
-->

# Questions for loft

Outbound queue from dryopea to the
[loft](https://github.com/jjstwerff/loft) project: questions,
language / runtime / stdlib feature requests, and problem-fix
asks that dryopea has surfaced and that need to be addressed in
loft.

Each entry is its own short section. When an entry is handed
over to loft (filed as an issue, mentioned in a session, or
otherwise actioned upstream), move it from **Open** to
**Submitted** with a note of what was done. When loft ships the
fix / feature, move it to **Resolved**.

## Entry template

```markdown
### <short title>

- **Found while:** <what dryopea was doing when this surfaced>
- **Kind:** question | feature | bug
- **What dryopea needs:** <one or two sentences>
- **Workaround in dryopea (if any):** <…>
- **Loft pointer:** <P-issue / plan / doc section, if known>
```

## Open

### Div-by-zero warning still fires on `float / int_literal`

- **Found while:** Re-verifying the @P368 fix on 2026-05-27.
  The headline cases (`x / 0.75`, `x / 2.0`, `n / 4`, `n / 2`)
  no longer warn — but `12.0 / 3` (float dividend, integer
  literal divisor) still emits the rewritten warning.
- **Kind:** bug (partial-fix follow-up to @P368)
- **What dryopea needs:** `lit_nonzero` in
  `src/parser/operators.rs` recognises Int/Long/Float/Single
  literals, but the mixed-type `float / int_literal` path
  appears to widen the literal to float (or insert an `as
  float` cast) *before* the warning check reaches the
  divisor, so the literal-detection misses it.  Either lift
  the check above the widening, or also match the cast-
  wrapped literal.
- **Reproducer:**
  ```loft
  fn test() {
      x = 12.0;
      _ = x / 3;        // warns (expected: no warn — 3 is a non-zero int literal)
      _ = x / 3.0;      // no warn
      _ = 12 / 3;       // no warn
  }
  ```
- **Workaround in dryopea:** write `3.0` instead of `3` when
  dividing a float by an integer-valued constant.  Trivial
  but slightly fewer-bytes-on-disk-warts than the original
  precomputed-reciprocal workaround.
- **Loft pointer:** `src/parser/operators.rs::lit_nonzero` —
  add the float-coerced-int-literal arm.

## Submitted

*(none — the three filed entries are now Resolved; see § Resolved.)*

## Investigated — no bug

### Vector-in-struct pass-by-value (false alarm)

Observed during E2 picker work: passing a `Picker { palette,
active }` by value to `render_picker(p: Picker, ...)` produced
`len(p.palette) == 0` inside the callee, even though the
caller's `len(picker.palette) == 11`.

Filed as a suspected fourth bug; reproducer was constructed
and **the bug did not reproduce**.  Plain `vector<integer>`,
`vector<Struct>`, and "inline call inside struct ctor"
patterns all behave correctly: caller and callee see the same
elements.

```loft
struct Item { name: text, n: integer }
struct Wrap { items: vector<Item> }

fn make_wrap() -> Wrap {
    Wrap { items: [Item { name: "a", n: 1 }, Item { name: "b", n: 2 }] }
}
fn consume(w: Wrap) {
    println("consume: items.len = {len(w.items)}");  // → 2 (correct)
}
```

**Root cause:** the apparent "empty vector inside the struct"
was the **JSON-cast-with-extras bug** (filed above) hiding a
load that was actually returning zero entries from the start.
Once GroundType declared all four extra optional fields the
JSON has (`variant`, `color_status`, `height_override`,
`end_drivable`), the cast started returning 11 entries, the
struct correctly carried them across the value-pass, and the
picker rendered.

Notable: bugs (1) and (2) (silent JSON-cast empty + test runner
not failing on assert) were **compound** — they masked each
other for ~half an hour of debugging, producing a green test
suite while every assertion was running against a 0-length
palette.

## Resolved

> Verified against `~/Documents/loft/target/release/loft` built
> from commit 42f8228 ("Fix @P366/@P367/@P368") on 2026-05-27.
> Dryopea suite 60/60 still green; per-bug reproducers in
> `$TMPDIR/p_followups/loft_fixes/`.

### @P367 — Test runner now surfaces assertion / runtime_error failures

- **Loft commit:** 42f8228 (`src/test_runner.rs`)
- **Fix:** test runner now extracts `had_fatal` +
  `runtime_error.message` from the run closure and routes
  typed-runtime-error halts through `matches_expect_fail`,
  so `assert(false, msg)` / `panic` / div-by-zero / any C66
  fault scores FAILED.  Side-effect: also repaired
  `@EXPECT_FAIL` for typed-error paths the panic-only code
  had silently broken.
- **Verified by dryopea:** `loft --tests
  $TMPDIR/p_followups/loft_fixes/p367_assert_fail.loft` now
  prints `FAIL  p367_assert_fail.loft::test_failing_assert
  — assertion failed: this should fail the test`, exit 1.
  A passing neighbour test in the same file still reports
  `ok` correctly.
- **Workaround retired:** `scripts/test.sh`'s marker-file
  grep (`_FAILED_*.txt`) is still active because
  `assert_golden` writes markers as a side-effect — but the
  marker is now a **redundant safety net**, not a primary
  failure signal.  The test runner alone is now sufficient.
  Marker-file path will be removed in a future cleanup.

### @P366 — `text as vector<Struct>` accepts JSON with extra fields

- **Loft commit:** 42f8228 (`src/database/structures.rs`)
- **Fix:** `walk_parsed_struct` now skips unknown JSON keys
  lenient-ignore style (one shared site, both backends),
  matching the dynamic `JsonValue` walker.  Missing declared
  fields still default-fill.  The strict-reject assertion in
  `tests/data_structures.rs::record` was flipped to expect
  the new behaviour.
- **Verified by dryopea:** dropped the 4 workaround fields
  (`variant`, `color_status`, `height_override`,
  `end_drivable`) from `GroundType` in `src/palette.loft`.
  All 18 `tests/01_e2_palette.loft` tests still green,
  golden renders byte-match.  Reproducer:
  `$TMPDIR/p_followups/loft_fixes/p366_json_extras.loft`.
- **Workaround retired:** GroundType matches the design intent
  (9 fields) instead of mirroring every key in palette.json.

### @P368 — No warning on division by a non-zero literal constant (PARTIAL)

- **Loft commit:** 42f8228 (`src/parser/operators.rs`)
- **Fix:** `lit_nonzero` now matches Int/Long/Float/Single
  literals (was Int-only), so `x / 0.75`, `x / 2.0`, `n / 4`,
  `n / 2` no longer warn.  Warning wording also reworded
  ("integer division/modulus" → generic "division").
- **Verified by dryopea:** all-float and all-int literal-
  divisor forms suppress cleanly.  Reproducer:
  `$TMPDIR/p_followups/loft_fixes/p368_div_warn.loft`.
- **Remaining gap:** `float / int_literal` (e.g. `12.0 / 3`)
  still warns.  Filed as a new § Open entry above.  Not
  blocking — the residual is one-character workaround
  (`3.0` instead of `3`).
- **Workaround partially retired:** the mid-precision
  precomputed-reciprocal pattern in `src/world.loft` is no
  longer strictly necessary, but kept for clarity / standard
  graphics idiom.  The other warn-suppressor — `1.0 / ppm`
  in `src/render.loft` — would still warn (variable
  divisor) and is unrelated to @P368.
