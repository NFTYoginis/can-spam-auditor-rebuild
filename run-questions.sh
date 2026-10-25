#!/usr/bin/env bash
# run-questions.sh <arm>   (arm = original | rebuild)
#
# Runs the eight questions in questions.md against one arm and writes the raw
# output to run-<arm>/. Each run works on a fresh copy of the arm in a temp
# folder; the arm itself is never edited. Q1, Q2 and Q6 apply their plant to
# that copy first and record how many places it changed (a plant that changed
# nothing is reported, never counted as a result).
#
# Every verdict is a literal string or exit-code check, written below next to
# the question it grades. Nothing is graded by a model.
set -u

ARM="${1:-}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ "$ARM" != "original" && "$ARM" != "rebuild" ]]; then
  echo "usage: $0 original|rebuild" >&2
  exit 2
fi
[[ -d "$ROOT/$ARM" ]] || { echo "error: $ROOT/$ARM does not exist" >&2; exit 2; }

OUT="$ROOT/run-$ARM"
rm -rf "$OUT"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.txt"
PY="${PYTHON:-python3}"

# Fresh copy of the arm, with questions/inputs/ beside it so the commands in
# questions.md run exactly as written.
fresh_copy() {
  local dir
  dir="$(mktemp -d)"
  cp -R "$ROOT/$ARM/." "$dir/"
  mkdir -p "$dir/questions"
  cp -R "$ROOT/questions/inputs" "$dir/questions/inputs"
  echo "$dir"
}

# Plant: literal replace in audit.py. Prints the number of replacements.
plant_replace() {
  "$PY" -I - "$1/audit.py" "$2" "$3" <<'PYEOF'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(path, encoding="utf-8").read()
n = src.count(old)
open(path, "w", encoding="utf-8").write(src.replace(old, new))
print(n)
PYEOF
}

# Plant Q6: first statement of quote_is_grounded() becomes `return True`.
plant_force_true() {
  "$PY" -I - "$1/audit.py" <<'PYEOF'
import sys
path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
n = 0
for i, line in enumerate(lines):
    if line.lstrip().startswith("def quote_is_grounded("):
        indent = line[: len(line) - len(line.lstrip())] + "    "
        j, depth = i, 0
        while True:  # walk to the end of the signature
            depth += lines[j].count("(") - lines[j].count(")")
            if depth == 0 and lines[j].rstrip().endswith(":"):
                break
            j += 1
        lines.insert(j + 1, indent + "return True  # PLANT Q6: quote check forced true")
        n += 1
        break
open(path, "w", encoding="utf-8").write("\n".join(lines))
print(n)
PYEOF
}

# Print the block of one finding (from its "## [" heading to the next) out of
# a Markdown report, located by its "**Rule:** <rule_id>" line.
finding_block() {
  "$PY" -I - "$1" "$2" <<'PYEOF'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
for block in text.split("\n## [")[1:]:
    if f"**Rule:** {sys.argv[2]}" in block:
        print("## [" + block)
        break
PYEOF
}

has() { grep -qF -- "$2" "$1"; }

verdict() {  # verdict <Q> <PASS|FAIL|INVALID> <why>
  printf '%-3s %-7s %s\n' "$1" "$2" "$3" | tee -a "$SUMMARY"
}

{
  echo "arm: $ARM"
  echo "python: $("$PY" --version 2>&1)"
  echo "grading: literal string / exit-code checks, defined in run-questions.sh"
  echo
} > "$SUMMARY"

# ---------------------------------------------------------------- Q1
W="$(fresh_copy)"; F="$OUT/q1.txt"
N="$(plant_replace "$W" '16 CFR §316.2(p)' '16 CFR §316.2(o)')"
{
  echo "\$ plant: replace every '16 CFR §316.2(p)' with '16 CFR §316.2(o)' in audit.py  (replaced: $N)"
  echo "\$ python3 audit.py fixtures/clean.eml"
  (cd "$W" && "$PY" audit.py fixtures/clean.eml 2>&1); echo "[exit $?]"
} > "$F"
finding_block "$F" rule-4-postal-address > "$OUT/q1.block"
if [[ "$N" == 0 ]]; then verdict Q1 INVALID "plant changed nothing"
elif [[ ! -s "$OUT/q1.block" ]]; then verdict Q1 FAIL "no postal-address finding in output"
elif has "$OUT/q1.block" "✓ quote verified"; then verdict Q1 FAIL "postal-address finding still prints '✓ quote verified'"
elif has "$OUT/q1.block" "✗ QUOTE NOT FOUND"; then verdict Q1 PASS "postal-address finding prints the quote-check failure line"
else verdict Q1 FAIL "no '✓ quote verified' but no failure line either"; fi
rm -rf "$W"

# ---------------------------------------------------------------- Q2
W="$(fresh_copy)"; F="$OUT/q2.txt"
N="$(plant_replace "$W" '"16 CFR §316.5"' '"16 CFR §316.4"')"
{
  echo "\$ plant: replace every '\"16 CFR §316.5\"' with '\"16 CFR §316.4\"' in audit.py  (replaced: $N)"
  echo "\$ python3 audit.py fixtures/clean.eml"
  (cd "$W" && "$PY" audit.py fixtures/clean.eml 2>&1); echo "[exit $?]"
} > "$F"
finding_block "$F" rule-5-opt-out > "$OUT/q2.block"
if [[ "$N" == 0 ]]; then verdict Q2 INVALID "plant changed nothing"
elif [[ ! -s "$OUT/q2.block" ]]; then verdict Q2 FAIL "no opt-out finding in output"
elif has "$OUT/q2.block" "✓ quote verified"; then verdict Q2 FAIL "opt-out finding still prints '✓ quote verified'"
else verdict Q2 PASS "opt-out finding does not print '✓ quote verified'"; fi
rm -rf "$W"

# ---------------------------------------------------------------- Q3
W="$(fresh_copy)"; F="$OUT/q3.txt"
{
  echo "\$ python3 audit.py fixtures/bad-no-postal-address.eml"
  (cd "$W" && "$PY" audit.py fixtures/bad-no-postal-address.eml 2>&1); echo "[exit $?]"
} > "$F"
finding_block "$F" rule-4-postal-address > "$OUT/q3.block"
B="$OUT/q3.block"
if ! has "$B" "## [FAIL]"; then verdict Q3 FAIL "postal-address finding is not FAIL"
elif ! has "$B" "15 U.S.C. 7704(a)(5)(A)(iii)"; then verdict Q3 FAIL "FAIL finding does not cite 15 U.S.C. 7704(a)(5)(A)(iii)"
elif ! has "$B" "a valid physical postal address of the sender"; then verdict Q3 FAIL "statute quote not printed"
elif has "$B" "✗"; then verdict Q3 FAIL "a quote on the finding failed the check"
elif has "$B" "✓ quote verified"; then verdict Q3 PASS "cites 7704(a)(5)(A)(iii), statute quote verified"
else verdict Q3 FAIL "no '✓ quote verified'"; fi
rm -rf "$W"

# ---------------------------------------------------------------- Q4, Q5
for Q in q4:q4-optout-name-address-account.eml q5:q5-optout-name-account.eml; do
  q="${Q%%:*}"; input="${Q#*:}"; QU="$(echo "$q" | tr q Q)"
  W="$(fresh_copy)"; F="$OUT/$q.txt"
  {
    echo "\$ python3 audit.py questions/inputs/$input"
    (cd "$W" && "$PY" audit.py "questions/inputs/$input" 2>&1); echo "[exit $?]"
  } > "$F"
  finding_block "$F" rule-5-opt-out > "$OUT/$q.block"
  if has "$OUT/$q.block" "## [FAIL]"; then verdict "$QU" PASS "opt-out finding is FAIL"
  else verdict "$QU" FAIL "opt-out finding is not FAIL: $(head -1 "$OUT/$q.block")"; fi
  rm -rf "$W"
done

# ---------------------------------------------------------------- Q6
W="$(fresh_copy)"; F="$OUT/q6.txt"
N="$(plant_force_true "$W")"
{
  echo "\$ plant: first line of quote_is_grounded() becomes 'return True'  (planted: $N)"
  echo "\$ python3 audit.py --selftest"
  (cd "$W" && "$PY" audit.py --selftest 2>&1); echo "[exit $?]"
} > "$F"
RC="$(tail -1 "$F" | tr -dc 0-9)"
if [[ "$N" == 0 ]]; then verdict Q6 INVALID "plant changed nothing"
elif [[ "$RC" == 0 ]] || has "$F" "SELFTEST PASSED"; then verdict Q6 FAIL "self-test stays green with the quote check forced true"
elif grep -iE '^\[FAIL\].*citation.swap' "$F" >/dev/null; then verdict Q6 PASS "self-test fails and names the citation-swap case"
else verdict Q6 FAIL "self-test fails but names no citation-swap case"; fi
rm -rf "$W"

# ---------------------------------------------------------------- Q7
W="$(fresh_copy)"; F="$OUT/q7.txt"; : > "$F"; bad=""
for fx in clean.eml clean-html-only-entities.eml clean-view-in-browser-stub.eml clean-longform-commercial-pitch.eml; do
  {
    echo "\$ python3 audit.py fixtures/$fx"
    (cd "$W" && "$PY" audit.py "fixtures/$fx" > "$W/.q7out" 2>&1); rc=$?
    cat "$W/.q7out"; echo "[exit $rc]"; echo
  } >> "$F"
  if grep -qF "## [FAIL]" "$W/.q7out" || grep -qF "✗" "$W/.q7out" || ! grep -qF "# CAN-SPAM audit" "$W/.q7out"; then bad="$bad $fx"; fi
done
if [[ -z "$bad" ]]; then verdict Q7 PASS "4/4 clean fixtures: no FAIL, no quote-check failure"
else verdict Q7 FAIL "FAIL or quote-check failure in:$bad"; fi
rm -rf "$W"

# ---------------------------------------------------------------- Q8
W="$(fresh_copy)"; F="$OUT/q8.txt"
{
  echo "\$ python3 audit.py fixtures/not-an-email.txt; echo \$?"
  (cd "$W" && "$PY" audit.py fixtures/not-an-email.txt > "$W/.q8out" 2> "$W/.q8err"); rc=$?
  echo "[stdout]"; cat "$W/.q8out"; echo "[stderr]"; cat "$W/.q8err"; echo "$rc"
} > "$F"
RC="$(tail -1 "$F")"
if [[ "$RC" == 2 && ! -s "$W/.q8out" ]]; then verdict Q8 PASS "exit 2, no report"
else verdict Q8 FAIL "exit $RC, stdout bytes $(wc -c < "$W/.q8out" | tr -d ' ')"; fi
rm -rf "$W"

echo
echo "raw output: run-$ARM/q1.txt .. q8.txt   (*.block = the one finding each verdict read)"
