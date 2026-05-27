#!/usr/bin/env bash
# Copyright (c) 2026 Jurjen Stellingwerff
# SPDX-License-Identifier: LGPL-3.0-or-later
#
# Run dryopea's test suite.
#
# Golden-image tests assert via `assert_golden` in src/golden.loft;
# loft's test runner reports the assertion as FAILED (since @P367
# landed), so this wrapper is just a thin convenience over
# `loft test --lib …`.  Refreshes tests/actual/ before each run so
# a stale PNG from a removed test can't masquerade as current.
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

# Drop stale actuals so a vanished test can't leave a PNG or JSON
# behind from a previous run.
rm -f "$ROOT"/tests/actual/*.png "$ROOT"/tests/actual/*.json

cd "$ROOT"
exec "$LOFT" test --lib "$LIB" --no-warnings
