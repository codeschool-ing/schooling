---
title: Measuring alert quality
version: 1
---

A rule's quality is measured with the outcome of each alert, recorded by the analyst who closed it: **true
positive** (it was what the rule said), **false positive** (it was not), and, discovered later and painfully,
**false negative** (something happened and no alert fired).

Lesson 4 gives two rules on the same week, and the outcomes are known:

| rule | alerts | true | false | precision |
|---|---|---|---|---|
| v1, failure then success | 5 | 2 | 3 | 2 / 5 = **40%** |
| v2, many accounts then success | 2 | 2 | 0 | 2 / 2 = **100%** |

**Precision** is the share of a rule's alerts that were true. It is what the people reading the queue feel:
at 40%, more than half their work on that rule is wasted. A rule that sits below, say, 20% for a month is a
rule to rewrite or retire, and the decision should be written down with its numbers.

Precision has a blind side: it ignores what the rule missed. A rule that never fires has no false
positives. That is why a SOC also counts, per incident, **which rule caught it, or that none did**; a
quarter's incidents found by a phone call from a client and not by an alert is the most important number
the team has, and lesson 15 makes it part of every review.

Two more numbers keep a queue healthy: **alerts per analyst per shift**, which says whether people can read
what they receive, and **the share closed without being opened**, which says whether they already stopped.
