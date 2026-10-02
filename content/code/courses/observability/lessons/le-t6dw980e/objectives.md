---
title: Objectives, and why not one hundred per cent
version: 1
---

An SLI is a measurement. An **SLO**, a *service level objective*, is a target for it over a window:
**99.5% of checkouts succeed, over a rolling 28 days.** Three choices are inside that sentence, and
each is a decision somebody should be able to defend.

**The number.** One hundred per cent is the answer everybody gives first, and it is wrong for two
reasons that have nothing to do with ambition. The customer cannot tell 100% from 99.99%, because
their own phone, network and payment provider fail more often than that. And a target of 100% makes
every change a threat, since any release can fail: the only safe system is one that never changes,
and a shop that never changes loses to one that does. The number should sit where customers start to
notice and complain, which is learnt from what they say and from the SLI's own history. It should
also be a little stricter than what the service already does on a good month, so that it means
something.

**The window.** Twenty-eight days is common because it always holds four of each weekday, so a
Monday rush is never counted twice against a month with one fewer. A rolling window forgets an
incident 28 days later. A calendar window resets on the first of the month, which is easier to
report and gives the last days of a bad month a perverse freedom.

**Each nine is a factor of ten.** The table is the same arithmetic as lesson 6's cost tables, and
it is the one to show anybody who asks for another nine:

| objective | failures allowed per million | total outage allowed in 28 days |
|---|---|---|
| 99% | 10 000 | 6 h 43 min |
| 99.5% | 5 000 | 3 h 22 min |
| 99.9% | 1 000 | 40 min |
| 99.99% | 100 | 4 min |

Four minutes in 28 days is less time than it takes to notice an alert, read it and open a laptop.
**An objective tighter than the team can respond is a promise nobody can keep**, and it is the most
common way SLOs stop being taken seriously.

An SLO is internal. An **SLA**, an agreement, is the version written into a contract, with a refund
or a penalty when it is missed. It is always looser than the SLO, so that the team hears about
trouble from its own objective long before the contract does.