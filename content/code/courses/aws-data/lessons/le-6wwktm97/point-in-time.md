---
title: Automated backups and point-in-time recovery
version: 1
---

**RDS's automated backups are a daily snapshot and a continuous log, and together they can rebuild the
database as it was at any second of the retention period.** Once a day, in the backup window, RDS takes
a snapshot of the volume. Between snapshots, it copies the engine's transaction log to S3 every five
minutes. To restore to 14:32:10 on Tuesday, RDS takes the last snapshot before that moment and replays
the log up to it. That is **point-in-time recovery**, and it is the answer to the mistake a replica
faithfully copies: the `DELETE` without a `WHERE`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Seven days of automated backups, from 10 to 16 October. One snapshot a day in the backup window, and under them a continuous transaction log copied to S3 every five minutes. The latest restorable time is a few minutes before now. A restore to Tuesday 13 October at 14:32 takes the snapshot of that day and replays the log up to 14:32, and the result is a new instance, quitanda-orders-restored, with its own endpoint, beside the original, which is not changed.\" data-fig=\"l07-pitr\"><defs><marker id=\"arr-l07-pitr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">snapshots</text><rect x=\"88.0\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"103.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"170.9\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.9\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11</text><rect x=\"253.7\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"268.7\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12</text><rect x=\"336.6\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"351.6\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">13</text><rect x=\"419.4\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"434.4\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14</text><rect x=\"502.3\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"517.3\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15</text><rect x=\"585.1\" y=\"55.0\" width=\"30.0\" height=\"22.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.1\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">16</text><text x=\"20.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">transaction log, to S3 every five minutes</text><rect x=\"70.0\" y=\"110.0\" width=\"570.0\" height=\"10.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"70.0\" y1=\"140.0\" x2=\"660.0\" y2=\"140.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"70.0\" y1=\"132.0\" x2=\"70.0\" y2=\"148.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"70.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">7 days back</text><line x1=\"660.0\" y1=\"104.0\" x2=\"660.0\" y2=\"148.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><text x=\"660.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">now</text><line x1=\"640.0\" y1=\"104.0\" x2=\"640.0\" y2=\"126.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></line><text x=\"636.0\" y=\"176.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">LatestRestorableTime</text><line x1=\"386.6\" y1=\"52.0\" x2=\"386.6\" y2=\"148.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></line><text x=\"392.6\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Tue 13 Oct, 14:32</text><line x1=\"386.6\" y1=\"150.0\" x2=\"386.6\" y2=\"205.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#arr-l07-pitr)\"></line><rect x=\"236.6\" y=\"212.0\" width=\"300.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"386.6\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda-orders-restored</text><text x=\"386.6\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new instance, with a new endpoint</text></svg>", "caption": "A restore replays the log onto the day's snapshot, up to the second asked for, and makes a new instance from it."}
```

**The retention is between 1 and 35 days**, and 0 turns automated backups off, and with them
point-in-time recovery, and, as the previous section said, read replicas. The latest moment you can
restore to is a field of the instance, `LatestRestorableTime`, which AWS documents as typically within
the last five minutes: the log has to have reached S3.

## In moto

Lesson 6's instance in an empty moto, with seven days of retention:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query 'DBInstance.[BackupRetentionPeriod,PreferredBackupWindow]' --output text
7	13:14-13:44
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].[InstanceCreateTime,LatestRestorableTime]' --output text
2026-10-16T16:08:45.120830+00:00	2026-10-16T16:08:45.983711+00:00
```

**The backup window is a half-hour moto chose**, `13:14-13:44` in UTC, which is mid-morning in São Paulo.
On AWS a window you do not choose is also picked for you, from an eight-hour block per region, and a
company whose quietest hour is four in the morning sets it there with `--preferred-backup-window`. The
latest restorable time is less than a second after the instance was created: in moto, the log is "in S3" at once,
because there is no log.

## A restore is a new instance

**This is the part that surprises people, on the day it matters.** A point-in-time restore does not
rewind the instance. It creates a second instance, with a name you give it and an endpoint of its own,
and leaves the original exactly as it was:

```
ana@laptop:~/aws$ aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier quitanda-orders --target-db-instance-identifier quitanda-orders-restored --use-latest-restorable-time --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,Endpoint.Address]' --output text
available	quitanda-orders-restored.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,Endpoint.Address]' --output text
quitanda-orders	quitanda-orders.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
quitanda-orders-restored	quitanda-orders-restored.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
```

**Two instances, two addresses.** The application is still talking to `quitanda-orders`, with the
deleted rows still deleted. The restored copy, `quitanda-orders-restored`, holds the data as it was, at a
different endpoint, and until somebody acts, nobody is using it. What happens next is a decision, and
there are two common ones. One is to copy back what was lost: query the restored instance for the
deleted rows and insert them into the original, which keeps everything written since the mistake. The
other is to switch over: point the application at the restored instance, or rename the two so the
restored one takes the old name, which loses everything written after the restore point.

**Name the network and the configuration in the restore command**, too. Unless they are given, AWS
documents that the restored instance comes up with the default security group and the default parameter
group, which means the application servers may not be able to reach it, and `max_connections` is back
to the formula. A restore rehearsed once, on a quiet day, with the commands written down, is the only kind
that goes well at three in the morning.

**A restore takes time on AWS**, a new volume built from a snapshot and a log replayed into it, and the
time grows with the size of the database and the amount of log to replay. None of that was run here.

## What moto lets through

```
ana@laptop:~/aws$ aws rds restore-db-instance-to-point-in-time --source-db-instance-identifier quitanda-orders --target-db-instance-identifier quitanda-orders-october --restore-time 2026-10-01T09:00:00-03:00 --query DBInstance.DBInstanceStatus
"available"
ana@laptop:~/aws$ aws rds modify-db-instance --db-instance-identifier quitanda-orders --backup-retention-period 36 --apply-immediately --query DBInstance.BackupRetentionPeriod
36
```

**A restore to the first of October was accepted, for an instance created on the sixteenth.** On AWS the
restore time has to fall inside the window, between the earliest restorable time and
`LatestRestorableTime`, and anything else is refused. And a retention of 36 days was accepted where AWS's
maximum is 35. Two numbers moto could have checked and did not; on a real account, the first mistake
costs a failed restore and the second a failed command, and both are cheaper to learn here.

**Backups beyond the allowance cost 0.095 a GiB-month**, as lesson 6 priced them. Seven days of a slowly
changing 100 GiB database stays near the allowance of 100 GiB; thirty-five days of one that rewrites a
large table every night grows well past it, because every changed block is kept for the whole window.
