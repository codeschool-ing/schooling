---
title: A runbook that is checked, not trusted
version: 1
---

A runbook decays in a particular way: the steps keep reading well while the things they name change.
A server is renamed, a port moves, a standby is retired, and the page still says to connect to it. The
cure is the one this course applies to everything: **check it by machine, on a schedule.**

Save this runbook as `runbook.md`, with your own names where they differ. It is in the format this lesson
described, for the cluster you built in lessons 16 to 19. One line in it is out of date on
purpose, the way such lines usually are, from an earlier arrangement nobody removed:

```localised
# Runbook: the shop's database

Start here    ./status.sh  (the state of everything, now)
Owner         Ana; the on-call list when she is away
Last tested   rehearsal of the 16th, followed by somebody else

## Where things are
Writes        127.0.0.1:5000  HAProxy, always the primary
Reads         127.0.0.1:5001  HAProxy, the replicas in turn
Nodes         127.0.0.1:5441  127.0.0.1:5442  127.0.0.1:5443
Reports       127.0.0.1:5434  standby for the reporting team
Consensus     etcd, localhost:2379

## 1. The leader died
Expect        a new leader within about 30 s; orders fail meanwhile
Check         ./status.sh: one Leader, two Replicas, port 5000 on it
If not        patronictl -c ~/patroni/pg1.yml list, and see 3
Then          leave the dead node down until its cause is known;
              start it with: patroni ~/patroni/<node>.yml
Done when     the node is a streaming Replica again
Tell          support at the start; everybody when done

## 2. A node will not rejoin
## 3. etcd is down: writes stop
## 4. Rows deleted by mistake: delayed replica, or PITR
```

Then a check that reads it. Every address of the form `127.0.0.1:port` in the file is a database
somebody might be told to connect to in the middle of the night, so each one is asked whether it
answers, with `pg_isready`, PostgreSQL's own tool for exactly that question:

```schooling-example
{"language": "sh", "file": "runbook-check.sh", "parts": [{"code": "#!/bin/sh\n# runbook-check.sh: does every database address in the runbook answer?\nstatus=0\nfor a in $(grep -o '127\\.0\\.0\\.1:[0-9]*' runbook.md | sort -u); do", "note": "Every host:port the runbook names, once each."}, {"code": "  if pg_isready -q -t 3 -h \"${a%:*}\" -p \"${a#*:}\"; then\n    echo \"ok       $a\"\n  else\n    echo \"NO REPLY $a\"\n    status=1\n  fi\ndone", "note": "pg_isready connects and asks; -t 3 gives up after three seconds. It prints nothing with -q, so the script writes its own line."}, {"code": "exit $status", "note": "Exit 1 when anything did not answer, so that a scheduler can turn it into a message to the runbook's owner."}]}
```

```
ana@vm:~$ ./runbook-check.sh; echo "exit $?"
ok       127.0.0.1:5000
ok       127.0.0.1:5001
NO REPLY 127.0.0.1:5434
ok       127.0.0.1:5441
ok       127.0.0.1:5442
ok       127.0.0.1:5443
exit 1
```

Five addresses answer, and **one does not**: 5434, the standby the reporting team was told to use,
from lessons 11 to 15, which the cluster of lessons 16 to 19 replaced. The check found in a moment
what a person would have found at the worst possible moment, typing the address from the page and wondering whether the
problem was them. Run it from the same scheduler as lesson 13's `lagcheck.sh`, and treat its failure
the same way: a message to whoever owns the runbook, because a wrong page is a defect, not a typo.

A check like this covers addresses. The **steps** are checked the only way steps can be: by somebody
other than the author following them, in lesson 23's rehearsal and lesson 7's drill, and correcting the
page where it was wrong, the same day.
