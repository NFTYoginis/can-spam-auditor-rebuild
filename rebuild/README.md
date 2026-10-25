# can-spam-auditor (rebuild)

Audits a raw marketing email (`.eml`: full source, headers included) against the CAN-SPAM Act: 16 CFR Part 316 and 15 U.S.C. 7704(a)(5). A deterministic checker handles what can be decided mechanically. `AI-ASSISTED` labels mark what can't. Two requirements are named as out of scope rather than skipped silently.

**Every quote a finding prints is checked against the provision that finding cites, not against `reference/` as a whole.** A real quote printed under the wrong section fails the check.

Zero API key, zero network calls, zero third-party dependencies: `audit.py` uses only the Python 3 standard library.

This folder is arm B of [the rebuild repo](../README.md). The judged original is in [`../original/`](../original/), and what changed and why is in [`../results.md`](../results.md).

## What changed from the judged commit (`5502381`)

**1. Quotes are checked under the provision they cite.** Each provision in `reference/` sits between `<!-- anchor:<provision> -->` and `<!-- /anchor:<provision> -->` markers, for example `<!-- anchor:16 CFR §316.2(p) -->`. `quote_is_grounded(quote, citation, anchors)` takes the provision from the citation string the finding prints and looks for the quote only inside that anchor. Anchors nest, so a citation to `§316.5` can match anything in §316.5, and a citation to `§316.5(b)` only matches (b). If a citation has no anchor, the check fails. The markers are added lines. No line of regulatory or statutory text was changed.

**2. The postal-address finding cites the duty, not only the definition.** `reference/15-usc-7704-a5.md` carries 15 U.S.C. 7704(a)(5) verbatim. Rule 4 now cites `15 U.S.C. 7704(a)(5)(A)(iii)` ("a valid physical postal address of the sender") for the duty, and `16 CFR §316.2(p)` for what counts as a valid address. Both quotes are checked, each under its own citation, and the finding shows `✓ quote verified` only if both pass.

**3. The opt-out check enforces all three §316.5 bars.** §316.5 bars requiring a fee, requiring "any information other than the recipient's electronic mail address and opt-out preferences", and requiring any step beyond a reply email or a single web page. The original checked the first and third. The rebuild also FAILs when the sentence containing the opt-out asks for a personal field: a name, a postal address, an account, member or customer number, an ID, a phone number, a date of birth, a ZIP code, a password, or a reason for leaving. Asking for the email address alone still passes.

**4. The self-test attacks its own quote check.** `--selftest` takes every (citation, quote) pair a real audit prints, moves the citation to a neighbouring provision (`§316.2(p)` to `§316.2(o)`, `§316.5` to `§316.4`, and so on), and requires each one to be rejected. If `quote_is_grounded()` is forced to return true, those canaries fail and the self-test goes red.

## Tested by trying to break it

This build has been broken three times by people trying to break it. Each break is dated and linked to a commit.

- **2026-09-05, garbage input.** An adversarial test fed `audit.py` plain prose with no headers and got back a fully formed "4 FAIL" report citing real CFR text. Fixed the same day with a hard refusal (`NotAnEmailError`, exit 2) that still audits a real email that is only missing its From header. Commit [`4d35421`](https://github.com/NFTYoginis/can-spam-auditor/commit/4d35421). `--judge-mode` checks (a) and (b) re-run this.
- **The same week, real copy.** Professionally drafted marketing emails showed that the ad-disclosure check FAILed content that §316.3's primary-purpose exemption may cover. That FAIL message now says so. Commit [`989a8a3`](https://github.com/NFTYoginis/can-spam-auditor/commit/989a8a3).
- **Comp #12 judges, at commit [`5502381`](https://github.com/NFTYoginis/can-spam-auditor/tree/5502381).** With the quotes left untouched, they swapped `§316.2(p)` to `§316.2(o)` and `§316.5` to `§316.4`. The original printed "✓ quote verified" beside both, and `--selftest` stayed green. Separately, an unsubscribe line demanding a full name, a mailing address and an account number PASSed. This rebuild is the answer to both. Each fix is re-tested by a question in [`../questions.md`](../questions.md), and the raw runs of both arms are in [`../run-original/`](../run-original/) and [`../run-rebuild/`](../run-rebuild/).

## Run it

```
python3 audit.py <email.eml>                           # Markdown report
python3 audit.py <email.eml> --json                    # machine-readable, one result per (citation, quote) pair
python3 audit.py <email.eml> --sarif report.sarif      # also write SARIF
python3 audit.py <email.eml> --brand-domain example.com
python3 audit.py --selftest                            # fixtures + citation-swap canaries + label integrity
python3 audit.py --judge-mode                          # the three adversarial checks from the original build
```

| Exit | Meaning |
| --- | --- |
| `0` | No check FAILs, and every quote verified under the provision it cites |
| `1` | At least one check FAILs, and every quote verified |
| `2` | The input isn't an email, or no input was given. No report is printed |
| `3` | A quote-check failure: some finding's quote is not under the provision it cites, or `reference/` has a malformed anchor. The report header says which findings are affected. This outranks `1`, because a report with a misattributed quote can't be trusted either way |

## What it checks

| Rule | Citation(s) | Tag |
| --- | --- | --- |
| Accurate header info (From / Reply-To domain consistency) | 16 CFR §316.2(m) | `AUTOMATED` |
| Non-deceptive subject line | 16 CFR §316.3(a)(2) | `AUTOMATED` for one structural case, `AI-ASSISTED` otherwise |
| Ad disclosure present | FTC Compliance Guide, "Identify the message as an ad" | `AUTOMATED` (binds commercial-purpose messages only, see `reference/rule-map.md`) |
| Physical postal address present | 15 U.S.C. 7704(a)(5)(A)(iii); 16 CFR §316.2(p) | `AUTOMATED` |
| Opt-out present, no fee, one step, no information beyond the email address | 16 CFR §316.5 | `AUTOMATED` |
| Opt-out honored within 10 business days | 16 CFR §316.5(b) | `OUT-OF-SCOPE` |
| Monitoring third-party senders | FTC Compliance Guide, "Monitor what others are doing on your behalf" | `OUT-OF-SCOPE` |

The full mapping is in [`reference/rule-map.md`](reference/rule-map.md).

## Known limits

- **The third §316.5 bar is a word list.** It catches the personal fields it names, in the sentence holding the opt-out cue and the sentence after it, when that text also contains a request word ("enter", "provide", "with your", "required" and similar). It misses fields it doesn't name, requests worded without any of those cues, requests placed further from the opt-out line, anything in another language, and anything the unsubscribe page asks for that the email itself doesn't mention.
- **The fee and multi-step bars are unchanged from the original.** They still use a 150-character window around the first opt-out cue.
- **It reads text.** An address or opt-out link that exists only inside an image is invisible to it.
- **A clean report is not "compliant".** It means the automated structural checks found nothing. Two requirements are not checked at all, and the report says so on every run.

Not a legal compliance certification, and not a multi-standard tool.

## Layout

```
audit.py                     the whole engine, stdlib only
fixtures/                    one clean base email + one broken variant per rule (generate_fixtures.py), plus parser-robustness fixtures
reference/
  16-cfr-part-316.md         16 CFR Part 316, verbatim, with provision anchors
  15-usc-7704-a5.md          15 U.S.C. 7704(a)(5), verbatim, with provision anchors
  ftc-compliance-guide.md    FTC compliance guide, verbatim, each requirement heading anchored
  rule-map.md                rule -> citation -> tag -> check function
identity.md / rules.md / examples.md   the ICM specialist layer
```

## Sources

- 16 CFR Part 316, via Cornell LII: `law.cornell.edu/cfr/text/16/part-316` (retrieved 2026-09-04)
- 15 U.S.C. 7704, via Cornell LII: `law.cornell.edu/uscode/text/15/7704` (retrieved 2026-10-25, paragraph (a)(5) only)
- FTC, *CAN-SPAM Act: A Compliance Guide for Business*: `ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business` (retrieved 2026-09-04)

All three are US federal government works, public domain under 17 U.S.C. §105.

## License

MIT. See `LICENSE`.
