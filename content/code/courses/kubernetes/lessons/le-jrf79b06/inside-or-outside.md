---
title: Inside the cluster or beside it
version: 1
---

Everything above worked, and it is still a small part of running a database. **Replication, failover,
point-in-time recovery, upgrades between major versions, tuning and monitoring** are the rest, and a
StatefulSet does none of them. There are three ways to get them.

| | managed database (RDS, Cloud SQL, Azure Database) | operator in the cluster (CloudNativePG, for example) | StatefulSet by hand |
|---|---|---|---|
| who runs failover and backups | the provider | the operator, configured by you | you |
| where the data lives | the provider's service, beside the cluster | volumes in the cluster | volumes in the cluster |
| cost | a premium over the machines | the machines, and your time | the machines, and more of your time |
| moves with the cluster | no | yes | yes |
| fits | most teams in a cloud | teams that want one platform everywhere | labs, tests, small internal tools |

**For most teams running in a cloud, the database belongs outside the cluster**, in the provider's
managed service: backups, replicas and failover come as settings, and the cluster's applications
reach it through an ordinary address, often wrapped in a Service of type `ExternalName` so that pods
use a name that does not change. The cluster can then be rebuilt from its manifests at any time,
because nothing in it is irreplaceable.

An operator, lesson 44's subject, is the strong case for staying inside: a program that runs in the
cluster and knows how to operate one particular database, turning "three replicas with daily backups
to this bucket" into StatefulSets, Services, Jobs and failover decisions. It suits teams that run on
their own hardware, or in several clouds, and want one way of doing it.

The by-hand StatefulSet of this lesson is the right choice for exactly what it was used for: learning,
tests, and data nobody would miss. Whatever runs the database, the questions of the previous section
do not change. **A backup that has never been restored is a hope, not a backup.**
