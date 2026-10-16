---
title: What the four numbers cannot see
version: 1
---

A team can have excellent DORA numbers and be failing. Not often, but it is possible, and knowing how is what keeps the metrics in their place. The four measure **how well a team delivers changes**. They say nothing about whether the changes were worth delivering, whether the team can keep it up, or whether the people waiting for the work are being served.

## Five blind spots

**Value.** A team can deploy twenty small changes a day, none of which anybody needed. Deployment frequency counts deployments, not outcomes. Whether a change moved anything for a user is a product question, answered by different measurements: adoption, retention, revenue, support tickets avoided.

**The wait before the work.** Lead time for changes starts at a commit. Everything before it, the request sitting in the backlog, the item waiting to be started, is invisible. Lesson 2 found that in September **84% of a Billing requester's wait was in the backlog**: 27 of 32 days. The team's DORA lead time that month was six hours. Both numbers are true, and only one of them is what the shop owner who reported the bug experienced.

**Quality that does not cause an incident.** Change failure rate counts deployments that needed remediation. A bug that annoys every user a little, and never triggers a rollback, is not a change failure. A team can ship a slow decline in quality while its failure rate stays at zero.

**The people.** None of the four can tell a team delivering well from a team delivering well while burning out. A team whose numbers improved because two people worked every weekend looks, on a DORA dashboard, exactly like a team whose numbers improved because it changed how it works. Lesson 8 introduces a framework that includes how people are doing, and lesson 17 counts the cost of the pager.

**Work that is not a deployment.** Support, operations, onboarding a new colleague, an architecture review, the hour spent unblocking another team. A platform team whose job is to make other teams faster may deploy rarely and be doing excellent work. `BIL-189`, which was waiting on another team, is the trace of that kind of work on the Billing team's board, and nothing on a DORA dashboard would ever show it.

## What to pair them with

None of this is an argument against the four; it is an argument against reporting them alone. Each blind spot has a measurement that sees into it, and a report that matters carries some of them beside the DORA numbers:

| blind spot | a measurement that sees it |
|---|---|
| value | an outcome the change was meant to move, chosen before it shipped |
| the wait before the work | lead time from request to production, lesson 2 |
| quality short of an incident | support tickets, error rates against an objective, lesson 16 |
| the people | a short regular survey, and the on-call load, lessons 8 and 17 |
| work that is not a deployment | flow of all work items, not only code changes, lessons 1 to 4 |

Lesson 19 builds a quarterly report out of exactly these pairs.
