---
title: Choosing where to run
version: 1
---

**Four ways to run the same Spark job, and the course has now run three of them.**

| | standalone | YARN | Kubernetes | managed |
|---|---|---|---|---|
| who runs the cluster | you | you, or the platform team | the platform team | the provider |
| what else shares it | nothing | other Hadoop jobs, by queue | every other service, by namespace | other jobs of your account |
| a Python driver in cluster mode | no | yes | yes | yes |
| executors added and removed while a job runs | with care | yes | yes | yes |
| where the data usually lives | the same machines | HDFS on the same machines | an object store | an object store |
| when it is the right answer | one team, a few machines, learning | a Hadoop estate that already exists | an organisation that already runs Kubernetes | most new work in the cloud |

**The choice is rarely made for Spark's sake.** An organisation that already runs everything on
Kubernetes adds Spark to it; one with ten years of HDFS and YARN keeps running Spark there; a new team
in the cloud starts on a managed service and never meets a NodeManager. What Spark needs from any of
them is the same: somewhere to start a driver, somewhere to start executors, and a way to reach the
data.

**What matters more than the manager is where the data is.** Every option but standalone and YARN
reads from an object store, over the network, which is lesson 3's lost locality. Lessons 6 and 10 are
how that is paid back: read fewer columns, skip row groups and partitions, and keep files large. A
job that reads everything is slower on any of them.
