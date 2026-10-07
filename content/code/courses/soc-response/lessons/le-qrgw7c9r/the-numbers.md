---
title: The numbers
version: 1
---

"What happened, and when" is answered from evidence, not from memory, and the first step is turning the
timeline into **intervals**. Lesson 5 named the three a SOC watches, MTTD, MTTA and MTTR; one incident gives
one value of each, and a few more that only an incident has. Write this as `milestones.sql` in `~/week`:

```schooling-example
{"language": "sql", "file": "milestones.sql", "parts": [{"code": "-- milestones.sql: Thursday's incident in intervals, from the logs and the incident record\n.headers on\n.mode column\nCREATE TEMP TABLE milestone (name TEXT, at TEXT);  -- every time in UTC", "note": "A temporary table, gone when sqlite3 exits: the milestones are worked out each time, never stored beside the logs."}, {"code": "INSERT INTO milestone\n  SELECT 'first guess', min(timestamp) FROM logs WHERE src_ip = '203.0.113.66' AND action = 'failure'\n  UNION ALL\n  SELECT 'first login', min(timestamp) FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success';", "note": "Two milestones come from the logs themselves, so they cannot be misremembered."}, {"code": "INSERT INTO milestone VALUES                   -- from the incident record, INC-2026-014\n  ('alert fired',  '2026-09-17 05:35:00'),\n  ('alert taken',  '2026-09-17 11:12:00'),\n  ('declared',     '2026-09-17 12:12:00'),\n  ('contained',    '2026-09-17 12:45:00'),\n  ('recovered',    '2026-10-02 13:00:00');", "note": "The rest come from the incident record, copied in by hand, in UTC like everything else in siem.db."}, {"code": "SELECT \"from\", \"to\", \"from (UTC)\",\n       printf('%d d %02d h %02d min', s / 86400, s % 86400 / 3600, s % 3600 / 60) AS took\nFROM (SELECT a.name AS \"from\", b.name AS \"to\", a.at AS \"from (UTC)\",\n             strftime('%s', b.at) - strftime('%s', a.at) AS s   -- seconds between the two\n      FROM milestone a, milestone b\n      WHERE (a.name, b.name) IN (VALUES\n        ('first guess', 'first login'), ('first login', 'alert fired'), ('alert fired', 'alert taken'),\n        ('alert taken', 'declared'), ('declared', 'contained'), ('first login', 'contained'),\n        ('contained', 'recovered')))\nORDER BY \"from (UTC)\", s;", "note": "Each pair of milestones becomes one interval, in seconds, printed as days, hours and minutes."}]}
```

The alert time is the one lesson 5 assumed for its worked example; the others are lesson 13's decision log
and the date recovery closed. Run it against the SIEM from lesson 4:

```
ana@soc:~/week$ sqlite3 siem.db < milestones.sql
from         to           from (UTC)           took            
-----------  -----------  -------------------  ----------------
first guess  first login  2026-09-17 05:10:06  0 d 00 h 23 min 
first login  alert fired  2026-09-17 05:33:07  0 d 00 h 01 min 
first login  contained    2026-09-17 05:33:07  0 d 07 h 11 min 
alert fired  alert taken  2026-09-17 05:35:00  0 d 05 h 37 min 
alert taken  declared     2026-09-17 11:12:00  0 d 01 h 00 min 
declared     contained    2026-09-17 12:12:00  0 d 00 h 33 min 
contained    recovered    2026-09-17 12:45:00  15 d 00 h 15 min
```

Read the column on the right from top to bottom, and the night tells its own story:

- **23 minutes** of guessing before a password worked. The firewall saw every attempt; nothing stopped them.
- **1 minute** from the login to the alert. The rule was fine: detection worked.
- **5 hours 37 minutes** from the alert to a person taking it. This is the night's longest step, and nobody
  did anything wrong in it: nobody was supposed to be awake.
- **1 hour** from taking the alert to declaring, spent confirming with bruno's manager, by lesson 7's rules.
- **33 minutes** from declaring to contained. The playbook and the runbooks did their job.
- **7 hours 11 minutes** from the first login to containment: the intruder's window. The data left in the
  first eight minutes of it, which is the uncomfortable part.
- **15 days** of recovery, most of it the two weeks of closer monitoring lesson 14 asked for.

The numbers do not say anybody was slow. They say **where the time went**, and it went to a gap between an
alert and a person. That is a finding about the system, which is exactly what a review is looking for.

Keep `milestones.sql`. The next incident gets the same query with different times, and after a few the
*mean* in MTTD and MTTA starts to mean something.
