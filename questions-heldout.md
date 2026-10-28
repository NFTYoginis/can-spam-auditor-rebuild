<!-- Provenance: written on 2026-10-28 by a third fresh Claude session, given only rebuild/README.md as it stood before the 2026-10-28 fix, and told to aim each case at a place where the tool might break a README promise. It never saw the fix or the other two sets. It could not run the tool. The text below is its file, unedited, committed before either arm was run against it. This set is held out: we report what it finds and do not fix the build against it before judging. -->

# Held-out questions (bars written before any run). Run from the folder holding audit.py.
Stdout checks are case-sensitive literal substrings. "Traceback" must never appear in any case.

## h1 Refusal of forwarded-memo prose with embedded header-looking lines
Q: Does a prose memo that only quotes From/To/Subject lines after a blank line get refused rather than audited?
README: "`2` | The input isn't an email, or no input was given. No report is printed"; "plain prose with no headers ... hard refusal (`NotAnEmailError`, exit 2)".
Cmd: `python3 audit.py ../questions-heldout/inputs/h1.eml`
PASS: exit code == 2; stdout does not contain `316.`; stdout does not contain `7704`; no `Traceback`.

## h2 "account settings" in the sentence after an email-only opt-out
Q: Does an opt-out that asks only for the email address still PASS when the next sentence merely links to account settings?
README: "Asking for the email address alone still passes." / "the sentence containing the opt-out ... an account ... number".
Cmd: `python3 audit.py ../questions-heldout/inputs/h2.eml`
PASS: exit code == 0 (email is otherwise clean: ad disclosure, PO-style street address, matching From/Reply-To); no `Traceback`.

## h3 Opt-out demanding an order number (field not on the word list)
Q: Is "reply with your order number" caught as information beyond the email address?
README: "bars requiring 'any information other than the recipient's electronic mail address and opt-out preferences'"; "an account, member or customer number, an ID ...".
Cmd: `python3 audit.py ../questions-heldout/inputs/h3.eml`
PASS: exit code == 1; stdout contains `316.5`. (Known-limit probe: exit 0 here is a kept-promise failure.)

## h4 Fee stated far from the first opt-out cue
Q: Is a $2.00 opt-out fee found when an early "Unsubscribe" link in the preheader pulls the 150-char window away from the fee sentence?
README: "bars requiring a fee"; "They still use a 150-character window around the first opt-out cue."
Cmd: `python3 audit.py ../questions-heldout/inputs/h4.eml`
PASS: exit code == 1; stdout contains `316.5`; no `Traceback`.

## h5 Transactional shipping notice carrying a promo code
Q: When the message has no address and no opt-out, does the FAIL output mention the primary-purpose exemption rather than a bare FAIL?
README: "the ad-disclosure check FAILed content that §316.3's primary-purpose exemption may cover. That FAIL message now says so."
Cmd: `python3 audit.py ../questions-heldout/inputs/h5.eml`
PASS: exit code == 1 (never 0, never 2); stdout contains `316.3`; no `Traceback`.

## h6 HTML-only footer in base64, address split across table cells, PDF attachment, RFC 2047 From/Subject
Q: Does the tool read the base64 text/html part (not only text/plain) and find address, ad disclosure and one-click opt-out, ignoring the attachment's "$5 fee" text?
README: "It reads text."; address check `AUTOMATED`; opt-out "no fee, one step".
Cmd: `python3 audit.py ../questions-heldout/inputs/h6.eml`
PASS: exit code == 0; no `Traceback`; stdout does not contain `Unsubscribe fee`.
