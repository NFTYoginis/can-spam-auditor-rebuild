# results.md

Arm A is `original/`, the judged commit `5502381`. Arm B is `rebuild/`. Both arms ran through `./run-questions.sh <arm>`. The raw output is in `run-original/` and `run-rebuild/`, and each folder's `summary.txt` has the one-line verdicts.

Every verdict is a literal string or exit-code check, written in `run-questions.sh`. That script and `questions.md` were committed in commit 2, before `rebuild/` was committed, and neither has changed since. We wrote the questions ourselves, from the judges' feedback, so the questions are ours and not an independent test.

## Question by question

| Q | What it asks | A: `original/` | B: `rebuild/` | |
|---|---|---|---|---|
| 1 | `§316.2(p)` → `§316.2(o)` in `audit.py`, quote kept. Does the postal finding still say verified? | **FAIL**: still prints `✓ quote verified` | **PASS**: prints `✗ QUOTE NOT FOUND under 16 CFR §316.2(o)` | fixed |
| 2 | `§316.5` → `§316.4`, quote kept. Does the opt-out finding still say verified? | **FAIL**: still prints `✓ quote verified` | **PASS** | fixed |
| 3 | Does the postal FAIL cite 15 U.S.C. 7704(a)(5)(A)(iii), with the statute quote verified? | **FAIL**: cites `§316.2(p)` only, and 7704 is not in `reference/` | **PASS** | fixed |
| 4 | Unsubscribe demands full name, mailing address and account number | **FAIL**: opt-out PASSes | **PASS**: opt-out FAILs | fixed |
| 5 | The same, without "mailing address" | **FAIL**: opt-out PASSes | **PASS**: opt-out FAILs | fixed |
| 6 | Force `quote_is_grounded()` to return true. Does `--selftest` go red and name the citation swap? | **FAIL**: `SELFTEST PASSED`, exit 0 | **PASS**: exit 1, eight `[FAIL] citation-swap canary` lines | fixed |
| 7 | The four clean fixtures: no FAIL and no quote-check failure | **PASS** | **PASS** | tie |
| 8 | `not-an-email.txt` exits 2 with no report | **PASS** | **PASS** | tie |

**Totals: A passes 2 of 8 and B passes 8 of 8**, on questions we wrote, with `python3` 3.9.6 on macOS. Q7 and Q8 tie. No question got worse.

## Ties

- **Q7.** This is where the rebuild could have got worse. A section check drawn too tightly would reject a real quote. It didn't: all seven findings on all four clean fixtures verify under the provision they cite. The tightest case is rule 2, which cites `§316.3(a)(2)` while its quote sits in `(a)(2)(i)`. That passes because anchors nest. A citation to a paragraph covers its subparagraphs, and a citation to a subparagraph covers only itself.
- **Q8.** Same as the original. `parse_eml()` was not touched.

## What is still weak, or got worse in ways the questions don't measure

- **The third §316.5 bar is a word list (Q4, Q5).** It FAILs when the opt-out sentence, or the sentence after it, contains both a request word ("enter", "provide", "with your", "required" and similar) and a personal field it names (a name, an address other than the email address, an account, member or customer number, an ID, a phone number, a date of birth, a ZIP code, a password, or a reason for leaving). We tried inputs it gets wrong:
  - **False FAIL:** "To unsubscribe, enter your email address. Your account number is not needed." It doesn't read negation.
  - **Misses:** "name, account number, and ZIP" with no request word. A request two sentences after the opt-out line. A field it doesn't list ("your employer and job title"). Any language other than English. And anything the unsubscribe page asks for that the email doesn't mention.
  §316.5 bars "any information other than the recipient's electronic mail address and opt-out preferences". Q5 is right that this is not a phrase list, but our check still is one. It is a wider list than before, and that's all.
- **New false-FAIL risk.** The original could not FAIL an opt-out for asking for information, so it could not false-FAIL one either. The rebuild can, as shown above. Three new fixtures pin the behaviour: two that must FAIL, and one asking only for the email address that must PASS.
- **Q1 in arm B, read closely.** The rebuilt postal finding carries two quotes: the duty under 7704(a)(5)(A)(iii) and the definition under `§316.2(p)`. The Q1 plant moves only the second. The finding-level line prints `✗ QUOTE NOT FOUND under 16 CFR §316.2(o)` with no `✓`, and the per-quote line still shows the 7704 quote as found "in that provision", because it is. We read Q1 as asking about the finding's verdict, and the harness checks that verdict.
- **Anchors are a new way to fail.** A marker must be a whole line, and the provision key must match the printed citation after light normalisation (`C.F.R.` → `CFR`, `§ 316` → `§316`). A citation written some other way, or a provision nobody anchored, fails the quote check. We chose failing closed over passing a quote under a provision we can't locate. An unclosed or duplicate anchor stops the run with an error rather than guessing.
- **Things dropped from `rebuild/`:** the CI workflow and the `docs/` landing page. Both are still in `original/`. The brief listed what `rebuild/` needed, and neither was on it.

## What we left alone on purpose

- **`rule-map.md`'s structure.** The judges called it the best index in the round. The rebuild edits only the rows whose citation or check changed (rules 3, 4, 5 and 7) and adds a short section on anchors.
- **The refusals.** Garbage input still exits 2. A clean run still can't mean "compliant". The output schema still has nowhere for a fix to go. `--judge-mode` is unchanged.
- **The two out-of-scope rules** (honoring an opt-out within 10 business days, and monitoring third-party senders). They are still named on every run and not checked. They now cite the exact provision or guide heading they quote.
- **Rule 3 still cites the FTC guide**, now its "Identify the message as an ad" heading, even though 15 U.S.C. 7704(a)(5)(A)(i) is in `reference/` now. The feedback didn't raise it, and we kept the change set to what it did raise.
- **The fee and multi-step bars.** They still scan 150 characters around the first opt-out cue. Only the new third bar uses sentence scope.
- **Primary-purpose classification (§316.3).** It is still not attempted, and the rule 3 and rule 5 messages still say so.

## About the 2026-09-18 fix in the old repo

After judging, the old repo got commit `b55cdfc`, which keyed the quote check by the finding's `rule_id`. Run through this same harness (on a scratch copy, so not committed here), it passes 3 of 8: Q4, Q7 and Q8. Q1, Q2, Q3, Q5 and Q6 still fail. The judges changed the printed citation and left the rule ID alone, so a lookup by rule ID still hit the right text. That's why this rebuild starts from the judged commit, `5502381`, and keys the check by the provision the finding prints. `b55cdfc` isn't one of the two arms here.

## Re-checking that anchors didn't change the law

The markers are added lines. Stripping them gives back the judged commit's text exactly, apart from one added paragraph in each file's header that explains the anchors:

```
diff <(grep -v '^<!-- /\?anchor:' rebuild/reference/16-cfr-part-316.md) original/reference/16-cfr-part-316.md
diff <(grep -v '^<!-- /\?anchor:' rebuild/reference/ftc-compliance-guide.md) original/reference/ftc-compliance-guide.md
```

`rebuild/reference/15-usc-7704-a5.md` is new. It was taken from Cornell LII on 2026-10-25 and holds paragraph (a)(5) only.

## After the honesty gate

**2026-10-25:** after Research's honesty gate, a quote-check failure in `rebuild/` now prints a `✗` line in the report header and exits `3`, which outranks `1`. A malformed `reference/` exits `3` too. We re-ran `./run-questions.sh rebuild`: only the raw Q1 and Q2 output changed (the header line, and exit `0` → `3`). The totals did not change: A 2 of 8, B 8 of 8.
