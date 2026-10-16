---
title: Multi-AZ, a standby you cannot read
version: 1
---

**A Multi-AZ instance is two instances in two zones, one of which you never see.** The primary takes
every read and every write. The standby, in another zone, receives every write synchronously: a
transaction is committed only when it is on both volumes. If the primary fails, RDS points the
instance's address at the standby, and the application reconnects to the same name and finds the same
data. The standby is not a replica you can query, and it does not make anything faster. It is
insurance, and it costs what the instance costs.

**The wrong idea is that Multi-AZ is for scale.** It is not: the standby takes no connections, so a
database that is slow on one instance is exactly as slow on a Multi-AZ one, and slightly slower to
commit, because every commit now waits for a second zone to answer. What it is for is the day a zone
loses power, a host fails, or RDS patches the operating system. AWS documents that it fails over
automatically in those cases and that a failover typically completes in 60 to 120 seconds. That timing
is AWS's, not this lab's; nothing in moto fails over, as the second half of this section shows.

## What happens during a failover

On AWS, in the order the documentation gives it, the primary stops answering, or RDS decides to move.
The standby, which already has every committed transaction, is promoted. The DNS name of the instance,
`quitanda-orders.….rds.amazonaws.com`, is changed to point at the standby's address, and a new standby
is built in the zone the old primary was in. **The address does not change. What is behind it does.**

So the work on the application's side is to reconnect. Every connection open to the old primary breaks,
transactions in flight are rolled back, and the client has to open new connections to the same name.
A driver that retries is fine. An application that resolved the name once at start-up and cached the
address forever keeps knocking at a machine that is gone. That is why AWS recommends a DNS cache of
under a minute for clients of RDS, and why the Java runtime's default, which can cache forever, is
the usual culprit.

## In moto

moto is running in its own terminal and the four lines of lesson 1's "Your lab, in brief" are typed in
this one. The instance is lesson 6's, without the network around it, which this lesson does not
need, and with one flag added:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-orders --engine postgres --engine-version 16 --db-instance-class db.m7g.large --storage-type gp3 --allocated-storage 100 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --multi-az --query 'DBInstance.[DBInstanceStatus,MultiAZ,AvailabilityZone,SecondaryAvailabilityZone]' --output text
available	True	sa-east-1a	None
```

**`MultiAZ` is `True`, and `SecondaryAvailabilityZone` is `None`.** On AWS that field names the
standby's zone, `sa-east-1b` or `sa-east-1c`, because there is a standby and it is somewhere. moto
records the flag and builds nothing. Forcing a failover, which on AWS is how you rehearse one, shows
the same thing from the other side:

```
ana@laptop:~/aws$ aws rds reboot-db-instance --db-instance-identifier quitanda-orders --force-failover --query 'DBInstance.[DBInstanceStatus,AvailabilityZone]' --output text
available	sa-east-1a
ana@laptop:~/aws$ aws rds describe-events --source-type db-instance --source-identifier quitanda-orders --query 'Events[].Message'
[
    "DB instance created",
    "Backing up DB instance",
    "Finished DB instance backup"
]
```

**The reboot was accepted, the zone did not move, and the instance's events say nothing happened.** On
AWS, a reboot with failover moves the primary to the standby's zone, so the second field would read
the other zone afterwards, and the instance's events would record the failover starting and finishing.
Rehearsing it on a real account before the day it is needed is the only way to learn how long *your*
application takes to reconnect, which is the number that matters, and it is a number moto cannot
produce.

## What it costs

The price sheet's RDS block has both lines, because a Multi-AZ instance is priced as a deployment of its
own:

```
ana@laptop:~/aws$ python3 prices.py rds
AWS public price list, sa-east-1, USD, excluding tax

RDS, USD per hour
  PostgreSQL, db.m7g.large, Single-AZ                   0.22100  hour
  MySQL, db.m7g.large, Single-AZ                        0.22100  hour
  MariaDB, db.m7g.large, Single-AZ                      0.22100  hour
  PostgreSQL, db.m7g.large, Multi-AZ                    0.44200  hour
  PostgreSQL, db.t4g.micro, Single-AZ                   0.03400  hour
  SQL Server Standard, db.m6i.large, licence in         1.08700  hour

RDS storage and backup, USD per GB-month
  gp3, Single-AZ                                        0.21900  GB-month
  gp3, Multi-AZ                                         0.43800  GB-month
  backup beyond the free allowance                      0.09500  GB-month
```

**Everything doubles.** The instance is 0.442 an hour against 0.221, and the storage 0.438 a GiB-month
against 0.219, because there is a second machine and a second volume. For Quitanda's `db.m7g.large` with
100 GiB, lesson 6's arithmetic gives 366.46 a month against 183.23. The difference is 183.23 a month,
or 2,198.76 a year, and whether it is worth paying is a question about the shop rather than the
database: what does an hour without orders on a Friday evening cost Quitanda?
