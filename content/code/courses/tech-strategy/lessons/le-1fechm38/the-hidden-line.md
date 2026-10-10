---
title: The line nobody invoices
version: 1
---

Of the four lines, **operation is the one that hides**, and at Coreto it is also the largest. The
self-hosted stack costs R$ 475,200 to operate over three years against R$ 151,200 for its
machines: three reais of people for every real of hardware. A comparison that leaves it out has
not made a small error. It has left out three quarters of one option's cost.

## Why it hides

Nobody decides to hide it. It hides because of how it is spent.

**It arrives in pieces.** Nobody spends 1,056 hours on the observability stack in one go. Somebody
spends a Tuesday afternoon on an upgrade, somebody else is woken in the night because the log disks
are full, somebody answers the Checkout team's questions about a missing metric, and before
every big on-sale somebody adds capacity because log volume climbs with traffic. Each piece is
small and looks like part of the job, and the sum is never written down anywhere.

**It is paid from another budget.** The vendor's invoice comes out of licences and software,
where somebody reviews every line. The engineers' salaries come out of headcount, which is paid
whether they operate a log store or build something else. Lesson 11 takes the engineering budget
apart line by line; here it is enough to see that the two options draw on different lines, and
only one of them is examined when the decision is made.

**The people doing it count it as their work.** Ask Platform what the stack costs and the honest
first answer is the hardware, because the hours are simply what the team does. Rafaela had to ask
the question a different way — how much of last quarter went on keeping it running? — to get a
number at all.

## Measuring it

Operation can be measured with the same tools lesson 5 used for a debt's interest, because it is
the same kind of cost: hours paid every sprint for as long as the thing exists.

| source | what it gives you |
|---|---|
| a time log kept for a month or two | the honest total, if people log the small pieces as well as the big ones |
| the on-call pages about the stack itself | the night work, which nobody remembers in daytime |
| tickets and chat questions routed to the team | the support load other teams put on it |
| the upgrade history | how many upgrades a year, and how long each one took |

Rafaela's team kept a time log and checked it against the pages and the upgrade history. It came to 60% of one engineer: **1,056 hours a year, R$ 158,400 at R$ 150 an hour.** The
60% is not one person. It is slices of several people's weeks, which is the other reason nobody
had seen it.

The hosted service's operation was estimated the same way, from what the vendor's own setup asks
of a customer: a tenth of an engineer, 176 hours a year. **Hosted is not zero operation**, and a
sheet that puts zero there is making the mirror-image mistake.

## "We pay them anyway"

The objection arrives every time: the Platform engineers are on the payroll whatever they do, so
their hours are free. It is wrong in a way worth stating precisely. Their salary is paid either
way; **their hours are spent only once.** An hour on the log store is an hour not spent on the work
the Platform team exists for — and at Coreto that list includes the load test that replays an
on-sale, one of the four actions in lesson 1's strategy. Lesson 13 prices that kind of loss as
opportunity cost. For a TCO, the rule is simpler: a person's hour is converted at the same R$ 150
whatever the person would otherwise be doing, so that the hosted invoice and the self-hosted hours
are measured in the same unit.

## What it does to the answer

Set the two operation lines beside the two licence lines:

| | hosted | self-hosted |
|---|---|---|
| licence, three years | R$ 275,400 | R$ 151,200 |
| operation, three years | R$ 79,200 | R$ 475,200 |

On licence alone self-hosting wins by R$ 124,200. The operation line runs the other way by
R$ 396,000. **The line that nobody invoices is more than three times the size of the difference
everybody was looking at.** The next section puts all four lines in your spreadsheet and adds
them up.
