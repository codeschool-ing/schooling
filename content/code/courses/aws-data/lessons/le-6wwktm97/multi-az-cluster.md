---
title: The Multi-AZ DB cluster, two standbys you can read
version: 1
---

**A Multi-AZ DB cluster is three instances in three zones, and two of them answer queries.** It is the
newer of RDS's two Multi-AZ deployments, for PostgreSQL and MySQL, and it fixes the complaint people
have about the first: a standby that costs a full instance and does nothing until the day it is
needed. In the cluster, one **writer** takes the writes and two **readers** in the other two zones
receive them, and the readers serve reads while they wait.

| | Multi-AZ instance | Multi-AZ DB cluster |
|---|---|---|
| instances | 2: primary and standby | 3: one writer, two readers |
| zones | 2 | 3 |
| the copies answer reads | no | yes, through a reader endpoint |
| replication | synchronous to the standby | semi-synchronous: a commit waits for one of the two readers |
| failover, as AWS documents it | typically 60 to 120 seconds | typically under 35 seconds |
| engines | all of RDS's | PostgreSQL and MySQL |

**Semi-synchronous is the trade.** A commit returns when the writer and at least one reader have the
transaction, so the commit does not wait for the slower of the two, and a reader that falls behind does
not slow every write. The reader that acknowledged has every committed transaction, which is what makes
it safe to fail over to. The other may be a moment behind, so a query sent to the reader endpoint can
see data slightly older than the writer's, the same caveat as the read replicas of the next section,
only measured in a much smaller unit.

**The cluster has two addresses**, a writer endpoint and a reader endpoint. The writer endpoint always
points at whichever instance is the writer now, so a failover is again a DNS change behind a name that
does not move. The reader endpoint spreads connections across the readers. An application that wants
both splits its traffic: writes and reads that must see their own writes go to the first, reports
and dashboards to the second.

## In moto

A Multi-AZ DB cluster is made with `create-db-cluster`, the command lesson 8 uses for Aurora, and an
engine that is not Aurora. Its three instances take a class from the list the cluster supports, such
as `db.m6gd.large`, and its storage is `io1`, `io2` or `gp3`, per AWS's documentation:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-orders --engine postgres --engine-version 16 --db-cluster-instance-class db.m6gd.large --storage-type io2 --allocated-storage 100 --iops 3000 --master-username quitanda --manage-master-user-password --query 'DBCluster.[Status,MultiAZ,Endpoint,ReaderEndpoint]' --output text
creating	False	quitanda-orders.cluster-peijid1n1e4k.sa-east-1.rds.amazonaws.com	quitanda-orders.cluster-ro-peijid1n1e4k.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-orders --query 'DBClusters[0].[Status,MultiAZ,length(DBClusterMembers)]' --output text
available	False	0
```

**moto made a cluster with two endpoints and no instances at all**, and says it is not Multi-AZ. On AWS
this command creates three instances in three zones and reports `MultiAZ` as `True`; `length` of the
members would be 3, and each would be listed with whether it is the writer. moto knows the command, keeps
the record, and invents both addresses in the right shape, and that is as far as it goes. Nothing about
the replication, the readers or the failover can be practised here, and this section is taught from
AWS's documentation, as the table says.

## Which one, and what it costs

**For a new PostgreSQL or MySQL database that needs a standby, the cluster is usually the better buy**:
it fails over faster, and the copies do work. The Multi-AZ instance remains the only choice for Oracle,
SQL Server, MariaDB and Db2, and for a version or an instance class the cluster does not offer.

The cluster is billed as three instances of its class plus its storage and its provisioned IOPS. The
price sheet in this course prints neither the `db.m6gd` classes nor `io2` storage, so this section quotes
no total. The shape of the bill is three machines where the Multi-AZ instance is two, against two
machines that answer queries where the Multi-AZ instance has one.
