---
title: The alert review
version: 1
---

Alerts drift for the same reasons on-call load does: new services, new thresholds written in a hurry after an incident, a provider that gets better or worse. A pruned pager becomes a noisy pager again in a year unless somebody looks at it regularly.

## Once a month, half an hour

The Billing team reviews its alerts on the first Tuesday of each month, with whoever was on call in the last four weeks. The agenda is short:

1. **The month's numbers**: pages, the share that needed a person, pages at night, and pages per person, the last of these from lesson 17.
2. **Every alert under half actionable**, by name, with a decision: remove, demote, fix, or keep with a reason written down.
3. **Every page that should have happened and did not**: a problem found by a customer, a colleague or by luck. A silent pager on a bad day is a failure just as much as a noisy one on a quiet day.
4. **New alerts** that finished their two weeks as tickets, and whether they may now page.

The third item is the one teams forget, and it is what keeps a pruning from going too far. The rate of false pages can always be brought to zero by deleting every alert; the review is there to notice the moment a deleted signal is missed.

## The number and its trap

The share of pages that needed a person is a good number to watch and a bad number to set a target on, for the reason lesson 7 spent a whole lesson on. **A team told to raise its actionable rate can do it by writing "checked the dashboard" on every page**, which turns a page that needed nothing into one that needed a person, on paper. The Billing team reports the rate beside the raw counts, pages and night pages, which are much harder to dress up, and treats a rate that jumps without a matching fall in pages as a question, not a success.

## What the team expects

The first review was held on Tuesday 6 October, with the quarter's numbers from section 04. If the alerts that stayed page as often as they did in the quarter, the pager will ring about once a week instead of six times, and once a month at night instead of twice a week, with the burn-rate alert and the fixed queue alert adding a little on top. Nobody on the team will call that a result before a quarter has passed: a month is a small sample, and one quiet month can follow any change at all.

What they will look at first is not the count. It is whether every page is read, every time, within a minute, because that is the property the pruning is for: **a page that people believe.**
