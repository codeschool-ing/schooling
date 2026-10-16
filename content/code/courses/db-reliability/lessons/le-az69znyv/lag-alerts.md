---
title: An alert that fires when the standby is gone
version: 1
---

The obvious alert is a query that lists every standby more than some amount behind, with an alert
whenever it returns a row. With the standby connected and current, it returns nothing, which is right.
Now stop the standby and ask again:

```
ana@vm:~$ psql -XAt shop -c "SELECT application_name FROM pg_stat_replication WHERE pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) > 64 * 1024 * 1024"
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ psql -XAt shop -c "SELECT application_name FROM pg_stat_replication WHERE pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) > 64 * 1024 * 1024"; echo "exit $?"
exit 0
```

Nothing, and `exit 0`. **A standby that is not connected has no row in `pg_stat_replication`**, so it
is behind by nothing, and the check that was meant to find the worst lag of all passes in silence. The
same thing happens to `SELECT max(...)` over the view, which returns a null that no comparison is ever
true for. Every check of this kind has to be written the other way round: start from the list of
standbys that **should** exist, and treat a missing one as the loudest failure.

This script does that. Save it as `lagcheck.sh` in your home directory and make it executable with
`chmod +x lagcheck.sh`:

```schooling-example
{"language": "sh", "file": "lagcheck.sh", "parts": [{"code": "#!/bin/sh\n# lagcheck.sh: says how far behind each standby is; exits 1 if one is\n# missing or too far behind\n# usage: ./lagcheck.sh standby1 [standby2 ...]", "note": "Called with the names of the standbys that should exist. The list is the point: the script cannot tell a standby that is missing from one that was never there unless somebody wrote down which ones are expected."}, {"code": "max_bytes=$((64 * 1024 * 1024))\nmax_seconds=30\nstatus=0\n\nfor name in \"$@\"; do", "note": "The two limits. Bytes say how much would be lost or has to be replayed; seconds say how stale a read is. Pick them from lesson 8's RPO, not from what looks normal today."}, {"code": "  row=$(psql -XAtq -F ' ' shop -c \"\n    SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)::bigint,\n           coalesce(extract(epoch FROM replay_lag), 0)::int\n    FROM pg_stat_replication WHERE application_name = '$name'\")", "note": "One row per expected name. `-A -t` print bare values, and `-F ' '` separates them with a space, so the shell can split them. A missing `replay_lag` counts as zero, because the column is empty when the standby is idle and current."}, {"code": "  if [ -z \"$row\" ]; then\n    echo \"$name: NOT CONNECTED\"\n    status=1\n    continue\n  fi\n  bytes=${row% *}\n  seconds=${row#* }\n  if [ \"$bytes\" -gt \"$max_bytes\" ] || [ \"$seconds\" -gt \"$max_seconds\" ]; then\n    echo \"$name: BEHIND by $bytes bytes, $seconds s\"\n    status=1\n  else\n    echo \"$name: ok, $bytes bytes, $seconds s\"\n  fi\ndone", "note": "No row is the case the naive query missed, so it is the first one tested."}, {"code": "exit $status", "note": "The exit status is what a scheduler or a monitoring system reads. The printed line is for the person it wakes up."}]}
```

Run it while the standby is down, then after starting it, and then with the standby's replay paused
while `pgbench` writes for forty seconds:

```
ana@vm:~$ ./lagcheck.sh standby1; echo "exit $?"
standby1: NOT CONNECTED
exit 1
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ ./lagcheck.sh standby1; echo "exit $?"
standby1: ok, 0 bytes, 0 s
exit 0
ana@vm:~$ pgbench -c 4 -T 40 -n bench > /dev/null 2>&1
ana@vm:~$ ./lagcheck.sh standby1; echo "exit $?"
standby1: BEHIND by 45096800 bytes, 40 s
exit 1
```

Three answers, each with its own exit status: **missing, current, behind.** The first is the one the
naive query could not give.

## Where it runs

Not on the primary's own schedule alone. A check that runs on the primary dies with the primary, and
the night the primary's machine is gone is a night somebody wants to know about the standby. Run it
from the place that already watches your servers, every minute, with its exit status turned into a
message to a person; lesson 5's nightly job and this one can share that path. And test the alert the
way this section did: **stop the standby on purpose and see the message arrive.** An alert nobody has
seen fire is the same kind of claim as a backup nobody has restored.
