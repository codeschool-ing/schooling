---
title: Reading a dashboard with questions
version: 1
---

Here is a dashboard a director might be shown for the Billing team at the end of September, and two readings of it. The numbers are the ones lesson 5 computed.

| metric | June and July | August and September |
|---|---|---|
| deployments per week | 1.0 | 4.4 |
| lead time for changes, median | 51 hours | 4.5 hours |
| change failure rate | 22% (2 of 9) | 5% (2 of 38) |
| time to restore, median | 166 minutes | 52 minutes |

## The first reading

"Every number improved by a factor of three or more. The team is now in a much better place, so let's set next quarter's targets: eight deployments a week and a failure rate under 3%."

Every sentence in that reading is accurate except the last, and the last undoes the rest. It turns four symptoms into four targets, which is the move this lesson began by warning against, and it sets them without asking what produced the improvement, so nobody knows whether the team can push further or what it would cost.

## The second reading

The second reader asks questions, and each question comes from one of this lesson's sections.

- **What changed?** A limit on work in progress and reviews done first. No tooling, no new people. *The symptom moved because a habit changed.*
- **Is the improvement in the numbers, or in the definitions?** The definitions were the same across the four months. *A change of definition looks exactly like an improvement.*
- **How many events are behind each rate?** Nine deployments before, thirty-eight after; two failures in each period. The "before" rate is fragile. *Quote counts where rates are thin.*
- **What can these numbers not see?** The backlog: requesters still waited a month in September, most of it before anybody started. The people: nothing here says whether the change cost anybody evenings. The blocked bug: forty days old, invisible to all four. *Every dashboard needs its blind spots written beside it.*
- **What would we do next?** Shorten the backlog; make blocked items count; keep the habits. Not "deploy eight times a week".

The second reading takes longer, and it is the only one that tells the director something they can act on. **A good reader of a DORA dashboard spends more time on its edges than on its numbers.** Lesson 19 turns that habit into the structure of a quarterly report.
