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

### `text as Struct` HANGS when the struct has ≥8 declared fields with a vector-of-struct field

- **Found while:** Plan 01 E4 — implementing MapFile save/load.
  My MapFile had 10 fields (`version`, `name`, four `pa_*`
  bounds, three `cam_*`, `ground: vector<GroundEntry>`).
  `text as MapFile` hangs indefinitely.  Bisecting by field
  count narrowed the trigger to a hard threshold.
- **Kind:** bug (JSON cast — infinite loop on overflow path)
- **What loft needs:** the cast walker for struct types
  appears to overflow a fixed-size scratch buffer / field
  table when the declared struct has ≥8 fields including
  a `vector<Struct>`.  Either an off-by-one in the bound
  check, or an unchecked grow path.  Tight reproducer:
  ```loft
  struct Inner { q: integer not null, r: integer not null, kind: text not null }
  struct G7 {
      b1: integer not null, b2: integer not null, b3: integer not null,
      b4: integer not null, b5: integer not null, b6: integer not null,
      bv: vector<Inner>,
  }
  struct G8 {
      c1: integer not null, c2: integer not null, c3: integer not null,
      c4: integer not null, c5: integer not null, c6: integer not null,
      c7: integer not null,
      cv: vector<Inner>,
  }

  fn test_g7_works() {
      json = `{{"b1":1,"b2":2,"b3":3,"b4":4,"b5":5,"b6":6,"bv":[{{"q":0,"r":0,"kind":"grass"}}]}}`;
      s = json as G7;       // OK
      println("G7 b1={s.b1}");   // prints "G7 b1=1"
  }

  fn test_g8_hangs() {
      json = `{{"c1":1,"c2":2,"c3":3,"c4":4,"c5":5,"c6":6,"c7":7,"cv":[{{"q":0,"r":0,"kind":"grass"}}]}}`;
      s = json as G8;       // HANGS forever
      println("never reached");
  }
  ```
  G7 = 7 fields (6 ints + 1 vector) → works.
  G8 = 8 fields (7 ints + 1 vector) → hangs.
  No timeout, no error — just an infinite loop.
- **Related observations** (the wide-sandwich shape I
  originally suspected is just a special case of the
  field-count threshold — `Wide4 (4) + ground (1) +
  Wide3 (3) = 8` declared slots in the outer struct):
  - Two NESTED structs sandwiching a `vector<Struct>` also
    hangs when the nested-struct widths sum to ≥7 outer
    fields; single-field nested types fit under the
    threshold and don't trigger it.
- **Workaround in dryopea:** keep MapFile at 6 fields
  (`version`, `name`, `cam_q`, `cam_r`, `cam_zoom`,
  `ground`).  Plan 04 § L1 expands once this ships.
- **Loft pointer:** `src/database/structures.rs::walk_parsed_struct`
  (the @P366 fix site) — likely a 7-entry or 8-entry field
  table that overflows.

### `text as Struct` CORRUPTS the field preceding an empty `[]` array

- **Found while:** Plan 01 E4 — empty `markers: []` / `waves: []`
  in MapFile JSON wrecked the field immediately before them.
- **Kind:** bug (JSON cast — scanner position lost)
- **What loft needs:** when the cast encounters an empty
  array `[]`, it appears to advance the input pointer
  incorrectly, so the NEXT field is matched against the
  PREVIOUS key's slot.  Net: the previous field's value
  reads back wrong.
- **Reproducer:**
  ```loft
  struct Item { x: integer not null }
  struct Box { name: text not null, items: vector<Item> }
  fn test() {
      json = `{{"name":"b","items":[]}}`;
      b = json as Box;
      println("name=[{b.name}]");  // observed: name=[]  (corrupted)
                                    // expected: name=[b]
  }
  ```
  Variants:
  - `vector<integer>` instead of `vector<Item>` → same bug,
    but corruption flavour differs (`name` came back as " ").
  - Empty `[]` BEFORE the populated field (`{"items":[],"name":"b"}`)
    → no corruption (works fine).  Only `[]`-then-field is broken.
  - Non-empty array (`{"name":"b","items":[{"x":1}]}`) → no
    corruption.  Only EMPTY `[]` triggers it.
- **Workaround in dryopea:** structurally avoid empty
  vectors in the saved JSON.  E4 ships without `markers` /
  `waves` / `description` fields; plan 04 § L1 adds them
  once this bug ships.
- **Loft pointer:** same site as the wide-sandwich bug
  above — `walk_parsed_struct` empty-array handling.

### `return (a, b);` rejected when function returns a tuple of two struct types

- **Found while:** Plan 01 integration smoke test —
  implementing `load_map_or_empty(path, palette) ->
  (PaintedWorld, EditorCamera)` with an early return for
  the cold-start branch.
- **Kind:** bug (type checker / parser disagreement)
- **What dryopea sees:** the body's *final-expression* tuple
  literal type-checks fine, but a `return (...)` tuple
  literal of the same shape gets rejected with an error
  whose two halves are textually identical:
  ```
  expected __tuple<PaintedWorld,EditorCamera>,
       got (PaintedWorld, EditorCamera)
  ```
  (`__tuple<...>` is the internal type name; `(...)` is the
  user-facing syntax — same underlying type, but the
  comparison fails.)
- **Reproducer (HANGS-FREE; just doesn't compile):**
  ```loft
  struct A { x: integer not null }
  struct B { y: integer not null }

  fn early_return_fails() -> (A, B) {
      if true {
          return (A { x: 1 }, B { y: 2 });   // PARSE ERROR
      }
      (A { x: 0 }, B { y: 0 })
  }

  fn if_else_works() -> (A, B) {
      if true {
          (A { x: 1 }, B { y: 2 })           // OK
      } else {
          (A { x: 0 }, B { y: 0 })
      }
  }
  ```
- **Workaround in dryopea:** rewrote
  `load_map_or_empty` to use an if-else *expression* with no
  early return.  Trivial; one-liner change.
- **Loft pointer:** the `return` lowering of a tuple-typed
  expression looks like it doesn't unify with the declared
  function return type the same way the body's final
  expression does.

### `{m:j}` JSON formatter OMITS empty / default field values

- **Found while:** Plan 01 E4 — `paint_to_mapfile` produced
  a MapFile with `description: ""`, `markers: []`, `waves: []`;
  `{m:j}` formatter dropped all three from the output.
- **Kind:** bug (silent data loss on save side)
- **What loft needs:** `{m:j}` should emit EVERY declared
  field, including empty strings / empty vectors / zero
  integers.  Today it drops them, so the round-trip
  `save_map_file → load_map_file` parses JSON that doesn't
  match the declared struct shape — which then either
  default-fills (a feature) or hangs (the bug above).
  Even with the cast bugs fixed, silently emitting partial
  JSON is hostile to consumers who hand-edit the file.
- **Reproducer:**
  ```loft
  struct S { a: text not null, b: vector<integer>, c: integer not null }
  fn test_omits() {
      s = S { a: "", b: [], c: 0 };
      println("{s:j}");
      // observed: {}
      // expected: {"a":"","b":[],"c":0}
  }
  ```
- **Workaround in dryopea:** drop fields whose values would
  ever be empty (markers, waves, description, etc.) and
  hand-author placeholder content for the rest.  Constrains
  the editor's save schema until this ships.

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
