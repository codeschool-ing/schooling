---
title: Risks, sensitivity points and trade-offs
version: 1
---

**ATAM's lasting contribution is its vocabulary for what a review finds.** Five words separate kinds
of finding that a less careful review lumps together as *concerns*, and the separation changes what
happens next.

| term | what it is | an example from Carcará's review |
| --- | --- | --- |
| **risk** | an architectural decision that may lead to a quality attribute scenario not being met | *the queue in front of purchases is sized for 2,500 a minute, and last year's peak was 2,300; one more route and it is not enough* |
| **non-risk** | a decision judged sound for its scenarios, with the reason | *seat holds in Redis meet QS-01 with headroom: measured at 4,000 holds a minute in the load test* |
| **sensitivity point** | a property of a component that one quality depends on strongly | *the sync interval of the drivers' phones: the freshness of the ticket list depends on it directly* |
| **trade-off point** | a sensitivity point for two or more qualities that pull in different directions | *the same sync interval: shorter improves refusing cancelled tickets, and costs battery and mobile data* |
| **risk theme** | a pattern that several risks share | *every station-side risk traces to the station internet link* |

## Why the distinctions matter

- **A non-risk is a finding.** Writing *seat holds in Redis are fine, and here is the measurement*
  stops the next review from spending an hour on it, and records the evidence.
- **A trade-off point is not a risk to remove.** The sync interval cannot be made good for both
  qualities; it can only be set deliberately, by the person who owns the trade, and revisited when
  the costs change. Treating it as a defect wastes effort; ignoring it leaves it to whoever edits the
  configuration.
- **Risk themes are what the report leads with.** Fourteen risks are a list; one theme, *the station
  link is a single point of failure for six capabilities*, is a decision a director can make.

## The theme that came out at Carcará

The review found fourteen risks. Six of them, in different parts of the system, came back to the
same fact: each of the 26 stations had one internet link, and the counter mode, the printers' QR
receipts, the end-of-day cash report, the agents' refunds and two others stopped when it did. None of
the six was serious alone; together they were the biggest risk to São João.

Celeste's decision, made in the meeting with the theme in front of her, was **a second mobile link
at the twelve busiest stations before the peak**, and the offline sale mode of lesson 8 for the
rest. That is what ATAM's last step exists for: **turning a list of findings into a decision the
business can take**.
