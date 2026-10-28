#!/usr/bin/env bash
# run-adversarial.sh <arm>   (arm = original | rebuild)
#
# Runs the six cases in questions-adversarial.md against one arm and writes
# the raw output to run-adversarial-<arm>/. Those cases were written by a fresh
# session from rebuild/README.md alone, aimed at breaking it. Each PASS bar
# below is that file's bar, transcribed literally: exit codes and substrings.
set -u

ARM="${1:-}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ "$ARM" != "original" && "$ARM" != "rebuild" ]]; then
  echo "usage: $0 original|rebuild" >&2
  exit 2
fi
[[ -d "$ROOT/$ARM" ]] || { echo "error: $ROOT/$ARM does not exist" >&2; exit 2; }

OUT="$ROOT/run-adversarial-$ARM"
rm -rf "$OUT"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.txt"
PY="${PYTHON:-python3}"

W="$(mktemp -d)"
mkdir -p "$W/arm" "$W/questions-adversarial"
cp -R "$ROOT/$ARM/." "$W/arm/"
cp -R "$ROOT/questions-adversarial/inputs" "$W/questions-adversarial/inputs"

{ echo "arm: $ARM"; echo "python: $("$PY" --version 2>&1)"; } > "$SUMMARY"

verdict() { printf '%-4s%-8s%s\n' "$1" "$2" "$3" | tee -a "$SUMMARY"; }
has() { grep -qF -- "$2" "$1"; }

run() {  # run <n>: writes aN.txt, sets RC
  ( cd "$W/arm" && "$PY" audit.py "../questions-adversarial/inputs/a$1.eml" ) \
    > "$OUT/a$1.txt" 2> "$OUT/a$1.stderr"
  RC=$?
  echo "exit: $RC" >> "$OUT/a$1.stderr"
}

exit_is() {  # exit_is <case> <code>
  if [[ "$RC" == "$2" ]]; then verdict "$1" PASS "exit $RC"
  else verdict "$1" FAIL "exit $RC (bar: $2)"; fi
}

# A1, A2, A5: exit 0
run 1; exit_is A1 0
run 2; exit_is A2 0

# A3: exit 1 AND stdout contains "316.5"
run 3
if [[ "$RC" == 1 ]] && has "$OUT/a3.txt" "316.5"; then verdict A3 PASS "exit 1, 316.5 cited"
else verdict A3 FAIL "exit $RC (bar: 1 with 316.5)"; fi

# A4: exit is not 2 AND stdout is non-empty
run 4
if [[ "$RC" != 2 && -s "$OUT/a4.txt" ]]; then verdict A4 PASS "exit $RC, report printed"
else verdict A4 FAIL "exit $RC, stdout bytes $(wc -c < "$OUT/a4.txt" | tr -d ' ')"; fi

run 5; exit_is A5 0

# A6: exit 1 AND stdout contains "316.3"
run 6
if [[ "$RC" == 1 ]] && has "$OUT/a6.txt" "316.3"; then verdict A6 PASS "exit 1, 316.3 cited"
else verdict A6 FAIL "exit $RC (bar: 1 with 316.3)"; fi

rm -rf "$W"
echo "raw output: run-adversarial-$ARM/a1.txt .. a6.txt (exit codes in a*.stderr)"
