---
title: The drill as a script
version: 1
---

The drill has five steps, and each of them has appeared in an earlier lesson: name a moment, read the
report at it, restore to it on the second server, read the report again, compare. What is new is
that they run unattended, every time the same way, and leave a record. Save this as
`restore-drill.sh` beside `report.sql`:

```schooling-example
{"language": "bash", "file": "restore-drill.sh", "parts": [{"code": "#!/usr/bin/env bash\n# restore-drill.sh: restore the newest backup elsewhere, prove it, throw it away\nset -euo pipefail\nstanza=main\ntarget=/var/lib/postgresql/16/restore\nport=5433\ndbs=\"shop bigshop\"\nlog=\"$HOME/drills.csv\"\nms() { echo $(( $(date +%s%N) / 1000000 )); }\nt0=$(ms)\n", "note": "Stop at the first failure. The settings name the stanza, where the copy goes, and which databases to compare."}, {"code": "label=\"drill-$(date +%Y%m%d-%H%M%S)\"\npsql -X -q -d shop -c \"SELECT pg_create_restore_point('$label')\" > /dev/null\nfor db in $dbs; do\n  psql -X -A -t -d \"$db\" -f report.sql > \"live-$db.txt\"\ndone", "note": "Name the moment the drill restores to, then photograph every database with the report. This assumes nothing writes in the few seconds between the two; the section on moving targets is about when that is false."}, {"code": "sudo -u postgres pgbackrest --stanza=\"$stanza\" check\nbackup=$(sudo -u postgres pgbackrest --stanza=\"$stanza\" info | awk '/ backup: /{b=$3} END{print b}')\n", "note": "check switches the log and waits until it is archived, so the restore point is in the archive before anything is restored."}, {"code": "t1=$(ms)\nsudo pg_ctlcluster 16 restore stop 2>/dev/null || true\nsudo rm -rf \"$target\"\nsudo -u postgres pgbackrest --stanza=\"$stanza\" --pg1-path=\"$target\" \\\n  --archive-mode=off --type=name --target=\"$label\" --target-action=promote restore", "note": "Phase one, the restore: files back from the repository into an empty directory, with archiving off."}, {"code": "t2=$(ms)\nsudo pg_ctlcluster 16 restore start\nuntil psql -X -A -t -p \"$port\" -d shop -c \"SELECT NOT pg_is_in_recovery()\" 2>/dev/null | grep -q t; do\n  sleep 0.2\ndone", "note": "Phase two, the recovery: start the copy and wait until it has replayed to the restore point and been promoted."}, {"code": "t3=$(ms)\nresult=ok\nfor db in $dbs; do\n  psql -X -A -t -p \"$port\" -d \"$db\" -f report.sql > \"restored-$db.txt\"\n  if ! diff \"live-$db.txt\" \"restored-$db.txt\"; then result=DIFFERENT; fi\ndone\nt4=$(ms)\n", "note": "Phase three, the proof: the same report on the copy, compared line for line with the live one."}, {"code": "sudo pg_ctlcluster 16 restore stop\nsudo rm -rf \"$target\"\nsecs() { printf '%d.%d' $(( $1 / 1000 )) $(( $1 % 1000 / 100 )); }\n[ -f \"$log\" ] || echo \"when,backup,restore_s,recovery_s,verify_s,total_s,result\" > \"$log\"\necho \"$(date '+%F %T'),$backup,$(secs $((t2-t1))),$(secs $((t3-t2))),$(secs $((t4-t3))),$(secs $((t4-t0))),$result\" >> \"$log\"\ntail -n 1 \"$log\"\n[ \"$result\" = ok ]", "note": "Throw the copy away, whatever the result, and write one line of history: when, from which backup, how long each phase took, and what it found."}]}
```

It runs as you, with `sudo` for the commands that need it, because it moves files that belong to
`postgres` and runs `psql` as you. The restore targets the **restore point** it created, by name,
which lesson 6 called the cheapest exact target there is. Make it executable, and run it:

```
ana@vm:~$ chmod +x restore-drill.sh
ana@vm:~$ ./restore-drill.sh
2026-10-10 16:50:15,20261010-164946F,2.2,2.5,6.0,16.7,ok
ana@vm:~$ echo $?
0
```

**One line, and an exit status of 0.** Read the line as the drill's whole result: it ran at
16:50:15, restored the full backup `20261010-164946F` plus the archive up to the restore point,
spent **2.2 seconds** putting files back, **2.5** replaying and promoting, **6.0** proving, and
**16.7** in all. The proof is the slowest phase, because fingerprinting three million rows means
reading them on both servers; the total is larger than the three phases because it includes reading
the live reports and the archive `check`.

Every run appends one line to `drills.csv`. The last section of this lesson reads that file, and it
is the most useful thing the drill produces.
