---
title: The level they are asked at
version: 1
---

A design question for a senior is an hour on a whiteboard about scale, failure and cost. **For a junior it
is fifteen minutes about whether you can think about a whole system**, not only the part in front of you.
The interviewer is checking three things:

1. **Do you ask before you build?** Who uses it, how many of them, what must never happen.
2. **Can you draw the simplest thing that works**, and name its parts?
3. **Do you know where it breaks first?** Not how to fix everything; which part fails first.

The questions themselves are small, and they depend on the role:

::: track it-support networks-infra
**In support and infrastructure**: *how would you set up the network and accounts for a twenty-person
office?*, *a school wants every classroom computer backed up; how?*, *users on the second floor say the
Wi-Fi drops; how would you find out why?* The answer is a small office drawn on the whiteboard: the
connection, the router, the switch, the access points, the server or the cloud accounts, and the backup.
:::

::: track *
**In development and data roles**: *how would you build a URL shortener?*, *design the tables for a
library's loans*, *how would you import a daily file of sales into a database?* The answer is a few boxes:
who calls what, where the data lives, and the one rule the system must keep.
:::

Either way, the portfolio project is your best preparation. You already designed one small system, with a
rule, a trade-off and a deploy; **a design question is the same conversation about a system you have not
built yet**.
