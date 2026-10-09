---
title: A hypothesis that can be wrong
version: 1
---

A useful hypothesis has three properties: it is **specific** enough to point at data, **testable** with
the data you have, and **falsifiable**, which means a result exists that would prove it wrong. "We may have
been hacked" fails all three. Three that pass, for the lab's company, each from a different source of
inspiration:

| | hypothesis | inspired by | data |
|---|---|---|---|
| **H1** | if an account was used by somebody other than its owner this week, it logged in from an address that account had never used | ATT&CK T1078, Valid Accounts | successful logins, by account and address |
| **H2** | if anybody reached `files` other than through `gw`, there is a login on `files` from an address that is not `gw`'s | the network design: `files` should be reachable only from `gw` | logins on `files`, by source |
| **H3** | if a person's account was used out of hours, there are logins at hours nobody works | the company's habits: everybody starts around eight | successful logins, by hour |

Notice the shape: **"if this happened, then this would be in the data."** The second half is what makes a
hypothesis testable, because it names exactly what to look for and where. It also tells you what absence
means: if H2's data show no source but `gw`, H2 is false for this week, and you can say so.

Hypotheses come from four places. Intelligence: lesson 8 said guessing campaigns hit the sector. ATT&CK: pick a
technique and ask what it would leave in your logs. The environment's own design: what should never happen
here? And the last incident: what would the same thing look like next time?
