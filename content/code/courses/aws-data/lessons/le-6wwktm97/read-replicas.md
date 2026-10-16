---
title: Read replicas, the copies that run behind
version: 1
---

**A read replica is a separate instance that replays the primary's changes after they are committed.**
It has its own endpoint, it answers queries, and it is always a little behind: the primary commits,
answers the application, and only then ships the change to the replica, which applies it when it gets
there. That gap is **replica lag**, and it is the one property of a replica that every use of it has
to be designed around.

**The wrong idea is that a replica is a backup, or a standby.** It is neither. A `DELETE` without a
`WHERE` on the primary is replayed on the replica a moment later, faithfully, so the replica protects
nothing against a mistake; that is what the backups of the next section are for. And because the
replication is asynchronous, a replica can be missing the last transactions when the primary dies, so
promoting it is a decision to accept that loss. Multi-AZ, synchronous, loses nothing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"One write, in time from left to right, across four lanes: the application, the primary in sa-east-1a, the Multi-AZ standby in sa-east-1b, and a read replica. The application sends COMMIT; the primary writes it to the standby, the standby acknowledges, and only then does the primary answer OK. After the OK, the primary ships the change to the read replica, which applies it later. The gap between the OK and the replica applying it is the replica lag.\" data-fig=\"l07-sync\"><defs><marker id=\"arr-l07-sync\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">application</text><line x1=\"170.0\" y1=\"50.0\" x2=\"700.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primary, sa-east-1a</text><line x1=\"170.0\" y1=\"105.0\" x2=\"700.0\" y2=\"105.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">standby, sa-east-1b</text><line x1=\"170.0\" y1=\"160.0\" x2=\"700.0\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20.0\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">read replica</text><line x1=\"170.0\" y1=\"215.0\" x2=\"700.0\" y2=\"215.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"190.0\" y1=\"50.0\" x2=\"228.0\" y2=\"101.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"200.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"240.0\" y1=\"105.0\" x2=\"278.0\" y2=\"156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><line x1=\"290.0\" y1=\"160.0\" x2=\"328.0\" y2=\"109.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><line x1=\"340.0\" y1=\"105.0\" x2=\"378.0\" y2=\"54.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"392.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OK</text><text x=\"285.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">synchronous: the OK waits</text><line x1=\"420.0\" y1=\"105.0\" x2=\"588.0\" y2=\"211.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"505.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">asynchronous: shipped after the OK</text><circle cx=\"596.0\" cy=\"215.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"610.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">applied</text><line x1=\"384.0\" y1=\"240.0\" x2=\"384.0\" y2=\"252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"596.0\" y1=\"240.0\" x2=\"596.0\" y2=\"252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"384.0\" y1=\"246.0\" x2=\"596.0\" y2=\"246.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"490.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">replica lag</text><line x1=\"384.0\" y1=\"54.0\" x2=\"384.0\" y2=\"240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 2\"></line><text x=\"690.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Multi-AZ waits for the standby before saying OK; a read replica hears about the write only after it."}
```

## What a replica is for

**Reads that can be a moment old.** Quitanda's analysts run reports at nine every morning that read
a month of orders. On the primary, those reports compete with the shop's checkouts for the same cache
and the same disk. On a replica, they compete with nobody. A report two seconds behind the shop is
fine. A customer who places an order and then sees "no orders yet" on a page that reads a replica is
not, and that is why the page a customer just wrote to reads from the primary.

**Up to 15 replicas per primary for PostgreSQL, MySQL and MariaDB**, as AWS documents it, each billed as
an instance of its own class with storage of its own. A replica can have a smaller class than the
primary, but one too small to keep up with the primary's writes falls further behind every hour, so
the lag grows instead of hovering.

Lesson 6's instance, rebuilt in an empty moto without its network, and a replica of it for the
reports:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query DBInstance.DBInstanceStatus
"available"
ana@laptop:~/aws$ aws rds create-db-instance-read-replica --db-instance-identifier quitanda-orders-reports --source-db-instance-identifier quitanda-orders --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,ReadReplicaSourceDBInstanceIdentifier,Endpoint.Address]' --output text
available	quitanda-orders	quitanda-orders-reports.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'
[
    "quitanda-orders-reports"
]
```

## The lag that moto cannot have

**On AWS, the lag is a metric**, `ReplicaLag` in CloudWatch, in seconds, and the replica reports its
replication state in `StatusInfos`. An alarm on the first is how a team learns that the nightly import
is outrunning the replica before the analysts do:

```
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders-reports --query 'DBInstances[0].StatusInfos'
null
ana@laptop:~/aws$ aws cloudwatch get-metric-statistics --namespace AWS/RDS --metric-name ReplicaLag --dimensions Name=DBInstanceIdentifier,Value=quitanda-orders-reports --start-time 2026-10-16T00:00:00Z --end-time 2026-10-17T00:00:00Z --period 60 --statistics Maximum
{
    "Label": "ReplicaLag",
    "Datapoints": []
}
```

**Nothing in either answer, because nothing is replicating.** moto keeps no data on either instance, so
there is no lag to measure and no state to report; on AWS `StatusInfos` would carry a `read replication`
entry with its status, and the metric a point every minute. The lag in the figure above is drawn from
how asynchronous replication works, not from this lab.

## Promotion

**Promoting a replica cuts the link and makes it a standalone, writable instance.** It is how a replica
becomes the new primary after a disaster the Multi-AZ standby could not cover, and how a copy of
production becomes a database of its own for a migration rehearsal. It cannot be undone: the promoted
instance no longer follows anything, and the old primary does not learn to follow it.

```
ana@laptop:~/aws$ aws rds promote-read-replica --db-instance-identifier quitanda-orders-reports --query 'DBInstance.[DBInstanceStatus,ReadReplicaSourceDBInstanceIdentifier]' --output text
available	quitanda-orders
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query 'DBInstances[0].ReadReplicaDBInstanceIdentifiers'
[
    "quitanda-orders-reports"
]
```

**On AWS, the promoted instance would have no source any more, and the primary's list of replicas
would be empty.** moto marked nothing: the promoted instance still names `quitanda-orders` as its source,
and the source still lists it. The command is accepted and its meaning is not modelled, which is the
pattern of this whole lesson.

## In another region

**A replica can live in another region**, for a disaster that takes out São Paulo or to read near
customers on another continent. The request is made in the destination region and names the source by
its ARN:

```
ana@laptop:~/aws$ aws rds create-db-instance-read-replica --db-instance-identifier quitanda-orders-dr --source-db-instance-identifier arn:aws:rds:sa-east-1:123456789012:db:quitanda-orders --region us-east-1 --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceArn,AvailabilityZone]' --output text
arn:aws:rds:us-east-1:123456789012:db:quitanda-orders-dr	sa-east-1a
```

**The ARN says `us-east-1` and the zone says `sa-east-1a`**, a replica in Virginia sitting in a São Paulo
zone. moto built the name for one region and copied the placement from the other; on AWS the zone would be
one of Virginia's. And on AWS the copy costs money that a replica in the same region does not: the
replication traffic leaves São Paulo, and the transfer block prices it:

```
ana@laptop:~/aws$ python3 prices.py transfer
AWS public price list, sa-east-1, USD, excluding tax

Data transfer out of sa-east-1, USD per GB
  to the internet, first 10 TB                          0.15000  GB
  to the internet, next 40 TB                           0.13800  GB
  to the internet, next 100 TB                          0.12600  GB
  to the internet, over 150 TB                          0.11400  GB
  between zones, each direction                         0.01000  GB
  to us-east-1                                          0.13800  GB
  to CloudFront                                         0.00000  GB
  in from the internet                                  0.00000  GB
```

**0.138 a GB to us-east-1.** What crosses is the primary's write-ahead log, everything it writes, not
the size of the database. A primary that writes 300 GB of log in a month pays 300 × 0.138 = 41.40 for
the transfer, on top of the replica's instance and storage in Virginia, which are priced from Virginia's
list and not from this sheet. Within one region, AWS documents no charge for the replication traffic
between a primary and its replicas.

## A condition moto does not check

**On AWS, a replica can only be made from an instance whose automated backups are on**, a retention
period of at least one day, because the replica is built from a backup and the primary's log. moto does
not check:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-scratch --engine postgres --engine-version 16 --db-instance-class db.t4g.micro --allocated-storage 20 --master-username quitanda --manage-master-user-password --backup-retention-period 0 --query DBInstance.BackupRetentionPeriod
0
ana@laptop:~/aws$ aws rds create-db-instance-read-replica --db-instance-identifier quitanda-scratch-copy --source-db-instance-identifier quitanda-scratch --query DBInstance.DBInstanceStatus
"available"
```

The first command turned backups off and the second made a replica anyway. On AWS the second is refused.
The next section is what those backups are.
