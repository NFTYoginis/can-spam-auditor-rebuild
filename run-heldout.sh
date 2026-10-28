#!/usr/bin/env bash
# run-heldout.sh <arm>   (arm = original | rebuild)
#
# Runs the six held-out cases in questions-heldout.md against one arm and writes
# the raw output to run-heldout-<arm>/. Those cases were written by a fresh
# session from rebuild/README.md alone, aimed at breaking it, never fixed against. Each PASS bar
# below is that file's bar, transcribed literally: exit codes and substrings.
set -u

ARM="${1:-}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ "$ARM" != "original" && "$ARM" != "rebuild" ]]; then
  echo "usage: $0 original|rebuild" >&2
  exit 2
fi
[[ -d "$ROOT/$ARM" ]] || { echo "error: $ROOT/$ARM does not exist" >&2; exit 2; }

OUT="$ROOT/run-heldout-$ARM"
rm -rf "$OUT"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.txt"
PY="${PYTHON:-python3}"

W="$(mktemp -d)"
mkdir -p "$W/arm" "$W/questions-heldout"
cp -R "$ROOT/$ARM/." "$W/arm/"
cp -R "$ROOT/questions-heldout/inputs" "$W/questions-heldout/inputs"

{ echo "arm: $ARM"; echo "python: $("$PY" --version 2>&1)"; } > "$SUMMARY"

verdict() { printf "%-4s%-8s%s\n" "$1" "$2" "$3" | tee -a "$SUMMARY"; }
has() { grep -qF -- "$2" "$1"; }

run() {  # run <n>: writes hN.txt, sets RC
  ( cd "$W/arm" && "$PY" audit.py "../questions-heldout/inputs/h$1.eml" ) \
    > "$OUT/h$1.txt" 2> "$OUT/h$1.stderr"
  RC=$?
  echo "exit: $RC" >> "$OUT/h$1.stderr"
}

# check <case> <n> <exit> [must-contain] [must-not-contain...]
# Every case also fails on "Traceback" in stdout.
check() {
  local c="$1" f="$OUT/h$2.txt" code="$3" want="${4:-}" why="" x
  shift 4 2>/dev/null || shift $#
  [[ "$RC" == "$code" ]] || why="exit $RC (bar: $code)"
  [[ -z "$want" ]] || has "$f" "$want" || why="${why:+$why, }no $want"
  for x in "Traceback" "$@"; do
    ! has "$f" "$x" || why="${why:+$why, }stdout has $x"
  done
  if [[ -z "$why" ]]; then verdict "$c" PASS "exit $RC${want:+, $want cited}"
  else verdict "$c" FAIL "$why"; fi
}

run 1; check H1 1 2 "" "316." "7704"
run 2; check H2 2 0
run 3; check H3 3 1 "316.5"
run 4; check H4 4 1 "316.5"
run 5; check H5 5 1 "316.3"
run 6; check H6 6 0 "" "Unsubscribe fee"

rm -rf "$W"
echo "raw output: run-heldout-$ARM/h1.txt .. h6.txt (exit codes in h*.stderr)"
