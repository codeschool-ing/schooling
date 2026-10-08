---
title: Correlation, and a rule that was wrong
version: 1
---

**Correlation** is a rule about several events: how many, in what order, within what time. Sigma writes
it as a rule that refers to other rules by name. The first idea most people have is "a failure followed by
a success from the same address, within an hour", which reads like somebody guessing until they got in.
Save it as `rules-v1.yml`:

```yaml
title: SSH login failure
name: ssh_login_failure
id: 3f1d2c6a-8b7e-4e0f-9a52-6c1b0e7d4a10
status: test
description: One failed SSH login, for a known or an unknown account.
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: failure
  condition: selection
level: low
---
title: SSH login success
name: ssh_login_success
id: 6a0c3e9b-2d71-4f58-a1e4-8b9d2c7f0e63
status: test
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: success
  condition: selection
level: informational
---
title: Login accepted from an address that failed first
id: 2b8e5f0d-7c41-4a93-8e6b-d50f1c2a9b37
status: test
correlation:
  type: temporal_ordered
  rules:
    - ssh_login_failure
    - ssh_login_success
  group-by:
    - src_ip
  timespan: 1h
level: high
```

A correlation converts into a long query, so it goes to a file, and a small script runs every query in a
file and shows one row per alert. Save this as `alerts.sh`:

```bash
#!/bin/bash
# alerts.sh RULES.sql: run converted Sigma rules against siem.db, one row per alert
while IFS= read -r query; do
  sqlite3 -header -column siem.db "SELECT group_keys, metric_name AS kind, event_count AS events,
    datetime(occurrence_time, 'unixepoch') AS at_utc FROM ($query)"
done < "$1"
```

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite rules-v1.yml -o v1.sql
Parsing Sigma rules
ana@soc:~/week$ wc -c v1.sql
4788 v1.sql
ana@soc:~/week$ bash alerts.sh v1.sql
group_keys                 kind              events  at_utc             
-------------------------  ----------------  ------  -------------------
{"src_ip":"203.0.113.41"}  temporal_ordered  2       2026-09-14 11:02:51
{"src_ip":"203.0.113.23"}  temporal_ordered  2       2026-09-15 11:39:11
{"src_ip":"203.0.113.23"}  temporal_ordered  2       2026-09-16 11:05:23
{"src_ip":"203.0.113.66"}  temporal_ordered  2       2026-09-17 05:33:07
{"src_ip":"203.0.113.66"}  temporal_ordered  2       2026-09-17 06:05:22
```

Five alerts. Two are from `203.0.113.66` on Thursday night. **Three are not.** Look at one of them:

```
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT timestamp, user, action FROM logs WHERE src_ip = '203.0.113.23' AND product = 'sshd'"
timestamp            user   action 
-------------------  -----  -------
2026-09-14 11:18:38  carla  success
2026-09-15 11:39:01  carla  failure
2026-09-15 11:39:11  carla  success
2026-09-16 11:05:14  carla  failure
2026-09-16 11:05:23  carla  success
2026-09-17 11:35:30  carla  success
2026-09-18 11:59:58  carla  success
```

Carla, from her usual address, failed once and got in ten seconds later, on two different mornings. Her
fingers slipped. The rule cannot tell her from the night's visitor, because one failure then one success
describes both. Three false alerts in a week of five people becomes hundreds in a company of five
hundred, and lesson 6 is about what that does to the people reading them.

The fix is to say what was actually different about Thursday: **one address tried many accounts**, and
*then* one of them worked. Sigma lets a correlation refer to another correlation, so the rule becomes two
steps. Save this as `rules-v2.yml`:

```yaml
title: SSH login failure
name: ssh_login_failure
id: 3f1d2c6a-8b7e-4e0f-9a52-6c1b0e7d4a10
status: test
description: One failed SSH login, for a known or an unknown account.
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: failure
  condition: selection
level: low
---
title: SSH login success
name: ssh_login_success
id: 6a0c3e9b-2d71-4f58-a1e4-8b9d2c7f0e63
status: test
logsource:
  product: linux
  service: sshd
detection:
  selection:
    product: sshd
    action: success
  condition: selection
level: informational
---
title: Many accounts tried from one address
name: many_accounts_one_source
id: 9c4b7e21-5d3a-4f86-b0e2-1a7c9d3e6f58
status: test
correlation:
  type: value_count
  rules:
    - ssh_login_failure
  group-by:
    - src_ip
  timespan: 1h
  condition:
    field: user
    gte: 10
level: high
---
title: Login accepted from an address that tried many accounts
id: 5e7a1c40-3b96-4d2f-8c05-a9e2b7d14f6c
status: test
correlation:
  type: temporal_ordered
  rules:
    - many_accounts_one_source
    - ssh_login_success
  group-by:
    - src_ip
  timespan: 1h
level: critical
```

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite rules-v2.yml -o v2.sql
Parsing Sigma rules
ana@soc:~/week$ bash alerts.sh v2.sql
group_keys                 kind              events  at_utc             
-------------------------  ----------------  ------  -------------------
{"src_ip":"203.0.113.66"}  temporal_ordered  11      2026-09-17 05:33:07
{"src_ip":"203.0.113.66"}  temporal_ordered  11      2026-09-17 06:05:22
```

Two alerts, both from `203.0.113.66`: the password login at 02:33:07 local (05:33:07 UTC), and a second
one half an hour later, with a key. Nobody wrote a rule for that second one; it fell out of a rule that
described the behaviour rather than a single line. Whether those two alerts are an incident is lesson 7's
question.

**Test every rule against a period you know.** v1 looked reasonable and was wrong three times out of five;
only running it against a real week showed that. A rule nobody has run against last month's data is a
guess with a severity attached.
