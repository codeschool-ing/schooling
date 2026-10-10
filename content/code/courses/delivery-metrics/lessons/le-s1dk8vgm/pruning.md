---
title: Removing, demoting and fixing alerts
version: 1
---

The program gives three verdicts, and each one is a different piece of work. None of them is "leave it and be more careful".

## Remove, or make it a ticket

Four of the Billing team's alerts never needed a person in thirteen weeks. For each, the team asked one question: **is there anything here somebody should know about this week?**

- **"Database disk over 80%"** became a ticket, opened automatically when the disk is forecast to fill within two weeks at its current rate. A disk that fills over days is a planning problem; a forecast says so in working hours, with time to act.
- **"TLS certificate expires in 30 d"** became a ticket too. Thirty days of warning is the point of the alert, and nobody needs to hear it at two in the morning.
- **"API CPU over 85%"** went to the dashboard, beside the charge latency it might explain. It is a cause, useful when investigating a symptom and useless on its own.
- **"Health check failed once"** was deleted. One failed check out of hundreds is a blip; the alert that matters is charges failing, and the team already has it.

**Deleting an alert feels dangerous and rarely is.** The fear is that the deleted alert was the one that would have caught something. The answer is to ask what would catch that something instead, and for a service with a good symptom alert, the answer is almost always the symptom alert.

## Fix

Two alerts needed a person sometimes, and less often than they paged. Those are not to be deleted; they are to be made precise.

- **"Card provider p99 over 2 s"** was replaced by the burn-rate alert of lesson 16. The provider being slow matters only when the shops wait long enough for charges to count as bad; the burn rate pages exactly then, and in the afternoon of 30 September it would have paged at 17:30 with a symptom nobody could call noise. The old alert stayed on the dashboard.
- **"Statement queue over 500"** was given a duration: page only if the queue stays over 500 for twenty minutes and is not shrinking. A queue that spikes and drains is a queue working; one that grows for twenty minutes is a statement that will be late on the 1st.

Adding **a duration** and **a rate of change** are the two cheapest fixes for an alert that fires too eagerly. Most noisy alerts fire on a single bad minute, and most real problems last longer than one.

## Keep, with an owner and a runbook

The three alerts with a high actionable rate stay, and each gets two things it did not have:

- **an owner**, one person who answers for the alert's quality, reads its pages in the handover notes and changes it when it misbehaves;
- **a runbook**, linked from the page itself, which lesson 17 asked for and section 03 made a rule.

## The rule for new alerts

Pruning once is not enough; a team that adds alerts freely will be back where it started in a year. The Billing team added one rule to its working agreement: **a new alert that pages comes with its runbook and its owner, in the same change, and starts as a ticket for two weeks** before it is allowed to wake anybody. Two weeks of tickets show how often it would have paged, and whether anybody would have done anything, before the first night it costs.
