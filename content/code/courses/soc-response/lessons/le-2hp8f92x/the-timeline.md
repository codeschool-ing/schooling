---
title: The timeline
version: 1
---

The **timeline** is the spine of an investigation: every relevant event, from every source, in one list, in
one time zone. It is where gaps show (nothing between 02:41 and 03:05: what happened?) and where claims are
checked (did the transfer start before or after the login on `files`?). Save this in `~/week` as
`timeline.sql`:

```sql
-- timeline.sql: Thursday night in one list, every source, UTC and local side by side
.headers on
.mode column
SELECT timestamp AS utc, time(timestamp, '-3 hours') AS local, host, product, action,
       coalesce(user, '') AS user, coalesce(src_ip, '') AS src, coalesce(dst_ip, '') AS dst,
       coalesce(bytes, '') AS bytes
FROM logs
WHERE timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30'
  AND (src_ip IN ('203.0.113.66', '198.51.100.22', '192.168.20.10') OR user = 'bruno')
  AND NOT (product = 'sshd' AND action = 'failure')
  AND NOT (product = 'firewall' AND src_ip = '203.0.113.66' AND dst_port = 22)
UNION ALL
SELECT min(timestamp), time(min(timestamp), '-3 hours'), 'gw', 'sshd', count(*) || ' failures',
       count(DISTINCT user) || ' accounts', '203.0.113.66', '', ''
FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'
ORDER BY utc;
```

The first part selects the night's events for the address, the account and the hosts involved, leaving out
the 57 failures and all 59 firewall lines from that address; the second part folds those back in as **one row** that says how
many there were. A timeline that listed every failure would hide the six events that matter under sixty that
do not.

```
ana@soc:~/week$ sqlite3 siem.db < timeline.sql
utc                  local     host   product   action       user         src            dst            bytes    
-------------------  --------  -----  --------  -----------  -----------  -------------  -------------  ---------
2026-09-17 05:10:06  02:10:06  gw     sshd      57 failures  19 accounts  203.0.113.66                           
2026-09-17 05:33:07  02:33:07  gw     sshd      success      bruno        203.0.113.66                           
2026-09-17 05:35:40  02:35:40  files  sshd      success      bruno        198.51.100.22                          
2026-09-17 05:35:40  02:35:40  fw     firewall  connection                198.51.100.22  192.168.20.10           
2026-09-17 05:41:12  02:41:12  fw     firewall  connection                192.168.20.10  203.0.113.200           
2026-09-17 05:41:12  02:41:12  fw     flow      flow                      192.168.20.10  203.0.113.200  612408119
2026-09-17 06:05:22  03:05:22  gw     sshd      success      bruno        203.0.113.66                           
```

Read it top to bottom and it tells the story with nothing added: guessing from 02:10, a password login at
02:33:07, a hop to `files` two and a half minutes later, the firewall seeing it at the same second, a
transfer out at 02:41:12 counted twice (the firewall's first packet and the flow's total), and the return
with a key at 03:05:22.

Three rules keep a timeline honest. **One zone**, stated in the header; here UTC is the reference and local
time is shown beside it. **Each row says where it came from**, so a doubtful entry can be traced to its raw
line. And **inferences are marked as inferences**: "a key was added between 02:35 and 03:05" belongs in the
timeline, labelled as inferred from the 03:05 login, until lesson 17 finds the evidence on disk.
