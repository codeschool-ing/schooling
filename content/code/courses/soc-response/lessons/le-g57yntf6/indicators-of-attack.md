---
title: Indicators of attack: behaviour
version: 1
---

An **indicator of attack (IoA)** describes behaviour rather than a value: what is being done, whatever the
address, the file or the account. Lesson 4's v2 rule was one. Three more, each a query over the week, and
each one would fire on Thursday even if every address in it had been different.

**Who is being guessed.** Lesson 2's distinction, unknown account against wrong password, separates a
person who mistyped from somebody working down a list:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT src_ip, detail, count(*) AS n FROM logs WHERE src_ip IN ('203.0.113.66', '203.0.113.23') AND action = 'failure' GROUP BY 1, 2"
src_ip        detail          n 
------------  --------------  --
203.0.113.23  wrong_password  2 
203.0.113.66  unknown_user    39
203.0.113.66  wrong_password  18
```

Carla's two failures are wrong passwords on her own account. The visitor's are **39 names that do not
exist here** and 18 wrong passwords on names that do. Nobody mistypes their own user name into `printer`.

**A login by a method the account has never used:**

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT user, method, count(*) AS logins, min(datetime(timestamp, '-3 hours')) AS first_local FROM logs WHERE action = 'success' GROUP BY user, method"
user    method     logins  first_local        
------  ---------  ------  -------------------
ana     publickey  5       2026-09-14 08:15:05
bruno   password   7       2026-09-14 08:33:31
bruno   publickey  1       2026-09-17 03:05:22
carla   password   5       2026-09-14 08:18:38
diego   publickey  10      2026-09-14 08:26:10
helena  password   5       2026-09-14 08:02:51
```

Every account keeps one method all week. Bruno's account gains a second, `publickey`, **once**, at 03:05 on
Thursday. A key login is not suspicious by itself (ana and diego use nothing else); a first key login on an
account that has only ever used a password means a key was added, and somebody should know who added it.

**A first transfer to a new destination:**

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT dst_ip, count(*) AS transfers, min(datetime(timestamp, '-3 hours')) AS first_local, sum(bytes) / 1000000 AS mb FROM logs WHERE product = 'flow' GROUP BY dst_ip"
dst_ip         transfers  first_local          mb  
-------------  ---------  -------------------  ----
203.0.113.150  7          2026-09-14 01:00:00  2494
203.0.113.200  1          2026-09-17 02:41:12  612 
```

The backup goes to one address, every night, from Monday. `203.0.113.200` appears once, at 02:41 on
Thursday, with **612 MB**: a first-seen destination receiving a large amount from a server that holds
client files. The amount is not unusual here, since every backup is larger; **the novelty is**.

Each of these is a question about *behaviour against a baseline*, which is why the baseline (lesson 6) is
worth building. They also produce more false positives than an atomic IoC: a new backup provider is a
first-seen destination too. That is the price of detection that lasts, paid in triage time.
