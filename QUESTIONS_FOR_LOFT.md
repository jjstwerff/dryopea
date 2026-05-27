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

### Path-backed user-data Store binding — `hash<X[k]>` mmap'd to a file

- **Found while:** Designing the persistence destination for
  dryopea's painted world + marker layer + stencil instance
  lists (chat 2026-05-27).  The world will grow substantially
  with stencils; serialising on every save is wasted IO when
  the runtime already keeps the data in a `Store::new(N)` buffer
  that could just as easily have been `Store::open(path)`.
- **Kind:** feature (language / runtime — user-data Store
  allocation from a path)
- **What loft needs:** A `.loft`-level way to declare *"the
  user-data `Store` for these records lives at this file path,
  mmap'd."*  A `hash<PaintedHex[q,r]>` lookup then becomes a
  direct read into the mmap'd buffer; mutations are durable on
  the next OS msync — no `f += val; f.sync()` save loop, no
  `text as Struct` parse on load.  The hash IS the file.
- **What's already shipped on the Rust side:**
  - `Store::open(path)` — `src/store.rs:307` (mmap-storage
    crate, default feature).
  - `Store::open_durable(path, DurabilityMode)` —
    `src/store.rs:2250` — phase 01 of @PLAN38.
  - Loft-callable integrity bracket — `store_durable_check(p)`
    / `store_durable_seal(p)` — phase 01b, commit `8bc4b08`,
    `default/02_images.loft:330-341`.
- **What's NOT yet exposed to `.loft`:** binding a user-data
  `Store` to a path.  Today every `hash<X[k]>` / `vector<T>`
  lives in a Store allocated via `Store::new(N)`
  (`src/database/allocation.rs:71, 85, 592`;
  `src/database/mod.rs:547, 639, 778-786`).  The runtime never
  calls `Store::open(path)` for user-data containers.  The
  phase 01b commit (`8bc4b08`) explicitly cited re-entrant
  borrows on `State` as the reason it chose path-metadata over
  Store-handle-wrapper for the on-corruption callback —
  startup-time path-binding sidesteps that issue entirely.
- **Shape sketch (illustrative — loft's call on syntax):**
  ```loft
  // Top-level directive — runtime opens this Store at startup
  // BEFORE user code runs, so no re-entrancy on State.
  #persist "dryopea_world.store";
  struct PaintedWorld { painted: hash<PaintedHex[q, r]> }

  fn main() {
      pw = PaintedWorld { painted: hash<PaintedHex[q, r]>::new() };
      pw.painted += PaintedHex { q: 0, r: 0, kind: 5 };
      // no save call; OS msyncs on idle / clean exit
  }
  ```
  or per-instantiation (`pw: PaintedWorld @ "dryopea_world.store"
  = ...;`).  Or program-flag (`loft --persist=dryopea_world.store
  src/main.loft`).  Whichever shape: binding must occur at
  startup, not from a native call.
- **Why now is not the deadline:** dryopea is *already* on the
  right substrate — `PaintedWorld` lives in a runtime-allocated
  Store today; the only pending step is "have the runtime call
  `Store::open(path)` for that Store instead of `Store::new(N)`."
  The rest of dryopea's code (paint, lookup, marker layer,
  stencil instances) is unchanged.  When the surface lands,
  migration is a one-line annotation.
- **Workaround in dryopea:** None applied; staying on JSON
  via `text as MapFile` + `:j` (with the cast bugs filed above
  for the JSON path itself).  A manual binary `file()` +
  `#read` cursor-IO route is **strictly worse** — it requires
  hand-rolled ser/deser AND still doesn't get us mmap.  Better
  to fix JSON's cast bugs upstream and wait for this language
  surface than to take the cursor-IO detour.
- **Pair with:** `store_durable_check(path)` /
  `store_durable_seal(path)` — once the path-binding ships,
  the integrity bracket wraps the *Store* (auto-mmap), not a
  *user-managed binary file* as today.  The bracket pattern is
  unchanged; only what's between `check` and `seal` changes from
  "manual binary writes" to "nothing — the hash mutations are
  the writes."
- **Loft pointer:** `@PLAN38` (durable-Store API) — naturally
  slots in as a future phase.  The phase doc
  (`doc/claude/plans/future/38-loft-store-durable/01b-loft-binding.md:249`)
  has phase 02 lined up as `store_durable_snapshot(path)` — that's
  still snapshot semantics, *not* the path-bound-user-data-Store
  ask.  New phase (01c, or 02b, or 04 — loft's pick).

### `vector<Struct>` with trailing `u8 not null` fields corrupts on `:j` save

- **Found while:** Plan 03 M3 — saving the marker sidecar.
  MarkerEntry has shape `{ q: integer, r: integer, kind: u8,
  direction: u8 }` (two trailing u8 fields).  Iterating
  `hash<MarkerEntry[q, r]>` and appending into a
  `vector<MarkerEntry>`, then serialising with `:j`, produces
  JSON where the u8 field values are **garbage memory** and the
  preceding integer fields are zeroed for the second-and-later
  entries.
- **Kind:** bug (`:j` formatter or vector iteration —
  mixed-width struct layout)
- **What dryopea sees:**
  ```loft
  pub struct MarkerEntry {
      q:         integer not null,
      r:         integer not null,
      kind:      u8      not null,
      direction: u8      not null,
  }

  fn test() {
      mw: hash<MarkerEntry[q, r]> = [];
      mw[1, 1] = MarkerEntry { q: 1, r: 1, kind: 0 as u8, direction: 0 as u8 };
      mw[2, 2] = MarkerEntry { q: 2, r: 2, kind: 0 as u8, direction: 3 as u8 };

      out: vector<MarkerEntry> = [];
      for e in mw {
          out += [MarkerEntry {
              q:         e.q,
              r:         e.r,
              kind:      e.kind,
              direction: e.direction,
          }];
      }
      println("{out:j}");
      // expected: [{"q":1,"r":1,"kind":0,"direction":0},
      //            {"q":2,"r":2,"kind":0,"direction":3}]
      // observed: [{"q":0,"r":0,"kind":3,"direction":0},
      //            {"q":6859879637655319924,"r":12653,
      //             "kind":183,"direction":255}]
  }
  ```
  Visible pattern: the first entry's `kind` slot received the
  *second* placement's `direction` value (3) — i.e. fields look
  shifted by one slot.  The second entry is full memory garbage.
- **Workaround in dryopea:** `marker_file.loft` now declares a
  wider on-disk shape `MarkerSaveEntry { q, r, kind: integer,
  direction: integer }` and `save.loft`'s
  `marker_world_to_file` widens `MarkerEntry.kind/direction` to
  integer when building the save vector.  Same idiom as
  `PaintedHex` (u8 in memory) ↔ `GroundEntry` (text on disk).
- **Loft pointer:** `:j` formatter for `vector<Struct>` where the
  struct has trailing `u8 not null` fields, OR loft's
  vector-of-struct iteration / copy with mixed-width fields.
  Bug surfaced AFTER M2 commit `d87d202`; the same code path
  passed 11/11 in M1 commit `d8f311c`.  Trigger may be related
  to adding sibling code in `markers.loft` (new functions, no
  struct changes) — possibly codegen-order-sensitive.

### Loft parser rejects `(tuple_local.N as float)`

- **Found while:** Plan 03 M3 — converting the integer return
  of `world_to_canvas` (a `(integer, integer)` tuple) into
  floats for sub-pixel arrow geometry math.
- **Kind:** bug (parser — cast-paren handling on tuple field
  access)
- **What dryopea sees:** All four forms below fail with the
  same `Expect token ;` / `Syntax error: unexpected ')'`
  error pointing at the cast:
  ```loft
  // From world.loft: hex_to_world returns (float, float).
  // From render.loft: world_to_canvas returns (integer, integer).

  pix = world_to_canvas(cam, wx, wy, w, h, ppm);

  // (1) Parenthesised cast on tuple component — FAILS:
  cx_f = (pix.0 as float);
  //                     ^ Syntax error: unexpected ')'

  // (2) Unparenthesised cast on tuple component — FAILS too:
  cx_f = pix.0 as float;
  //              ^ Expect token ;

  // (3) Bind first, then cast the local — ALSO FAILS:
  cx_i = pix.0;
  cx_f = cx_i as float;
  //          ^ Expect token ;

  // (4) Works only via dual indirection: turn the integer
  //     pixel into a separate float-typed local via a
  //     no-op multiply, or inline the world→canvas math
  //     so floats never become integers in the first place.
  ```
- **Reproducer (minimal):**
  ```loft
  fn pixel() -> (integer, integer) { (10, 20) }

  fn test() {
      p = pixel();
      x = p.0 as float;   // PARSE ERROR
      println("{x}");
  }
  ```
- **Workaround in dryopea:** `marker_render.loft`'s
  `draw_marker_arrow` inlines render.loft's `world_to_canvas`
  math but keeps the intermediates as `float` end-to-end, so no
  integer→float cast is needed on a tuple component.  This
  duplicates ~6 lines of camera projection math; cleanup once
  the parser fix ships.
- **Loft pointer:** probably the same parser site that handles
  the existing `(struct_field as T)` cast — that form works in
  `painted.loft` (`pl_aq = (h.q as float);` and `(a.q as float)`
  inline), so the tuple-field-access path appears to need its
  own arm.

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
