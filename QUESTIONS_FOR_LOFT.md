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

*(none — all filed entries either Open above or Resolved below.)*

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

> Earlier batch verified against `~/Documents/loft/target/release/loft`
> built from commit 42f8228 ("Fix @P366/@P367/@P368") on 2026-05-27.
> Dryopea suite 60/60 then green; per-bug reproducers in
> `$TMPDIR/p_followups/loft_fixes/`.
>
> Later batch (@P372–@P375 + `store_persist_bind`) tracked on the
> loft `libraries` / `bumper_plane` branches as the upstream agent
> ships fixes; the local loft binary at
> `~/Documents/loft/target/release/loft` always carries the latest
> resolved set per the cross-project coordination note.  Dryopea-
> side workarounds retire as the relevant code touches them; not
> all retirement happens in one sweep.

### @P375 — `{x:j}` / `to_json()` omitted present-but-empty fields

- **Loft commit:** 83ebd55 ("Fix @P375: …")
- **Found by dryopea:** Plan 01 E4 — `paint_to_mapfile` produced
  a MapFile with `description: ""`, `markers: []`, `waves: []`;
  `{m:j}` dropped all three from the output, so the round-trip
  cast → load got partial JSON that either default-filled or
  hung (until @P372 also shipped).  Reproducer:
  ```loft
  struct S { a: text not null, b: vector<integer>, c: integer not null }
  s = S { a: "", b: [], c: 0 };
  println("{s:j}");
  // pre-fix: {}      post-fix: {"a":"","b":[],"c":0}
  ```
- **Fix:** `{x:j}` and `to_json()` now emit EVERY declared field
  including empty strings / empty vectors / zero integers.
- **Workaround retirement (pending):** `src/save.loft::save_markers`
  no longer needs its "skip-write-if-empty + delete-on-empty"
  branch for the EMISSION reason (the empty-vector reload would
  no longer trip the cast bug — @P373/@P375 both fixed).  The
  delete-on-empty behaviour is still cleaner UX (no zombie sidecar
  on disk after clearing), so the BEHAVIOUR stays but the
  bug-driven rationale is gone.

### @P374 — `return (tuple-of-structs)` rejected vs final-expression tuple

- **Loft commit:** 84b6592 ("Fix @P374: …")
- **Found by dryopea:** Plan 01 integration smoke test —
  `load_map_or_empty(path, palette) -> (PaintedWorld,
  EditorCamera)` rejected the early-return `return (pw, cam);`
  but accepted the same tuple as a final expression.  Identical
  textual halves: `expected __tuple<...>, got (...)`.
- **Fix:** function declaring `-> (A, B)` (structs, rewritten to
  `Reference(__tuple<A, B>)`) now accepts the equivalent
  `return (A{…}, B{…});` form, matching the final-expression
  behaviour.
- **Workaround retirement (pending):** `src/save.loft::load_map_or_empty`
  uses an if-else expression form to dodge this; can rewrite
  with `return` if cleaner reads, but the existing form is
  fine — purely cosmetic retirement.

### @P373 — `text as Struct` corrupts the field before an empty `[]` array

- **Loft commit:** 27560e6 ("Fix @P373: …")
- **Found by dryopea:** Plan 01 E4 — empty `markers: []` /
  `waves: []` in MapFile JSON wrecked the field immediately
  before them.  Reproducer:
  ```loft
  struct Box { name: text not null, items: vector<Item> }
  json = `{"name":"b","items":[]}`;
  b = json as Box;   // observed name=[]  expected name=[b]
  ```
- **Fix:** the empty-array branch in `walk_parsed_into` was
  writing the collection's default to the struct's BASE (field
  0) instead of the collection field's slot.  Corrected.
- **Workaround retirement (pending):** MarkerFile's "non-empty
  vectors only" discipline is no longer bug-driven; can carry
  empty vectors in the on-disk JSON once dryopea decides to.
  Combined with @P375, `save_markers` could simplify
  significantly.

### @P372 — `text as Struct` hangs (infinite loop) for structs over 56 bytes

- **Loft commit:** 58a3167 ("Fix @P372: …")
- **Found by dryopea:** Plan 01 E4 — `text as MapFile` hung
  forever when MapFile had 10 fields.  Originally suspected a
  field-count threshold; root cause turned out to be struct
  BYTE size > 56 (the fixed `database(8)` claim = 64 bytes, with
  the 8-byte header leaving 56 for the payload).  8+ integer
  fields trigger it deterministically; a vector field is one
  reliable way to push past.
- **Fix:** `db_from_text` now sizes the claimed record by the
  declared struct size instead of the fixed 64-byte default;
  larger structs no longer corrupt the heap walker → no
  infinite loop.
- **Workaround retirement (pending):** the 6-field cap on
  MapFile (`src/map_file.loft`) is no longer required.  Plan 04
  § L1 can land its full schema (markers, waves, objective,
  description, …) without splitting into the multi-file
  workaround pattern.  Decision on whether to *actually* fold
  the marker sidecar into MapFile is independent — the sidecar
  has cross-consumer value (@PLAN50 reads markers without
  parsing the rest of MapFile) regardless of whether the cast
  bug is fixed.

### `store_persist_bind` — path-backed user-data Store binding

- **Loft commit:** 4a7e775 (@PLAN38 phase 01c, on `origin/main`)
- **Filed by dryopea:** Designing the persistence destination —
  the world will grow with stencils; serialising every save is
  wasted IO when the runtime already keeps the data in a Store
  buffer that could just as easily be path-backed mmap.  Filed
  asked for an `.loft`-level way to declare *"the user-data
  Store for these records lives at this file path."*
- **Fix:** `pub fn store_persist_bind(r: hash, path: text) ->
  boolean;` (`default/02_images.loft:366`).  Per-instance
  runtime call rather than the declarative `#persist` syntax
  sketched in the original ask, but functionally what was
  asked.  Two modes:
  - Fresh path (not on disk yet) — serialises the current
    in-memory Store at the hash's slot, pads to ≥1024 words
    with a valid tail-free block, mmaps the file.  Existing
    DbRefs remain valid.
  - Existing path — opens via `Store::open`, drops in-memory
    contents in favour of the on-disk image.  Type layout
    must match.
  Fail-soft: returns `false` on any I/O / format error.  Pair
  with `store_durable_check(p)` / `store_durable_seal(p)` for
  crash-safety bracketing.
- **Workaround retirement (pending):** `src/save.loft`'s
  JSON-marshal save path (`save_world`, `save_map_file`,
  `paint_to_mapfile`, `mapfile_to_painted`, plus the marker
  sidecar equivalents) is replaceable with a one-line
  annotation on `PaintedWorld.painted` / `MarkerWorld.markers`.
  When this migration lands, the `MarkerSaveEntry` / `MapFile`
  / `MarkerFile` structs and most of `src/save.loft` go away.
  Strategy carried forward in [`plans/ROADMAP.md` § Persistence
  destination](plans/ROADMAP.md).

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
