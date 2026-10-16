---
title: Aurora Serverless v2, capacity that follows the load
version: 1
---

**Aurora Serverless v2 is an Aurora instance whose size moves while it runs.** Instead of a class such as
`db.r7g.large`, the instance is `db.serverless`, and the cluster says the smallest and the largest it may
be, in **Aurora capacity units**. AWS documents an ACU as about 2 GiB of memory with the CPU and network
that go with it. Aurora watches the load and moves the instance between the two limits in steps of half
an ACU, within seconds, without restarting it or dropping a connection. It is billed per ACU-hour for the
capacity it actually had.

**The wrong idea is that serverless means cheap.** It means billed by the size it had each second, which
is cheap when the database is quiet most of the time and expensive when it is busy all of it. The price
sheet's Aurora block says how expensive:

```
ana@laptop:~/aws$ python3 prices.py aurora
AWS public price list, sa-east-1, USD, excluding tax

Aurora PostgreSQL, USD
  db.r7g.large, Standard, per hour                      0.43884  hour
  db.r7g.large, I/O-Optimized, per hour                 0.57081  hour
  storage, Standard                                     0.19000  GB-month
  storage, I/O-Optimized                                0.42800  GB-month
  I/O, Standard, per million requests                   0.28000  million
  Serverless v2, per ACU-hour                           0.25000  ACU-hour
```

## The arithmetic at both ends

**At a constant load, serverless costs about four and a half times as much.** A `db.r7g.large` has 2 vCPU
and 16 GiB of memory; 16 GiB is 8 ACUs, and 8 × 0.25 = 2.00 an hour against 0.43884 for the provisioned
instance, 4.6 times. A database that needs 16 GiB all month pays 8 × 0.25 × 730 = 1,460.00 serverless
against 0.43884 × 730 = 320.35 provisioned.

**When the load is mostly absent, it costs a fraction.** Quitanda's development cluster is used by the
team ten hours a day, twenty-two working days a month, 220 hours, and nobody touches it the other 510. At
8 ACUs while in use, that is 8 × 0.25 × 220 = 440.00 a month, and what the idle hours cost depends on the
minimum:

| minimum | the 510 idle hours | compute for the month |
|---|---|---|
| 0.5 ACU | 0.5 × 0.25 × 510 = 63.75 | 503.75 |
| 0, pausing after 15 minutes | nothing for compute | 440.00 |

Both are more than the provisioned 320.35, because ten hours a day at full size is already a lot of
hours. The line where serverless wins at 8 ACUs is 320.35 / 2.00 = 160 hours a month at full size, about
seven and a half hours a working day with nothing outside them. A cluster that is busy two hours a day is
far below it; one that is busy all evening is not.

**A minimum of 0 is the newer option**: the instance pauses after a period with no connections, compute
billing stops, and the first connection afterwards wakes it, which AWS documents as taking seconds rather
than milliseconds. Storage is billed either way. That pause is right for a development or test cluster and
wrong for the shop, where the first customer of the morning would wait for it. The limits AWS documents
are a minimum of 0 or 0.5 and a maximum of 256 ACUs on recent engine versions, and the pause between 5
minutes and 24 hours of idleness.

## In moto

A development cluster that can pause, and one serverless instance in it:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-dev --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --serverless-v2-scaling-configuration MinCapacity=0,MaxCapacity=8,SecondsUntilAutoPause=900 --query 'DBCluster.ServerlessV2ScalingConfiguration'
{
    "MinCapacity": 0.0,
    "MaxCapacity": 8.0,
    "SecondsUntilAutoPause": 900
}
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-dev-1 --db-cluster-identifier quitanda-dev --engine aurora-postgresql --db-instance-class db.serverless --query 'DBInstance.[DBInstanceClass,DBInstanceStatus]' --output text
db.serverless	available
```

**The scaling configuration is stored and the instance is `available`**, and it will never scale, because
there is no load and no engine to measure it on. moto keeps the numbers it was given, and it keeps them
whatever they are:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-backwards --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --serverless-v2-scaling-configuration MinCapacity=300,MaxCapacity=2 --query 'DBCluster.ServerlessV2ScalingConfiguration'
{
    "MinCapacity": 300.0,
    "MaxCapacity": 2.0
}
```

**A minimum of 300 and a maximum of 2 was accepted**, a range that is backwards and whose minimum is above
anything AWS allows. On AWS the request is refused. As with every number in these three lessons, moto
stores and does not judge; the judgement is the documentation's, and on a real account it is the error
message's.

**A cluster can mix the two kinds.** A provisioned writer sized for the steady load of the shop and a
serverless replica that grows when the morning reports run is a common shape. The promotion tier matters
here as well as in a failover: AWS documents that a serverless reader in tier 0 or 1 keeps at least the
writer's capacity, so that it is ready to take over, while one in tiers 2 to 15 scales on its own load.
