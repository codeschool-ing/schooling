---
title: Manual snapshots, the backups nobody deletes for you
version: 1
---

**A manual snapshot is a copy of the volume that RDS keeps until you delete it.** Automated backups
belong to the instance: they roll off when the retention period passes them, and by default they go
when the instance goes. A manual snapshot belongs to the account. It outlives the instance it was taken
from, it can be copied to another region or shared with another account, and it is how a database is
kept for longer than 35 days: before a risky migration, at the end of a financial year, or before the
instance is deleted.

**It is not a point in time you can move.** A snapshot holds the volume at one moment and nothing after
it; there is no log beside it to replay. So a snapshot answers "the database as it was before the
migration", and point-in-time recovery answers "the database as it was at 14:32". They are kept for
different reasons and they cost the same, the backup price of 0.095 a GiB-month beyond the allowance.
The first snapshot of a volume is a full copy and later ones store only the blocks that changed, so a
daily snapshot of a database that changes little costs little.

## Taken, kept, restored

Lesson 6's instance once more, in an empty moto, and a snapshot before the release of Quitanda's new
order schema:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query DBInstance.DBInstanceStatus
"available"
ana@laptop:~/aws$ aws rds describe-db-snapshots --db-instance-identifier quitanda-orders --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotType]' --output text
rds:quitanda-orders-2026-10-16-16-08	automated
ana@laptop:~/aws$ aws rds create-db-snapshot --db-instance-identifier quitanda-orders --db-snapshot-identifier quitanda-orders-before-v2 --query 'DBSnapshot.[DBSnapshotIdentifier,SnapshotType,Status]' --output text
quitanda-orders-before-v2	manual	available
```

**The automated snapshot was already there**, named by RDS after the instance and the minute, and the
manual one sits beside it with a name a person chose. The difference shows when the instance is deleted:

```
ana@laptop:~/aws$ aws rds delete-db-instance --db-instance-identifier quitanda-orders --skip-final-snapshot --query DBInstance.DBInstanceStatus
"deleting"
ana@laptop:~/aws$ aws rds describe-db-snapshots --query 'DBSnapshots[].[DBSnapshotIdentifier,SnapshotType]' --output text
quitanda-orders-before-v2	manual
```

**The automated one went with the instance; the manual one stayed.** That is AWS's documented behaviour
too: deleting an instance deletes its automated backups unless you ask to keep them, and never touches
its manual snapshots. Restoring is the same shape as a point-in-time restore, a new instance with a new
endpoint:

```
ana@laptop:~/aws$ aws rds restore-db-instance-from-db-snapshot --db-instance-identifier quitanda-orders-v1 --db-snapshot-identifier quitanda-orders-before-v2 --db-instance-class db.m7g.large --query 'DBInstance.[DBInstanceStatus,Endpoint.Address]' --output text
available	quitanda-orders-v1.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
```

**On AWS, `delete-db-instance` refuses to run until you either name a final snapshot with
`--final-db-snapshot-identifier` or say `--skip-final-snapshot` out loud**, as the deletion above did.
moto does not insist, and deleting the restored copy the way somebody tidying up might shows it:

```
ana@laptop:~/aws$ aws rds delete-db-instance --db-instance-identifier quitanda-orders-v1 --query DBInstance.DBInstanceStatus
"deleting"
```

**On AWS that command is an error; in moto it deleted the instance with no snapshot of it.** So the habit
has to come from you: name a final snapshot every time, unless the database is one you would be glad to
lose.

## The two failure modes

**Snapshots kept forever.** Nothing expires a manual snapshot, so a team that takes one before every
release and deletes none has, two years later, a few hundred of them, each billed every month. A tag
saying why and until when, and somebody who reads the tags, is cheaper than a mystery line on the bill.

**Snapshots never restored.** A snapshot that has never been restored is a hope rather than a backup.
Restoring one into a new instance, running a few queries against it and deleting the instance is an
afternoon's work and costs a few hours of an instance; it is the only test that proves the snapshot holds
what everybody assumes it holds. moto cannot run that test, because it holds no data, and that is the
right note to end this lesson's evidence on: every restore here produced a status and an address, and
none of them produced a row.
