<!-- Provenance: written on 2026-10-28 by a fresh Claude session that was given one file, rebuild/README.md, and told not to open anything else. It could not run the tool. The text below is its file, unedited. It was committed before either arm was run against it, and it will not change. -->

# Outsider questions for audit.py

## Q1. Does it refuse plain prose that is not an email?
README: "`2` | The input isn't an email, or no input was given. No report is printed"; "a hard refusal (`NotAnEmailError`, exit 2)".
Input: o1.eml (letter-style prose, no headers).
Command: `python3 audit.py ../questions-outsider/inputs/o1.eml`
PASS: exit code is 2; stdout does not contain `quote verified`; stdout does not contain `AUTOMATED`.

## Q2. Does a real email with no From header still get audited (not refused)?
README: "still audits a real email that is only missing its From header."
Input: o2.eml (Date/To/Subject/body, no From; has ad disclosure, postal address, reply-to-unsubscribe).
Command: `python3 audit.py ../questions-outsider/inputs/o2.eml`
PASS: exit code is not 2 (expected 0 or 1; output format isn't shown well enough for more); stdout contains `OUT-OF-SCOPE` (README: the report names the unchecked requirements on every run).

## Q3. Does an unsubscribe step demanding name + mailing address + account number FAIL?
README: "FAILs when the sentence containing the opt-out asks for a personal field: a name, a postal address, an account, member or customer number"
Input: o3.eml (otherwise clean; opt-out line says "please enter your full name, your mailing address and your account number").
Command: `python3 audit.py ../questions-outsider/inputs/o3.eml`
PASS: exit code is 1 (not 0, not 3).

## Q4. Does an unsubscribe that asks only for the email address still pass?
README: "Asking for the email address alone still passes."
Input: o4.eml (identical to o3 except opt-out says "please enter your email address").
Command: `python3 audit.py ../questions-outsider/inputs/o4.eml`
PASS: exit code is 0; stdout contains `quote verified`; stdout contains `OUT-OF-SCOPE`.
(Caveat: exit 0 also depends on header, subject and ad-disclosure checks passing; o4 was written to satisfy them.)

## Q5. Is an address that exists only in an image reported as missing, not silently passed?
README: "It reads text. An address or opt-out link that exists only inside an image is invisible to it." and rule "Physical postal address present ... AUTOMATED".
Input: o5.eml (multipart; the postal address appears nowhere in text, only a referenced footer image).
Command: `python3 audit.py ../questions-outsider/inputs/o5.eml`
PASS: exit code is 1 (address check FAILs, quotes verified). Exit 0 means the tool invented an address; exit 3 or 2 is also a fail.
