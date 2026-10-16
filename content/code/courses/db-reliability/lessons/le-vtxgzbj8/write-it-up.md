---
title: The write-up, without blame
version: 1
---

After the incident, the write-up turns what happened into what changes. Its form is settled and worth
keeping to, because a write-up that changes shape every time is one nobody compares with the last:

```localised
Title       Orders failed for 30 seconds: primary pg1 lost
Date        ...
Authors     ...
Status      draft / reviewed / actions done

Summary     Two or three sentences: what broke, for how long, what customers saw.
Impact      Measured: how long, how many requests or orders failed, how much
            data was lost (the RPO actually suffered), how long to recover
            (the RTO actually achieved).
Timeline    One line per event, with its time and its source.
Causes      What made it happen, and what made it as bad as it was. Several,
            usually; "human error" is never one of them on its own.
What went   Things that worked and should be kept.
well
Actions     Each one a change, with an owner and a date. "Be more careful"
            is not an action.
```

**Blameless** means the write-up asks how the system let a person's reasonable action cause harm,
never who to punish. People hide what they did when they will be blamed for it, and a write-up is
only as good as what people are willing to put in it.

The timeline field above is what the previous section built from what this incident left on disk. Its actions,
for an incident like this one, might be: make `orders.sh`'s real counterpart retry with lesson 19's
rules, so that thirty seconds of failed orders become thirty seconds of slow ones; add an alert on
HAProxy's primary changing, so that a person knows within a minute rather than from the shop's
support inbox; and rehearse the failover every quarter, which is lesson 23.
