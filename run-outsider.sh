#!/usr/bin/env bash
# run-outsider.sh <arm>   (arm = original | rebuild)
#
# Runs the five questions in questions-outsider.md against one arm and writes
# the raw output to run-outsider-<arm>/. Those questions were written by a
# fresh session from rebuild/README.md alone, not by us. Each PASS bar below is
# that file's bar, transcribed literally: exit codes and substrings only.
set -u

ARM="${1:-}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ "$ARM" != "original" && "$ARM" != "rebuild" ]]; then
  echo "usage: $0 original|rebuild" >&2
  exit 2
fi
[[ -d "$ROOT/$ARM" ]] || { echo "error: $ROOT/$ARM does not exist" >&2; exit 2; }

OUT="$ROOT/run-outsider-$ARM"
rm -rf "$OUT"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.txt"
PY="${PYTHON:-python3}"

# Fresh copy of the arm, with questions-outsider/inputs/ one level up so the
# commands in questions-outsider.md run exactly as written.
W="$(mktemp -d)"
mkdir -p "$W/arm" "$W/questions-outsider"
cp -R "$ROOT/$ARM/." "$W/arm/"
cp -R "$ROOT/questions-outsider/inputs" "$W/questions-outsider/inputs"

{ echo "arm: $ARM"; echo "python: $("$PY" --version 2>&1)"; } > "$SUMMARY"

verdict() {  # verdict <Q> <PASS|FAIL> <why>
  printf '%-4s%-8s%s\n' "$1" "$2" "$3" | tee -a "$SUMMARY"
}
has() { grep -qF -- "$2" "$1"; }

run() {  # run <n>: writes oN.txt, sets RC
  ( cd "$W/arm" && "$PY" audit.py "../questions-outsider/inputs/o$1.eml" ) \
    > "$OUT/o$1.txt" 2> "$OUT/o$1.stderr"
  RC=$?
  echo "exit: $RC" >> "$OUT/o$1.stderr"
}

# O1: exit 2; stdout has neither "quote verified" nor "AUTOMATED"
run 1; F="$OUT/o1.txt"
if [[ "$RC" == 2 ]] && ! has "$F" "quote verified" && ! has "$F" "AUTOMATED"; then
  verdict O1 PASS "exit 2, no report"
else verdict O1 FAIL "exit $RC"; fi

# O2: exit is not 2; stdout contains "OUT-OF-SCOPE"
run 2; F="$OUT/o2.txt"
if [[ "$RC" != 2 ]] && has "$F" "OUT-OF-SCOPE"; then
  verdict O2 PASS "exit $RC, audited, OUT-OF-SCOPE named"
else verdict O2 FAIL "exit $RC$(has "$F" OUT-OF-SCOPE || echo ', no OUT-OF-SCOPE')"; fi

# O3: exit 1
run 3
if [[ "$RC" == 1 ]]; then verdict O3 PASS "exit 1"
else verdict O3 FAIL "exit $RC (bar: 1)"; fi

# O4: exit 0; stdout contains "quote verified" and "OUT-OF-SCOPE"
run 4; F="$OUT/o4.txt"
if [[ "$RC" == 0 ]] && has "$F" "quote verified" && has "$F" "OUT-OF-SCOPE"; then
  verdict O4 PASS "exit 0, quotes verified, OUT-OF-SCOPE named"
else verdict O4 FAIL "exit $RC (bar: 0)"; fi

# O5: exit 1
run 5
if [[ "$RC" == 1 ]]; then verdict O5 PASS "exit 1"
else verdict O5 FAIL "exit $RC (bar: 1)"; fi

rm -rf "$W"
echo "raw output: run-outsider-$ARM/o1.txt .. o5.txt (exit codes in o*.stderr)"
