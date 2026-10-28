<!-- Provenance: written on 2026-10-28 by a second fresh Claude session, given only rebuild/README.md and told to aim each case at a place where the tool might break a README promise. It could not run the tool. The text below is its file, unedited. It was committed before either arm was run against it, and it will not change. -->

# Adversarial questions (bars written before any run)
Command for each: `python3 audit.py ../questions-adversarial/inputs/aN.eml`

## a1 - quoted-printable soft breaks inside "advertisement" and "unsubscribe"
Q: Does a clean ESP-style QP HTML email with words split by soft line breaks, and "account" in the sentence BEFORE the opt-out, pass?
README: "Asking for the email address alone still passes." / "Exit 0: No check FAILs, and every quote verified"
PASS bar: exit code 0.

## a2 - base64 HTML body, postal address split across <br> lines (PO Box)
Q: Is a base64 body decoded and a multi-line PO Box address accepted as a valid postal address?
README: "Physical postal address present ... AUTOMATED"; "§316.2(p)"; "It reads text."
PASS bar: exit code 0.

## a3 - odd phrasing of an info-demanding opt-out (ZIP + reason)
Q: Does "we'll need your ZIP code and a reason for leaving on the form" trip the third §316.5 bar?
README: "FAILs when the sentence containing the opt-out asks for a personal field: ... a ZIP code ... or a reason for leaving." (Known limits admit request-word cues; this uses "we'll need", "on the form".)
PASS bar: exit code 1 (not 0, not 2, not 3) AND stdout contains the substring `316.5`.

## a4 - real email missing its From header
Q: Does the tool still audit a real email lacking From, rather than refusing?
README: "a hard refusal (NotAnEmailError, exit 2) that still audits a real email that is only missing its From header."
PASS bar: exit code is not 2 AND stdout is non-empty (a report is printed).

## a5 - CRLF line endings, folded From, multi-word RFC 2047 encoded Subject
Q: Does header folding/CRLF/encoded-word decoding avoid a false refusal or false FAIL on a clean email?
README: "Exit 2: The input isn't an email"; "Exit 0: No check FAILs"
PASS bar: exit code 0 (specifically not 2).

## a6 - fake "Fwd:" subject on a promo with no In-Reply-To/References, everything else clean
Q: Is the structural deceptive-subject case caught?
README: "Non-deceptive subject line | 16 CFR §316.3(a)(2) | AUTOMATED for one structural case"
PASS bar: exit code 1 AND stdout contains the substring `316.3`.
