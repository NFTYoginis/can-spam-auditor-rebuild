# Worked examples

Both outputs below are pasted verbatim from real `audit.py` runs against the fixture files named — not narrated, not fabricated. Reproduce either one yourself: `python3 audit.py fixtures/<file>`.

Both use invented businesses. Per a 2026-09-04 build-time review, the second example is deliberately **not** drawn from any real operator email-ops incident, even anonymized — it's a synthetic fixture built to the same defect *shape* (a Reply-To that doesn't match the From domain; a missing requirement elsewhere), with no specifics that trace back to anything real. (Build history for this decision lives in the build-tooling repo that produced this one, not inside this repo — nothing to check here, just noting why the example is synthetic rather than a real anonymized incident.)

---

## Example 1 — a clean pass

**Input:** `fixtures/clean.eml` — a plain marketing email for a fictional yoga studio, with an ad disclosure, a real-shaped postal address, and a working single-step opt-out link.

**Command:** `python3 audit.py fixtures/clean.eml`

**Output:**

```
# CAN-SPAM audit — clean.eml

**0 FAIL** / 4 PASS / 1 NEEDS-REVIEW / 2 out of scope

## [PASS] Accurate header information — `AUTOMATED`
- **Rule:** rule-1-header-accuracy
- **Citation:** 16 CFR §316.2(m) (✓ quote verified in reference/, under the provision cited)
- **Quoted:** "The definition of the term "sender" is the same as the definition of that term in the CAN-SPAM Act, 15 U.S.C. 7702(16)"
- From header present and well-formed; Reply-To (if present) shares its domain.

## [NEEDS-REVIEW] Non-deceptive subject line — `AI-ASSISTED`
- **Rule:** rule-2-subject-line
- **Citation:** 16 CFR §316.3(a)(2) (✓ quote verified in reference/, under the provision cited)
- No transactional-subject pattern detected. Whether a subject line 'accurately reflects the content of the message' in the general case is a judgment call this checker doesn't attempt — flagged AI-ASSISTED rather than silently passed.

## [PASS] Message identified as an advertisement — `AUTOMATED`
- **Rule:** rule-3-ad-disclosure
- An explicit ad/marketing/promotional disclosure phrase is present in the body.

## [PASS] Valid physical postal address present — `AUTOMATED`
- **Rule:** rule-4-postal-address
- A street-address-shaped pattern (or PO Box) is present in the body.

## [PASS] Working, one-step, no-fee opt-out mechanism — `AUTOMATED`
- **Rule:** rule-5-opt-out
- Opt-out language is present with no fee-gating, multi-step, or extra-information language detected nearby.

## [SKIPPED] Opt-out honored within 10 business days — `OUT-OF-SCOPE`
- A static single-email auditor has no way to observe what happens after the email is sent.

## [SKIPPED] Monitoring third-party senders acting on your behalf — `OUT-OF-SCOPE`
- Auditing a third party's ongoing conduct is not something a single static artifact can check.
```

(trimmed here for length — the real run also prints each finding's full citation and exact quoted regulatory text; see the file itself)

**What this demonstrates:** even a fully clean email still carries a `NEEDS-REVIEW` and two `OUT-OF-SCOPE` lines. Nothing here says "compliant" — see `rules.md` § Never for why that word is refused.

---

## Example 2 — a two-violation fail

**Input:** `fixtures/example-glowup-multi-violation.eml` — a fictional skincare brand's promotional email. `Reply-To` resolves to a different domain than `From` (an inaccurate-routing-info pattern), and the body has no physical postal address at all.

**Command:** `python3 audit.py fixtures/example-glowup-multi-violation.eml`

**Output:**

```
# CAN-SPAM audit — example-glowup-multi-violation.eml

**2 FAIL** / 2 PASS / 1 NEEDS-REVIEW / 2 out of scope

⚠️ Each separate email in violation of the CAN-SPAM Act is subject to penalties of up to $53,088 (FTC, 2025 inflation-adjusted figure, reference/ftc-compliance-guide.md). Every email sent counts separately.

## [FAIL] Accurate header information — `AUTOMATED`
- **Rule:** rule-1-header-accuracy
- **Citation:** 16 CFR §316.2(m) (✓ quote verified in reference/, under the provision cited)
- Reply-To domain (a-different-mailhost.example) does not match From domain (glowupskincare.example). This auditor can't confirm real-world mailbox ownership, but a Reply-To that routes to a different domain than the stated sender is a structural inconsistency in the routing information the rule requires to be accurate.

## [NEEDS-REVIEW] Non-deceptive subject line — `AI-ASSISTED`
- No transactional-subject pattern detected.

## [PASS] Message identified as an advertisement — `AUTOMATED`
- An explicit ad/marketing/promotional disclosure phrase is present in the body.

## [FAIL] Valid physical postal address present — `AUTOMATED`
- **Rule:** rule-4-postal-address
- **Citation:** 15 U.S.C. 7704(a)(5)(A)(iii); 16 CFR §316.2(p) (✓ quote verified in reference/, under the provision cited)
- No street address, PO Box, or ZIP-code-shaped pattern found in the body.

## [PASS] Working, one-step, no-fee opt-out mechanism — `AUTOMATED`
- Opt-out language is present with no fee-gating, multi-step, or extra-information language detected nearby.

## [SKIPPED] Opt-out honored within 10 business days — `OUT-OF-SCOPE`
## [SKIPPED] Monitoring third-party senders acting on your behalf — `OUT-OF-SCOPE`
```

(trimmed here for length; full citations + verbatim quotes appear in the real run)

**What this demonstrates:** two independent, code-produced `FAIL`s, each citing the exact regulatory section and quote — not "this looks off," but a named rule, a named citation, and a quote checked against the provision that citation names. Exit code is `1`.

---

## A third, deliberately smaller example — the `AI-ASSISTED` boundary firing as `AUTOMATED`

`fixtures/bad-subject-contradicts-body.eml` is the one case where `rule-2-subject-line` becomes `AUTOMATED` rather than `AI-ASSISTED`: a subject line reading `Re: Your Order Confirmation` over a body that opens with "Flash Sale: 30% off all classes this week! Buy now and save" — no transactional content up front. Run it yourself: `python3 audit.py fixtures/bad-subject-contradicts-body.eml`. This is the brief's own worked-example shape ("the button at line 47 has a contrast ratio of 3.1:1" — pure arithmetic, not a vibe check) applied to CAN-SPAM: a real regulatory test (16 CFR §316.3(a)(2)) driving one narrow, honestly-scoped code branch.


---

## A fix firing, pasted from the committed runs

The three examples above show the auditor passing and failing on fixtures. These two show the two changes this rebuild exists for, copied verbatim from the committed raw runs (`run-rebuild/q4.txt` and `run-rebuild/q1.txt`, written by `./run-questions.sh rebuild`). Lines marked `...` are cut for length; nothing is retyped.

### The third §316.5 bar firing

**Source:** `run-rebuild/q4.txt`, the run of `questions/inputs/q4-optout-name-address-account.eml`, whose unsubscribe step asks for a full name, a mailing address and an account number. The opt-out finding is a `FAIL` and names all three.

```
$ python3 audit.py questions/inputs/q4-optout-name-address-account.eml
# CAN-SPAM audit — q4-optout-name-address-account.eml

**1 FAIL** / 3 PASS / 1 NEEDS-REVIEW / 2 out of scope
...
## [FAIL] Working, one-step, no-fee opt-out mechanism — `AUTOMATED`
- **Rule:** rule-5-opt-out  
- **Citation:** 16 CFR §316.5 (✓ quote verified in reference/, under the provision cited)  
- **Quoted:** "Neither a sender nor any person acting on behalf of a sender may require that any recipient pay any fee, provide any information other than the recipient's electronic mail address and opt-out preferences, or take any other steps except sending a reply electronic mail message or visiting a single Internet Web page"  
- Opt-out language is present but asks the recipient for information beyond their email address (full name, mailing address, account number) — §316.5 bars requiring "any information other than the recipient's electronic mail address and opt-out preferences".

[exit 1]
```

### The quote check catching a wrong citation

**Source:** `run-rebuild/q1.txt`. Q1's plant changes every `16 CFR §316.2(p)` to `16 CFR §316.2(o)` in a scratch copy of `audit.py`, leaving the quote alone, then audits `fixtures/clean.eml`. The quote is real but sits under a different provision, so the check refuses it. Exit code is `3`.

```
$ plant: replace every '16 CFR §316.2(p)' with '16 CFR §316.2(o)' in audit.py  (replaced: 3)
$ python3 audit.py fixtures/clean.eml
# CAN-SPAM audit — clean.eml

**0 FAIL** / 4 PASS / 1 NEEDS-REVIEW / 2 out of scope

✗ **1 quote-check failure(s)** (rule-4-postal-address): a quoted line is not under the provision its finding cites. Treat this report as unreliable until that's fixed.
...
- **Citation:** 15 U.S.C. 7704(a)(5)(A)(iii); 16 CFR §316.2(o) (✗ QUOTE NOT FOUND under 16 CFR §316.2(o) in reference/ — self-check failure)  
...
[exit 3]
```
