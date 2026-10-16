---
title: Watching the log for the shape of damage
version: 1
---

Damage to a database has a shape before anybody reads a single row: an enormous amount of change in a
very short time. Rewriting every row of every table writes the write-ahead log at a rate ordinary
traffic never reaches, and lesson 4's LSN arithmetic can measure that rate every few seconds. Save
this as `walwatch.sh`:

```schooling-example
{"language": "bash", "file": "walwatch.sh", "parts": [{"code": "#!/usr/bin/env bash\n# walwatch.sh: say how much log was written in each interval, and shout past a limit\nset -euo pipefail\ninterval=${1:-5}\nlimit_mb=${2:-50}\nlast=$(psql -X -A -t -d shop -c \"SELECT pg_current_wal_lsn()\")\nwhile sleep \"$interval\"; do\n  now=$(psql -X -A -t -d shop -c \"SELECT pg_current_wal_lsn()\")\n  mb=$(psql -X -A -t -d shop -c \"SELECT (pg_wal_lsn_diff('$now', '$last') / 1048576)::int\")", "note": "Every interval, read the server's position in the log and print how many megabytes were written since the last reading."}, {"code": "  if [ \"$mb\" -gt \"$limit_mb\" ]; then\n    echo \"$(date +%T) ${mb} MB  ALERT: more than ${limit_mb} MB in ${interval} s\"\n  else\n    echo \"$(date +%T) ${mb} MB\"\n  fi\n  last=$now\ndone", "note": "Past the limit, the line says so. In production this line would page somebody instead of printing."}]}
```

On the shop, ordinary work writes almost nothing, so a limit of 10 MB in 5 seconds is generous. On a
real system the limit comes from watching normal days first, and it is set above the busiest normal
moment, such as the nightly batch.

Start it in the background. Then play the intruder's last step yourself, on your own lab: rewrite
every customer's name and city into noise, and every order's total into one cent.

```
ana@vm:~$ ./walwatch.sh 5 10 > walwatch.log &
shop=# UPDATE customers SET name = md5(name), city = md5(city);
UPDATE 1000

shop=# UPDATE orders SET total_cents = 1;
UPDATE 50003
ana@vm:~$ cat walwatch.log
21:54:17 0 MB
21:54:22 19 MB  ALERT: more than 10 MB in 5 s
21:54:27 0 MB
```

**`19 MB  ALERT`** in the interval when the two statements ran, and quiet on either side. The two
`UPDATE`s are plain SQL that anybody with the rights could type, which is exactly the point: nothing
about them is unusual except how much they changed at once.

The shop looks like this now:

```
shop=# SELECT name, city FROM customers ORDER BY id LIMIT 3;
               name               |               city               
----------------------------------+----------------------------------
 1c1e3dd095316f30724ac021ca3b95b8 | fec8c8f7fccdb0825811a7ad2cb2e0a0
 e3adaa38a12fed1f930b3ba74afddffa | 0164ddf9ddc99107b29e7107530e700b
 58b905bf1e0555ce2c8b3912192cd7a9 | 3b7bf0a2e00574c0530f21aa8d315782
(3 rows)

shop=# SELECT count(*), sum(total_cents) FROM orders;
 count |  sum  
-------+-------
 50003 | 50003
(1 row)
```

A rate alert does not say what happened, only that something large did, and when. **The when is what
the recovery needs**: the alert's time, minus one interval, is a point before the damage, and lesson
6 knows how to restore to it. The same signal catches a migration somebody ran without telling
anyone, a runaway job, and a mistaken update; all of them are worth a page.

## What else to watch

The log rate catches the damage. The earlier steps of an attack leave other traces, and each one is
cheap to watch:

- **Backups disappearing**: the number of backups in each repository should only grow between
  retention runs; a drop outside the schedule is an alarm.
- **Backup or archive jobs that stopped**: lesson 4's `pg_stat_archiver` alerts and lesson 5's
  nightly job already catch this, if their silence is also alerted on.
- **New roles, new superusers, new functions**: the inventory in the next section, compared every
  day with the day before.
