---
title: When the measured number misses the promise
version: 1
---

The point of measuring is to find out, on a quiet day, that the setup does not meet the promise. Then
there are only two honest moves: change the setup, or change the promise. Pretending is the third
move, and the incident ends it.

## Levers on the RPO

| lever | what it buys | what it costs |
|---|---|---|
| a shorter `archive_timeout` | loss bounded to that interval on a quiet server | empty 16 MB segments in the archive |
| a streaming receiver (`pg_receivewal`) | loss of a fraction of a second | a second machine, a slot to watch |
| a replica (lesson 11) | the same, plus a server ready to take over | a second server, permanently |
| synchronous replication (lesson 12) | **zero** loss for a lost server | every commit waits for the network |

None of them helps against a mistaken `DELETE`. For that the RPO is set by point-in-time recovery,
which can stop at any moment, and by how long the archive is kept.

## Levers on the RTO

The restore's two phases point at different levers:

- **Copying the files back** shrinks with faster storage and network, parallelism (`process-max` in
  pgBackRest), and a restore server that already exists rather than one ordered on the day.
- **Replaying the log** shrinks with **more frequent backups**, because a restore starts from the
  newest backup of any kind and replays only what came after it. Lesson 5's daily differential was
  not only about storage: it caps the replay at one day of log instead of a week's.
- **Everything else** (noticing, deciding, finding the person with the password) shrinks with
  alerting that works, a runbook (lesson 24), and rehearsal (lesson 23). In real incidents those
  minutes are often more than the restore's.

And when every lever is pulled and the restore still cannot fit, the RTO is telling you that a
restore is the wrong tool for that failure. The answer is a server that is **already restored and
kept current**, which is where the course goes next: lessons 11 to 21 build exactly that, and lesson
9 first moves the backups somewhere a lost machine cannot take them.
