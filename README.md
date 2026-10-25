# can-spam-auditor-rebuild

A rebuild of our Comp #12 entry, [`NFTYoginis/can-spam-auditor`](https://github.com/NFTYoginis/can-spam-auditor), as judged at commit [`5502381`](https://github.com/NFTYoginis/can-spam-auditor/tree/5502381). `original/` is `git archive 5502381` of that repo, untouched. `feedback.md` is the judges' file, verbatim.

The line in the feedback that drove this rebuild:

> a citation that resolves but points at the wrong thing is the exact failure this competition is hunting

The judged auditor checked that each quote existed *somewhere* in `reference/`. It never checked that the quote sat under the provision the finding cited. The rebuild checks each quote only inside the provision its citation names. It also adds the statute that creates the postal-address duty, and enforces the third §316.5 bar (no information beyond the email address).

## Re-run both arms

```
./run-questions.sh original && ./run-questions.sh rebuild
```

You need Python 3 and bash, nothing else. Each run copies the arm to a temp folder, applies the plants for Q1, Q2 and Q6 there, and runs all eight questions. It rewrites `run-original/` or `run-rebuild/` and prints one verdict per question. To check that you reproduced our runs, run `git status --short run-original run-rebuild` afterwards. Only the `python:` line in `summary.txt` should differ, and only if your Python version isn't 3.9.6.

## Read in this order

1. [`feedback.md`](feedback.md): the judges' read of the original.
2. [`questions.md`](questions.md): eight questions, six from the feedback and two no-regression checks. It was committed before `rebuild/` was committed and hasn't changed since.
3. [`results.md`](results.md): A vs B question by question, the ties, what is still weak, and what we left alone on purpose.
4. [`rebuild/README.md`](rebuild/README.md): what the rebuilt auditor does, and its known limits.

## Layout

```
feedback.md            judges' feedback, verbatim
original/              arm A: git archive 5502381, untouched
questions.md           the eight questions
questions/inputs/      the two .eml inputs for Q4 and Q5
run-questions.sh       runs all eight against one arm, writes raw output
run-original/          raw output, arm A
rebuild/               arm B
run-rebuild/           raw output, arm B
results.md             A vs B, ties, limits, left alone
.github/workflows/     on every push: both arms, the rebuild self-test, and a check that verdicts match the committed runs
```

## Commit order

One commit per step, in this order, so the history shows that the questions came before the rebuild:

1. `original/` + `feedback.md`
2. `questions.md` + `questions/inputs/` + `run-questions.sh`
3. `run-original/`
4. `rebuild/`
5. `run-rebuild/`
6. `results.md`
7. this README

## License

MIT, as the original. See `rebuild/LICENSE` and `original/LICENSE`.
