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

*(none yet — the three filed entries are picked up by the loft
agents; see § Submitted below.)*

## Submitted

> Picked up by the loft project agents (2026-05-27).  Listed
> here for traceability; will move to § Resolved as each is
> confirmed fixed (binary rebuilt + dryopea's reproducer
> behaves as expected).

### Don't warn on division by a literal constant

- **Found while:** Plan 01 E1 — implementing `world_to_hex`
  (axial flat-top inverse).  The math is naturally written as
  divisions by `0.75` and constants like `(2/3)/0.75` etc.
- **Kind:** feature (warning suppression)
- **What dryopea needs:** Loft warns on every `/` because of
  the divide-by-zero hazard ("integer division may produce
  null on divide-by-zero with no defensive check; consider
  `a / b ?? 0` or wrap in `if b != 0 { ... }`").  The warning
  also fires on **float division by a literal non-zero
  constant** (e.g. `x / 2.0`, `x / 0.75`), which is
  unconditionally safe — the divisor is statically known
  non-zero.  Please suppress the warning when the RHS of `/`
  is a non-zero literal constant (integer or float).
- **Workaround in dryopea:** Precompute reciprocals as
  named constants and multiply (`x * 0.8888...` instead of
  `(x * 2.0 / 3.0) / 0.75`).  Works but the formulas read
  less clearly than the math they implement; readers have
  to consult comments to recover the original division
  structure.
- **Loft pointer:** unknown.  Warning emitted from somewhere
  in the parser / type-checker that flags every `/` site.

### `text as vector<Struct>` returns empty vector on valid JSON (silent failure)

- **Found while:** Plan 01 E2 — loading `examples/palette.json`
  (3328 bytes, valid JSON, 11 entries) via
  `file(path).content() as vector<GroundType>` returns
  `vector<GroundType>` with `len == 0`.  No error to stderr;
  `json_errors()` would presumably help but the silent-empty
  result is hard to debug.
- **Kind:** bug (JSON cast)
- **Suspected cause:** the JSON entries carry **extra fields** the
  target struct doesn't declare.  My `GroundType` has 9 fields;
  each `palette.json` entry has 13 (4 extras: `variant`,
  `color_status`, `height_override`, `end_drivable`).  The cast
  may bail silently when JSON has fields the struct doesn't.
  Adding fields to the struct, or trimming the JSON, may fix it
  — but the **silent** behaviour is the bug.
- **Reproducer:**
  ```loft
  struct Item { tag: text, amount: integer }

  fn test_extra_field() {
      // JSON has an "extra" key the struct doesn't declare.
      items = `[{{"tag":"a","amount":1,"extra":"x"}}]` as vector<Item>;
      println("len = {len(items)}");   // observed: 0 (expected: 1)
  }
  ```
  Combined with the assert-doesn't-fail-tests bug below, the
  failure presents as "all tests pass" while every payload
  access reads null.
- **What dryopea needs:** either (a) the cast accepts extra
  fields and ignores them, or (b) the cast errors loudly when
  the JSON has fields the struct doesn't.  Silent empty is
  the worst combination.
- **Workaround in dryopea:** add every extra JSON field to the
  target struct, OR strip the extras from palette.json before
  parsing.
- **Loft pointer:** unknown — the `text as <T>` cast lowering
  in the parser / typer + the JSON cast in
  `src/state/codegen.rs` or wherever the cast runtime lives.

### Test runner doesn't surface assertion / runtime_error failures

- **Found while:** Plan 01 E1 golden-image validation harness —
  trying to make `assert(false, "golden missing")` fail the test.
- **Kind:** bug (test framework)
- **What dryopea needs:** `loft test` / `--tests` to mark a
  test as FAILED when `state.database.runtime_error` is set
  after the test function returns.

  **Current behaviour:** when an `assert(condition, msg)` fires
  with `!condition`, `n_assert` in `src/native.rs` populates
  `stores.runtime_error` (the C66 "typed runtime error" path).
  The dispatch loop in `state/mod.rs::execute_argv` short-
  circuits (`code_pos = u32::MAX`) and `execute_argv` returns
  cleanly.  No Rust panic occurs.  The test runner's
  `catch_unwind(execute_argv(...))` returns `Ok(())` → the test
  is reported as **PASSED** even though the assertion failed.

  Reproducer:
  ```loft
  // tests/x.loft
  fn test_failing_assert() {
      println("about to assert(false)");
      assert(false, "this should fail the test");
      println("LINE AFTER — does not print, so execution halted");
  }
  ```
  ```
  $ loft --tests tests/x.loft
  about to assert(false)
    ok    tests/x.loft  (1 fn: test_failing_assert)
  test result: ok. 1 passed; 1 file
  ```
  Same for `panic("msg")`, `div by zero`, and any
  `runtime_error`-based fault.

  **Suggested fix:** after `execute_argv` returns in the test
  runner (`src/test_runner.rs:1033`), check
  `state.database.runtime_error.is_some()` (and/or
  `had_fatal`).  If so, treat the test as failed with the
  error's message.
- **Workaround in dryopea:** `assert_golden` in
  `src/golden.loft` writes a loud failure marker to stderr +
  a `tests/actual/_FAILED_<name>.txt` file on
  mismatch.  CI / dev workflow greps for that marker after
  `loft test` to determine real pass/fail.
- **Loft pointer:** test_runner.rs:1033 (catch_unwind site);
  native.rs:480 (n_assert sets runtime_error);
  state/mod.rs:1966 (dispatch-loop short-circuit).

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

*(none yet)*
