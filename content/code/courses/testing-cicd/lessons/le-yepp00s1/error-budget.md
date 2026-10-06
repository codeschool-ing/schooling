---
title: Error budgets, or when to stop releasing
version: 1
---

Everything so far decided when to stop **one** release. There is a second stop criterion, one level
up: when to stop releasing **altogether**, for a while.

## An objective, and what it allows

A **service level objective** (SLO) is a target for how reliable a service should be, measured from
the customer's side: for example, "99.9% of quote requests succeed, over 30 days". The **error
budget** is what the objective leaves over: 0.1% of requests may fail. Expressed as time, for a
service that is either up or down:

| objective | down time allowed in 30 days |
| --- | --- |
| 99% | 7 hours 12 minutes |
| 99.9% | 43 minutes 12 seconds |
| 99.99% | 4 minutes 19 seconds |

Each extra nine divides the budget by ten, and multiplies what it costs to stay inside it.

## The budget as a rule

The budget turns an argument into arithmetic:

- **While budget remains**, releases go out at the usual pace. Some will fail; that is what the
  budget is for. A team that never spends its budget is releasing too slowly, or aiming too high.
- **When the budget is spent**, releases of new features stop, and the work goes to reliability: the
  tests, the canary criteria, the rollback, whatever the postmortems asked for. They resume when
  the budget recovers.

Applied to this lesson: the blue-green switch of lesson 10 cost 77 failed requests. At 99.9% over, say, two million requests a month, the budget is 2,000
failed requests. That incident spent about 4% of it. A bug that failed one request in twenty for an
hour, unnoticed, would have spent it several times over.

## Why it belongs in a course about pipelines

Everything in this course, the tests, the matrix, the stages, the canary and the rollback, exists to
let a team release often without spending its budget. The budget is how the team knows whether that
is working. When it runs out, it is the pipeline that gets the attention.
