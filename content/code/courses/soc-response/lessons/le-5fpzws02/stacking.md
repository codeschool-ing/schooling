---
title: Stacking: the interesting end is the short one
version: 1
---

The workhorse of hunting is **stacking**, also called long-tail analysis: count how often each value, or
each combination of values, occurs, and read the **rare end**. Normal behaviour repeats; the unusual
happens once or twice. For H1, stack successful logins by account and address:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT user, src_ip, count(*) AS logins FROM logs WHERE action = 'success' GROUP BY user, src_ip ORDER BY logins"
user    src_ip         logins
------  -------------  ------
bruno   198.51.100.22  1     
bruno   203.0.113.66   2     
ana     203.0.113.11   5     
bruno   203.0.113.17   5     
carla   203.0.113.23   5     
diego   198.51.100.22  5     
diego   203.0.113.31   5     
helena  203.0.113.41   5     
```

Sorted from least to most frequent, the top of the list is where to look. Every person logs in five times
from one address, which is one login per weekday from home. Diego also reaches `files` from `gw`
(`198.51.100.22`) every day; that is his job. Three rows break the pattern, and all three are bruno's:
**twice from `203.0.113.66`**, an address his account never used before, and **once from `gw` to `files`**,
which he never does otherwise. H1 predicted exactly this, and it is there.

H3 stacks by hour instead:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT strftime('%H', timestamp, '-3 hours') AS hour_local, count(*) AS logins FROM logs WHERE action = 'success' GROUP BY hour_local"
hour_local  logins
----------  ------
02          2     
03          1     
08          30    
```

Thirty logins at eight in the morning, the whole company starting work, and **three in the small hours**:
two at 02 and one at 03. Stacking does not say who they were; it says where to look next, and the next
query (lesson 7 already ran it) names bruno's account in all three.

Stacking works because **attackers are rare and organisations are repetitive**. Its weakness is the same
fact: a rare legitimate thing, a new employee or a once-a-quarter job, sits in the short tail too, and the
validation step is where it is told apart.
