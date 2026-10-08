---
title: From a hunt to a rule
version: 1
---

The best outcome of a hunt that found something is that **nobody has to hunt for it again**. Lesson 9
showed the transfer that mattered: a large upload from `files` to an address that was not the backup.
Written as a rule, with the hunt it came from in its description, save this as `big-upload.yml`:

```yaml
title: Large transfer out to a destination other than the backup
id: 8d2f6b31-4c7e-4a05-9e18-3b7a0c5d2f94
status: test
description: From the hunt of 21 September 2026. The backup provider is the only known large destination.
logsource:
  category: flow
  product: network
detection:
  large:
    product: flow
    bytes|gte: 100000000
  backup:
    dst_ip: 203.0.113.150
  condition: large and not backup
level: high
```

Two selections and a condition with `not`: large flows, except to the one destination known to receive
them. Convert it and run it against the week:

```
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite big-upload.yml
Parsing Sigma rules
SELECT * FROM logs WHERE (product='flow' AND bytes >= 100000000) AND (NOT COALESCE((dst_ip='203.0.113.150'), 0))
ana@soc:~/week$ ~/sigma/bin/sigma convert -t sqlite big-upload.yml -o big.sql
Parsing Sigma rules
ana@soc:~/week$ sqlite3 -header -column siem.db "SELECT timestamp, src_ip, dst_ip, bytes FROM ($(cat big.sql))"
timestamp            src_ip         dst_ip         bytes    
-------------------  -------------  -------------  ---------
2026-09-17 05:41:12  192.168.20.10  203.0.113.200  612408119
```

One row, the 612 MB transfer of Thursday at 02:41 local (05:41:12 UTC), and none of the seven backups.
The threshold of 100 MB is a judgement, and lesson 6's method applies: count what it flags over a known
period before trusting it. Two maintenance tasks come with this rule and belong in its description: the
`backup` list has to change when the company changes provider, and **the rule says nothing about transfers
that stay under 100 MB**, which a patient adversary can arrange.

A hunt that ends in a rule should also update the mapping of lesson 9: T1048.002 now has a detection. Over
time, a team that turns each hunt into rules sees the uncovered cells of its ATT&CK map shrink, and that
map is the simplest honest answer to the question "what can we see?".
