---
title: Replicas, endpoints and a failover that moves no data
version: 1
---

**An Aurora replica is a second engine reading the same volume, so it is never missing data.** It is
not a copy being kept in step, as lesson 7's read replicas are. It has no storage of its own; it reads the
protection groups the writer writes, and the writer's log stream reaches it only to refresh the pages it
holds in memory. AWS documents the lag of an Aurora replica as usually well under 100 milliseconds,
against the seconds a busy RDS replica can fall behind. The figure is AWS's, not this lab's.

That changes what a failover is. **Promoting an Aurora replica copies nothing and replays nothing**: the
data is already where the replica can read it, so the replica only has to start accepting writes, and the
cluster endpoint is moved to it. AWS documents service as typically back within about thirty seconds when
there is a replica to fail over to. A cluster with no replica has to start a new instance against the
volume, which AWS documents as typically under ten minutes, and that difference is the strongest reason
to run one replica even when nothing reads from it.

## Failing over in moto

The cluster from the previous section, with its writer in `sa-east-1a` and its replica in `sa-east-1b`:

```
ana@laptop:~/aws$ aws rds failover-db-cluster --db-cluster-identifier quitanda-aurora --target-db-instance-identifier quitanda-aurora-2 --query 'DBCluster.DBClusterMembers[].[DBInstanceIdentifier,IsClusterWriter]' --output text
quitanda-aurora-1	False
quitanda-aurora-2	True
```

**The writer moved, which is the first failover in this course that moto shows at all.** It swapped the
flag between the two members. On AWS, the same command is how a failover is rehearsed: the cluster
endpoint moves to `quitanda-aurora-2`, connections to the old writer break, and the application reconnects
to the same name, exactly as with lesson 7's Multi-AZ instance. moto moves the flag and nothing else,
because there is nothing else; how long *your* application takes to notice and reconnect is still a number
only a real account can give you.

## Four kinds of endpoint

| endpoint | points at | for |
|---|---|---|
| cluster, `quitanda-aurora.cluster-…` | the writer, whichever instance that is now | writes, and reads that must see them |
| reader, `quitanda-aurora.cluster-ro-…` | the replicas, connections spread across them | reads that can be a few milliseconds old |
| custom | a list of instances you choose | a group of replicas kept apart for one job |
| instance, `quitanda-aurora-1.…` | one instance, always | diagnosing that instance, never an application |

**A custom endpoint is how Quitanda keeps its analysts off the replica the shop reads from.** Two replicas
serve the website through the reader endpoint; a third, larger one is named in a custom endpoint the
reporting tool uses, so a heavy report slows nobody's checkout. moto has not written that action:

```
ana@laptop:~/aws$ aws rds create-db-cluster-endpoint --db-cluster-identifier quitanda-aurora --db-cluster-endpoint-identifier quitanda-reports --endpoint-type READER --static-members quitanda-aurora-1

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

moto's terminal names the missing piece, `NotImplementedError: The create_db_cluster_endpoint action has
not been implemented`. On AWS the command returns the endpoint's address and the members it serves; it was
not run.

## Fifteen, and no more

**A cluster takes up to fifteen replicas**, as AWS documents it, sixteen instances with the writer. moto
does not count:

```
ana@laptop:~/aws$ for i in $(seq 3 17); do aws rds create-db-instance --db-instance-identifier quitanda-aurora-$i --db-cluster-identifier quitanda-aurora --engine aurora-postgresql --db-instance-class db.r7g.large --query DBInstance.DBInstanceStatus --output text; done | sort | uniq -c
     15 available
ana@laptop:~/aws$ aws rds describe-db-clusters --db-cluster-identifier quitanda-aurora --query 'length(DBClusters[0].DBClusterMembers)'
17
```

**Seventeen members, fifteen of them just created, each answered `available`.** On AWS the sixteenth
instance would be the last one accepted and the seventeenth refused. A replica is billed as an instance of
its class, and none of them adds storage, because there is one volume.

## Across regions: Global Database

**An Aurora Global Database is one primary cluster and secondary clusters in other regions**, and the
replication is done by the storage layer rather than by the engine: the volume ships its changes to the
other region's volume, and AWS documents the lag as typically under a second. The secondary clusters
answer reads near the people who make them, and one can be promoted to take writes if the primary region
is lost, which is the disaster lesson 7's cross-region replica answered more slowly. The transfer between
regions is billed, as lesson 7's transfer block priced it, and the secondary region's instances and
storage are billed at that region's prices. None of it was run here, and the replication it stands for
is exactly the part moto has no model of.
