---
title: What to page on, and what the bill sees first
version: 1
---

**Cost is slow compared with errors, and paging on every movement is lesson 14's fatigue again.** A cost signal earns
a page only when waiting until the morning would cost more than waking somebody. A set that works for a team the size
of the shop's, with lesson 24's budget and the daily detector of the last section:

| signal | threshold | route |
|---|---|---|
| spike, one service | above 5 USD a day over the usual | ticket, read the same day |
| spike, any | above 25 USD a day, or a service nobody uses | page |
| budget, forecast | above 100% of the month | ticket |
| budget, actual | above 100% before the 20th | page |
| budget stream, pace | three times the usual daily spend | page |

Most rows are tickets. The debug logs of the last section were 20 USD a day: real money, worth a ticket on the 9th and
a fix that week, and not worth anybody's night.

## The two pages that are there for a reason

**A service nobody uses appearing on the bill** is the signature of a stolen credential: machines in a region the team
never deploys to, or a service the shop has never enabled. Lesson 20's Security Command Center may raise the same
thing as a finding; the bill is the second witness, and the one that cannot be switched off from inside the project.
The detector of the last section can be told the list of services the shop uses and report any other at once,
whatever its cost.

**A bill growing three times faster than usual** is a loop, a leak or an attack, whichever lesson it belongs to: a
retry loop calling a paid API, a bucket served to the internet, somebody else's workload. The response is lesson 15's,
and the first mitigation is usually the one lesson 24 refused to automate on production: stopping what is spending.
Done by a person, with the page in hand, it is a decision rather than an accident.

## What the course comes to

Every lesson of this course has been about noticing before a customer does: the pipeline that refuses a bad image, the
alert on the error budget, the finding that names a public bucket. **The bill is the last of those signals and the
slowest, and for some incidents the only one.** A team that reads it every morning, with a ticket for the small
movements and a page for the two that matter, hears about those incidents the same day rather than on the 1st.
