---
title: One event, forty-eight alerts
version: 1
---

**Alert fatigue** is what happens to people who receive more alerts than they can read: they stop reading
carefully, then they stop reading, and the alert that mattered is closed with the others. It is not a
character flaw. It is arithmetic, and the arithmetic starts with alerts that are correct.

Take the first half of lesson 4's v2 on its own, the rule that counts accounts tried from one address.
Save it as `spray.yml`:

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
```

Convert it and run it with lesson 4's `alerts.sh`:

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite spray.yml -o spray.sql
Parsing Sigma rules
ana@soc:~/week$ bash alerts.sh spray.sql | head -n 5
group_keys                 kind         events  at_utc             
-------------------------  -----------  ------  -------------------
{"src_ip":"203.0.113.66"}  value_count  10      2026-09-17 05:11:06
{"src_ip":"203.0.113.66"}  value_count  11      2026-09-17 05:11:11
{"src_ip":"203.0.113.66"}  value_count  12      2026-09-17 05:11:16
ana@soc:~/week$ bash alerts.sh spray.sql | tail -n +3 | wc -l
48
```

**Forty-eight alerts, every one of them correct**, for one event: one address guessing for about five
minutes. The correlation re-evaluates its window at each new failure, and every window that still has ten
or more accounts in it is another alert. A tool that pages somebody per row pages them 48 times in five
minutes about the same thing.

The fix is **grouping**: one alert per address per episode, with the count inside it. Save this as
`grouped.sh`:

```bash
#!/bin/bash
# grouped.sh RULES.sql: the same alerts as alerts.sh, one row per address instead of per window
while IFS= read -r query; do
  sqlite3 -header -column siem.db "SELECT group_keys, count(*) AS windows,
    datetime(min(occurrence_time), 'unixepoch') AS first_utc,
    datetime(max(occurrence_time), 'unixepoch') AS last_utc FROM ($query) GROUP BY group_keys"
done < "$1"
```

```
ana@soc:~/week$ bash grouped.sh spray.sql
group_keys                 windows  first_utc            last_utc           
-------------------------  -------  -------------------  -------------------
{"src_ip":"203.0.113.66"}  48       2026-09-17 05:11:06  2026-09-17 05:16:32
```

One row, saying the same thing the 48 said, with the start and the end of the episode. Every SIEM has a
setting for this, under names such as grouping, deduplication, suppression or throttling, and checking it
is the first thing to do with any rule that counts.
