# questions.md

Eight questions, committed before `rebuild/` exists. Questions 1 to 6 each trace to a line in `feedback.md`. Questions 7 and 8 check that the rebuild did not break what the feedback said already worked.

Every question is a command with a checkable output. Nothing is graded by a model, so a mod who re-runs both arms should get the same results we did.

## How each arm is run

- **Arm A:** `original/`, the judged commit `5502381`, untouched.
- **Arm B:** `rebuild/`.

Questions 1, 2 and 6 plant a fault. Each one copies the arm into a temp folder, applies the edit shown, and runs the command there. The arm itself is never edited. `run-questions.sh <arm>` does this for every question and writes the raw output to `run-original/` or `run-rebuild/`.

Inputs not already in the arm's own `fixtures/` are in `questions/inputs/`.

---

## From fix 1: anchor each quote to its section

> "quotes left untouched, `§316.2(p)` swapped to `§316.2(o)` and `§316.5` to `§316.4`, and it printed "✓ quote verified" beside both while `--selftest` stayed green."

**Q1. Postal-address citation swapped to a neighbouring provision, with the quote left alone.**
Plant: in `audit.py`, replace every `16 CFR §316.2(p)` with `16 CFR §316.2(o)`.
Run: `python3 audit.py fixtures/clean.eml`
Expected: the postal-address finding does **not** print `✓ quote verified`. It prints the quote-check failure line, because the quoted text is not in §316.2(o).

**Q2. Opt-out citation swapped to a neighbouring provision, with the quote left alone.**
Plant: in `audit.py`, replace every `"16 CFR §316.5"` with `"16 CFR §316.4"`.
Run: `python3 audit.py fixtures/clean.eml`
Expected: the opt-out finding does **not** print `✓ quote verified`.

**Q3. Does the postal-address finding cite the provision that creates the duty?**

> "`§316.2(p)` defines what a valid postal address is, while the duty to include one lives in 15 U.S.C. 7704(a)(5), which is not in your `reference/` at all."

Run: `python3 audit.py fixtures/bad-no-postal-address.eml`
Expected: the FAIL finding cites 15 U.S.C. 7704(a)(5)(A)(iii). Its quote, "a valid physical postal address of the sender", prints `✓ quote verified`. That means the statute text is now in `reference/` and the quote is checked against that section.

## From fix 2: implement the third bar in §316.5

> "An unsubscribe flow demanding full name, mailing address, and account number was sent, and it PASSed directly under the clause forbidding exactly that."

**Q4. The judges' exact unsubscribe flow.**
Run: `python3 audit.py questions/inputs/q4-optout-name-address-account.eml`
The input says: "To unsubscribe, please enter your full name, mailing address, and account number at ..."
Expected: the opt-out finding is `FAIL`.

**Q5. The same bar, without the words "mailing address".**
Run: `python3 audit.py questions/inputs/q5-optout-name-account.eml`
The input says: "To unsubscribe, please provide your full name and account number at ..."
Expected: the opt-out finding is `FAIL`. §316.5 bars "any information other than the recipient's electronic mail address and opt-out preferences". It is not limited to a list of phrases, so the check should not be either.

## From what would have moved us up: the section anchor

> "a citation that resolves but points at the wrong thing is the exact failure this competition is hunting"

**Q6. Does the self-test notice when the section check is switched off?**
Plant: make the quote check always return true (one line in `quote_is_grounded()`).
Run: `python3 audit.py --selftest`
Expected: the self-test **fails**, and it names the planted citation-swap case that slipped through. A self-test that stays green with the check removed proves nothing about the check.

## No-regression: what the feedback said worked

**Q7. Honest email still passes, with every quote verified.**
Run: `python3 audit.py <f>` for each of `fixtures/clean.eml`, `clean-html-only-entities.eml`, `clean-view-in-browser-stub.eml`, `clean-longform-commercial-pitch.eml`
Expected: no FAIL, and no quote-check failure line, in any of the four. This is where a stricter section check could make the rebuild worse, by rejecting a real quote.

**Q8. Garbage is still refused.**

> "Garbage input exits 2 rather than producing a plausible report."

Run: `python3 audit.py fixtures/not-an-email.txt; echo $?`
Expected: exit code `2`, and no report.

---

## Scoring

Each question is pass or fail per arm, against the expected line above. `results.md` reports all eight for both arms, including any question where the rebuild tied or did worse, and what we left alone on purpose.
