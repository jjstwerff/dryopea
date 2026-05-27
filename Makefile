# Copyright (c) 2026 Jurjen Stellingwerff
# SPDX-License-Identifier: LGPL-3.0-or-later
#
# ==== What can this Makefile do for you? ================================
#
# If you just want to try things:
#
#   make play       Launch the interactive editor (E1-live) in a 960x720
#                   GL window.  Loads dryopea_save.json from cwd if
#                   present; auto-saves on exit.  WASD pan, scroll zoom,
#                   1-9 0 - = palette select, Ctrl+S save, Esc exit.
#
#   make play MAP=starter_01
#                   Same, but edits the named map at
#                   maps/starter_01.json + maps/starter_01_markers.json
#                   instead of the default single-slot save.  The maps/
#                   directory is auto-created on first save.
#
#   make test       Run the dryopea test suite via scripts/test.sh.
#                   Refreshes tests/actual/ first so stale artefacts
#                   can't masquerade as current.  ~5 seconds.
#
#   make help       Print this overview again.
#
# If you are working on dryopea itself:
#
#   make check FILE=src/<file>.loft
#                   Parse-check a single .loft file without running it.
#                   Equivalent to `loft --native-emit /tmp/x.rs --lib …`.
#                   Quick syntax/type sanity for an edit in progress.
#
#   make loft       Rebuild the loft binary in $(LOFT_ROOT).  Run this
#                   after pulling loft, or when the dryopea suite trips
#                   on a fresh loft feature.  ~20s release build.
#
#   make clean      Wipe tests/actual/ plus the cwd save file
#                   (dryopea_save.json), so the next launch starts cold.
#
# Tunables (env or `make VAR=…`):
#
#   LOFT_ROOT       Path to the loft checkout.  Default: ../loft.
#   LOFT_BIN        Path to the loft binary.  Default: $(LOFT_ROOT)/target/release/loft.
#   LOFT_LIB        Path to loft's stdlib.    Default: $(LOFT_ROOT)/lib.
#
# Every target above is defined as a real rule later in this file.
# Scroll down to any name to see exactly what it does.
# =========================================================================

LOFT_ROOT ?= $(CURDIR)/../loft
LOFT_BIN  ?= $(LOFT_ROOT)/target/release/loft
LOFT_LIB  ?= $(LOFT_ROOT)/lib

.PHONY: help play test check loft clean

# ── Help ─────────────────────────────────────────────────────────

# Print the overview at the top of this file.  Useful when you land on
# a fresh checkout and want to know what buttons are available without
# reading the whole Makefile.
help:
	@sed -n '/^# ==== What can this Makefile do for you/,/^# ====/p' Makefile \
	  | sed 's/^# \{0,1\}//'

# ── Common-use targets ───────────────────────────────────────────

# Launch the interactive editor.  Fails fast with a clear message if
# the loft binary is missing — `make loft` rebuilds it.  Pass
# `MAP=<name>` to edit a named map under maps/ instead of the default
# single-slot save.
play:
	@if [ ! -x "$(LOFT_BIN)" ]; then \
	  echo "ERROR: loft binary not found at $(LOFT_BIN)"; \
	  echo "Run 'make loft' to build it, or set LOFT_BIN."; \
	  exit 2; \
	fi
	$(LOFT_BIN) --lib $(LOFT_LIB) src/main.loft $(MAP)

# Full test suite.  Delegates to scripts/test.sh (single source of
# truth for the invocation — that script also cleans tests/actual/
# and respects LOFT_BIN).
test:
	@LOFT_BIN=$(LOFT_BIN) scripts/test.sh

# ── Development helpers ──────────────────────────────────────────

# Parse-check a single .loft file.  Pass FILE=src/whatever.loft.
# Emits Rust to /tmp (discarded) — we only care about whether the
# loft frontend accepts the file.  Surfaces syntax errors + type
# warnings without running the program.
check:
	@if [ -z "$(FILE)" ]; then \
	  echo "Usage: make check FILE=src/<file>.loft"; \
	  exit 2; \
	fi
	$(LOFT_BIN) --native-emit /tmp/dryopea_check.rs --lib $(LOFT_LIB) $(FILE)

# Rebuild the loft binary.  Cargo is incremental, so this is cheap
# after the first build (~2s incremental, ~20s from clean).
loft:
	cd $(LOFT_ROOT) && cargo build --release

# Drop runtime save state and stale test artefacts.  scripts/test.sh
# also wipes tests/actual/* between runs, so a forgotten `make clean`
# isn't fatal — this target exists for explicit "start cold" intent.
clean:
	rm -f dryopea_save.json dryopea_save_markers.json
	rm -f tests/actual/*.png tests/actual/*.json
