---
title: A run that failed, and what stopped
version: 1
---

Green runs are easy to read. The run worth reading is a red one. On 18 September 2026, a pull
request adding lessons to another course of this catalogue ran the same workflow, and the record
shows what happened:

```
ana@laptop:~$ curl -s $A/runs/35315497063/jobs | jq -r ".jobs[] | [.name, .conclusion] | @tsv"
Changes	success
Go	failure
Browser	success
Infra	skipped
ana@laptop:~$ curl -s $A/runs/35315497063/jobs | jq -r ".jobs[] | select(.name == \"Go\") | .steps[] | select(.number >= 10 and .number <= 16) | [.number, .name, .conclusion] | @tsv"
10	The restore drill's question still runs	success
11	The catalogue is coherent	success
12	A student who read nothing cannot pass	failure
13	The interface speaks every language it claims to	skipped
14	Our stylesheets parse, and do not lay out their elements	skipped
15	Nothing the browser fetches leaves the origin	skipped
16	The tests, with a database behind them	skipped
```

**The `Go` job failed and the `Browser` job succeeded.** Jobs are independent: one failing does not
stop the others, unless one `needs` the failed job. `Infra` was skipped by the `Changes` job, because
the pull request touched no infrastructure.

Inside `Go`, the steps tell the rest. Steps 10 and 11 passed. **Step 12, *A student who read nothing
cannot pass*, failed**, and every step after it was skipped: the interface check, the stylesheet
check, the test suite against the database. That is lesson 5 section 05's rule, a failing step stops
the job, seen from the service's side.

## What that means for whoever reads it

Step 12 is the repository's check that exercise answers cannot be guessed without reading the
material, the same `check-exercises` this course's own questions had to pass. So the red run says
something precise: the questions in that pull request leaked their answers. It says nothing about the
Go code, because **the Go tests did not run**. A red job is a statement about the first step that
failed and an absence of information about everything after it.

Two habits follow:

- **Read the first failing step, not the job's summary.** "Go failed" sounds like a Go problem; the
  step says it was a content problem.
- **Order steps from cheapest and most likely to fail to most expensive.** A check taking three
  seconds before a suite taking two minutes means a content mistake costs three seconds of runner
  time, not the whole job. This repository puts its quick checks first for exactly that reason.

## When the order is wrong for you

Sometimes a team wants every check to run even after one fails, to see all the problems in one round.
GitHub Actions allows it per step with `if: always()` or `continue-on-error: true`, at the cost of a
longer run that keeps going after it already knows the answer is no. Like `fail-fast` for matrices,
it is a trade between runner time and information, and the right choice can differ for pull requests
and for `main`.
