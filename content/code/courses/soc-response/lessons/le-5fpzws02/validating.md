---
title: Validating, and the negative result
version: 1
---

A stack points; it does not prove. **Validation** asks whether the rare thing is what the hypothesis says it
is, using data the search did not use. For H1's three rows, lesson 7 already did the work: the address
tried 19 accounts first, the account's owner logged in normally from home that same morning, and a large
transfer followed. Independent facts, all pointing one way: the finding is confirmed and goes to incident
response.

H2 comes back differently:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT src_ip, count(*) AS n FROM logs WHERE host = 'files' GROUP BY src_ip"
src_ip         n
-------------  -
198.51.100.22  6
```

Every one of the six logins on `files` came from `gw`'s address. **H2 is false for this week**: nobody
reached `files` except through `gw`. That is a **negative result**, and it is worth exactly as much as the
precision with which it is written down:

```localised
Hunt H2, 21 Sep 2026, ana
Hypothesis: somebody reached files other than through gw.
Data: siem.db, sshd logins on files, 14 to 20 Sep 2026 (6 events).
Method: count logins on files by source address.
Result: negative. All 6 from 198.51.100.22 (gw).
Limits: covers SSH only; files' other services do not log to the SIEM.
```

The last line is the important one. A negative result says nothing about data that was not searched, and
**a hunt that does not state its limits will be read as covering more than it did**. Here, it is also a
gap to fix: if `files` had a second way in, the SIEM would not see it.
