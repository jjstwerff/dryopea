#!/usr/bin/env bash
# Copyright (c) 2026 Jurjen Stellingwerff
# SPDX-License-Identifier: LGPL-3.0-or-later
#
# Run dryopea's test suite + the golden-image post-check.
#
# Until loft's test runner surfaces runtime_error / assertion
# failures as test FAIL (see QUESTIONS_FOR_LOFT.md), golden-image
# mismatches are signalled via marker files in tests/actual/.
# This wrapper script:
#   1. Cleans previous run's marker files.
#   2. Invokes `loft test`.
#   3. Lists any _FAILED_*.txt markers.
#   4. Exits non-zero if any markers exist.
#
# Usage:  scripts/test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOFT="${LOFT_BIN:-$ROOT/../loft/target/release/loft}"
LIB="$ROOT/../loft/lib"

if [[ ! -x "$LOFT" ]]; then
    echo "ERROR: loft binary not found at $LOFT" >&2
    echo "Set LOFT_BIN to override." >&2
    exit 2
fi

# Clean prior markers + previous actuals so a stale FAIL doesn't
# carry over.
rm -f "$ROOT"/tests/actual/_FAILED_*.txt
rm -f "$ROOT"/tests/actual/*.png

cd "$ROOT"
"$LOFT" test --lib "$LIB" --no-warnings
RC=$?

# Surface golden failures explicitly (loft test runner doesn't yet
# fail on assertion-based failures — see QUESTIONS_FOR_LOFT.md).
shopt -s nullglob
markers=( "$ROOT"/tests/actual/_FAILED_*.txt )
if (( ${#markers[@]} > 0 )); then
    echo
    echo "=== golden failures (${#markers[@]}) ==="
    for m in "${markers[@]}"; do
        echo "  $(basename "$m")"
        sed 's/^/    /' "$m"
    done
    echo
    echo "Review tests/actual/*.png — if a render is correct, copy to tests/golden/."
    exit 1
fi

exit "$RC"
