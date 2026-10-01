---
title: Finding the privilege nobody uses
version: 1
---

A rule set accumulates. After a year, some rules grant access nobody uses any more, and some grant more
than anybody uses. Least privilege needs a way to find both, and the firewall already collects the
evidence: **counters**.

The method is plain. Give every `accept` a counter, as lesson 1 did, and read them over a period long
enough to include every legitimate use: a month covers most businesses, a quarter covers the reports
that run at quarter end. Then sort the rules into three groups:

| counter after the period | what it suggests | what to do |
|---|---|---|
| zero | the access is not used, or is shadowed (lesson 18) | find the owner; remove it, or schedule its expiry |
| low and from few sources | the rule is wider than its use | narrow it to those sources and ports |
| high | the access is in use | keep it, and check it still matches its comment |

Flow records (lesson 23) sharpen the second row: they say not only how many packets a rule allowed but
**which pairs of machines** used it, which is exactly what a narrower rule needs to name.

**Every removal is tested before it is permanent.** The safest sequence is the one lesson 5 built for
any change: remove the rule with a scheduled way back, run the matrix test of lesson 18, and watch for
the complaint. An access nobody complains about losing within the period was not needed.

The review itself is a recurring task, not a project. Rules are cheap to add in a hurry and expensive to
remove without evidence, so the evidence has to be gathered continuously, and the counters are already
doing it.
