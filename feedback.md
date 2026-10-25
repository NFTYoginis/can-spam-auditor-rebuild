# Gabriel Azoulay: can-spam-auditor

Comp #12: The Auditor. We read your repo at the commit that was public when the clock stopped: [https://github.com/NFTYoginis/can-spam-auditor](https://github.com/NFTYoginis/can-spam-auditor) (`5502381`).

**What you built.** An auditor that checks a raw marketing email against the CAN-SPAM Act (16 CFR Part 316), verifying its own citations before it lets itself report anything.

---

## The read

**Is the standard real, present, and applied.** `reference/` does the job the brief demanded: Part 316 and the FTC's compliance guide, both verbatim, both public-domain, with the provenance written down.

**Finding quality under test.** It refuses in the right places. Garbage input exits 2 rather than producing a plausible report. A clean run is forbidden from meaning "compliant". There is nowhere in the output schema for a fix to live. The README carries dated, commit-linked evidence of having been broken by someone — which almost nobody writes.

**Methodology cleanliness.** `rule-map.md` is the best index in the round: every requirement tied to a citation, a tag, and the named function that checks it, with reasoned notes on the two rules deliberately left unwired.

**README quality.** Strong, with the honesty to distinguish what is checked from what isn't — though it does not yet distinguish the two halves of the citation check (below).

---

## What worked

1. **`rule-map.md`.** Every requirement tied to a citation, a tag, and the named function that checks it — with reasoned notes on the two rules deliberately left unwired rather than silent about them.

2. **Refusals by design.** Garbage exits 2, a clean run cannot mean compliant, and the schema has nowhere for a fix to live. Plus a README with dated, commit-linked evidence of a real outsider breaking it.

## Two fixes

1. **Anchor each quote to the section heading it sits under.** `quote_is_grounded()` searches the concatenated reference files, so it catches invention and is blind to misattribution: quotes left untouched, `§316.2(p)` swapped to `§316.2(o)` and `§316.5` to `§316.4`, and it printed "✓ quote verified" beside both while `--selftest` stayed green. Closing it will also show you the live instance you cannot currently see: `§316.2(p)` defines what a valid postal address is, while the duty to include one lives in 15 U.S.C. 7704(a)(5), which is not in your `reference/` at all.

2. **Implement the third bar in §316.5.** Its text you quote bars three things; `check_opt_out` implements two. An unsubscribe flow demanding full name, mailing address, and account number was sent, and it PASSed directly under the clause forbidding exactly that.

---

**What would have moved you up a tier.** The section anchor on the quote check — a citation that resolves but points at the wrong thing is the exact failure this competition is hunting, and the map you already built tells the checker where to look.
