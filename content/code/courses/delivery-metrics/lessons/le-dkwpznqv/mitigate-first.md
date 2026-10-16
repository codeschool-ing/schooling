---
title: Mitigation before diagnosis
version: 1
---

At 18:02 on 30 September, sixteen minutes after the incident was declared, the Billing team had a choice. Rafa, the technical lead, was fairly sure the double charges came from one of the four changes in release `D047`, and fairly sure which: the new retry for slow card payments. He could find the bug and fix it, or he could roll the whole release back and look afterwards.

Bia, as incident commander, decided to roll back. The rollback started at 18:04 and finished at 18:15, and no duplicate charge happened after it. Finding and fixing the bug properly took the next day.

## Why undo before you understand

**The priority in an incident is to stop the harm, not to explain it.** Every minute spent diagnosing while the system is still double-charging shops is a minute of more double charges. Diagnosis can take an hour, or a day, and it can be wrong; a rollback to the previous release takes minutes and is very likely to stop whatever the release started.

The habit to unlearn is the engineer's instinct, which is usually a virtue: understand the problem, then fix it. In an incident that order is reversed. **Mitigate, then diagnose, then fix.** The postmortem, lesson 15, is where understanding happens, with the evidence preserved and nobody's customers being harmed while it happens.

## The usual mitigations

| move | when it fits | what it costs |
|---|---|---|
| **roll back** the last release | the harm started with a deployment | the other changes in the release go out again later |
| **turn off a feature flag** | the change was released behind a flag | the feature is unavailable until fixed |
| **fail over** to another region or provider | the harm is in one place you can route around | capacity or cost on the other side |
| **shed load** or rate-limit | the system is overwhelmed | some requests are refused, deliberately |
| **block the bad input** | one kind of request triggers the failure | the users sending it are affected |

Each one is a decision the incident commander makes with incomplete information, and each one should be **cheap to make because it was prepared in advance**: a rollback that takes one command, flags around risky changes, a runbook that says how to fail over. A team that has to work out how to roll back during the incident has made mitigation as slow as diagnosis.

## When you cannot roll back

Some changes cannot be undone by reverting the code: a database migration that dropped a column, a message already sent to ten thousand shops, money already charged. The 30 September incident had a version of this. The rollback stopped new duplicate charges at 18:15; it did nothing about the 212 duplicates already made, which had to be refunded one by one until 21:10.

That is why the Billing team's timeline separates **restored**, when the harm stopped, from **resolved**, when its consequences were repaired. DORA's time to restore is the first. The shops' experience includes the second.

## Small batches make mitigation easy

Lesson 5 found that the Billing team's failed deployments took more than two hours to undo in June and July, when each carried six to eight changes, and under an hour afterwards. `D047` carried four changes and a rollback took eleven minutes. **A small release is a cheap rollback**, which is one more way the batch size of lessons 5 and 7 reaches into a part of the work it seems to have nothing to do with.
