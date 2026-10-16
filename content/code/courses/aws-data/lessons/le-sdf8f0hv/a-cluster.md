---
title: A cluster and its instances, in moto
version: 1
---

**An Aurora database is a cluster first and instances second.** The cluster owns the volume, the
backups, the engine version, the master user and the endpoints. Instances are the machines that run the
engine against that volume, and the cluster can exist with none of them, holding data nobody can query.
So making one is two kinds of command: one `create-db-cluster`, then one `create-db-instance` per machine,
each naming the cluster. moto is running in its own terminal and the four lines of lesson 1's "Your lab,
in brief" are typed in this one.

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --backup-retention-period 7 --query 'DBCluster.[Status,Endpoint,ReaderEndpoint]'
[
    "creating",
    "quitanda-aurora.cluster-icnvtdkhgjyf.sa-east-1.rds.amazonaws.com",
    "quitanda-aurora.cluster-ro-icnvtdkhgjyf.sa-east-1.rds.amazonaws.com"
]
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].Status'
"available"
```

**Two addresses before there is a single machine.** The first is the **cluster endpoint**, which always
points at the writer. The second, with `cluster-ro` in its name, is the **reader endpoint**, which spreads
connections across the replicas. No size was given and no storage type: an Aurora volume has no size to
choose, and it grows with the data. The status says `creating`, the first time in this course moto has
not answered `available` straight away; asked again a moment later, it is `available`. On AWS the
cluster takes minutes to get there, and it has nothing to run on even then.

Then the machines. One in each of two zones, so that losing a zone leaves one:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-aurora-1 --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --availability-zone sa-east-1a --query 'DBInstance.[DBInstanceStatus,AvailabilityZone,Endpoint.Address]' --output text
available	sa-east-1a	quitanda-aurora-1.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier quitanda-aurora-2 --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --availability-zone sa-east-1b --query 'DBInstance.[DBInstanceStatus,AvailabilityZone,Endpoint.Address]' --output text
available	sa-east-1b	quitanda-aurora-2.aaaaaaaaaa.sa-east-1.rds.amazonaws.com
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter,PromotionTier]' --output text
quitanda-aurora-1	True	1
quitanda-aurora-2	False	1
```

**The first instance into a cluster becomes the writer**, and every one after it a replica, because
Aurora has exactly one writer per cluster. Each instance also has an endpoint of its own, which is for
diagnosing that particular machine and not for an application, which should use the cluster's two. The
**promotion tier** decides which replica becomes the writer when the writer fails: lowest tier first, from
0 to 15, the largest instance breaking a tie. Both are at the default of 1 here.

## What moto says about the storage

```
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'DBClusters[0].[StorageType,AllocatedStorage]' --output text
gp2	1
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-aurora-1 --query 'DBInstances[0].[StorageType,AllocatedStorage]' --output text
aurora	1
```

**`gp2` for the cluster is wrong**, and it is the most instructive line in this lesson. gp2 is an EBS
volume type, the kind lesson 6's instance had, and an Aurora cluster has no EBS volume; there is no
storage type an Aurora cluster can report that is a disk. The instance's `aurora` is the right word, and
its allocated storage of 1 is a placeholder: on AWS, Aurora instances report storage as a property of the
cluster, which grows by itself. moto answers with fields borrowed from its model of an ordinary instance,
and they read as plausibly as the true ones.

The other storage configuration, I/O-Optimized, is a value of `--storage-type`, and moto cannot take it:

```
ana@laptop:~/aws$ aws rds create-db-cluster --db-cluster-identifier quitanda-aurora-io --engine aurora-postgresql --engine-version 16.4 --master-username quitanda --manage-master-user-password --storage-type aurora-iopt1

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**A 500 again**, and moto's terminal prints why: `KeyError: 'aurora-iopt1'`. moto looks the storage type up
in a table of default sizes for EBS volumes, the same model as above, and the Aurora values are not in it.
On AWS the command creates a cluster whose storage is billed the I/O-Optimized way; the last section of
this lesson is what that means for the bill, and it was not run.

**Read every Aurora transcript in this lesson the same way.** moto keeps the shape of a cluster: its
endpoints, its members, which one is the writer. Anything below the engine, which is the part of Aurora
that sets it apart, it does not model at all, and sometimes it fills the gap with an answer that belongs
to a different service.
