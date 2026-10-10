---
title: Not how good, but what changed
version: 2
---

Every change to the assistant is a new release: a different model, a different prompt, a different
number of chunks, a different floor. Lesson 5 found the floor release of 1 October in production, after
customers had been meeting it for days. A **regression test** asks the question
before the release instead: run the evaluation set through the candidate and through the release in
production, and compare them **case by case**.

The question is narrower than "is the candidate good". It is **what did the candidate change**: which
cases it now gets right that it got wrong, which it now gets wrong that it got right, which replies
read differently, and what it costs and how long it takes. A candidate can raise the average and break
the one case a customer asks about most; a regression test is built to show that case by name.

## The candidates

A release is a line of `releases.json`: a model, the number of chunks, and the floor. The course
writes three candidates beside the two releases that ran in the week, each starting in 2099 so that
nothing in production picks them up. Replace `releases.json` with:

```json
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.4},
  "2026.10.1": {"from": "2026-10-01T10:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.55},
  "2026.10.2": {"from": "2099-01-01T00:00:00", "model": "llama3.2:1b", "k": 3, "floor": 0.55},
  "2026.10.3": {"from": "2099-01-01T00:00:00", "model": "llama3.2:3b", "k": 3, "floor": 0.4},
  "2026.10.4": {"from": "2099-01-01T00:00:00", "model": "llama3.2:1b", "k": 3, "floor": 0.4}
}
```

- **2026.10.2 changes the model** to `llama3.2:1b`, the smaller one lesson 1 pulled. At the course's
  prices it costs a third of `llama3.2:3b` per token, and it answers faster on the same machine.
- **2026.10.3 puts the floor back** to 0.4, the setting before 1 October.
- **2026.10.4 does both.**

Each release answers version 2 of the evaluation set, through `evalrun.py` from lesson 8 with its
`--release` option:

```
ana@dev:~/obs$ for r in 2026.09.4 2026.10.1 2026.10.2 2026.10.3 2026.10.4; do python evalrun.py $r --set data/eval-v2.jsonl --release $r; done
runs/2026.09.4.jsonl: 32 questions, release 2026.09.4
runs/2026.10.1.jsonl: 32 questions, release 2026.10.1
runs/2026.10.2.jsonl: 32 questions, release 2026.10.2
runs/2026.10.3.jsonl: 32 questions, release 2026.10.3
runs/2026.10.4.jsonl: 32 questions, release 2026.10.4
```

The runs are made today, so every reply is priced at today's prices, whatever release produced it: the
comparison is between what each would cost now, which is the question a release decision asks.
