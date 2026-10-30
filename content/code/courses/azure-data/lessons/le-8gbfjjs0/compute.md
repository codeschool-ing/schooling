---
title: Compute: four kinds, and the one left running
version: 1
---

**Databricks offers four kinds of compute, and choosing among them is most of what a team decides
about its bill.** All four run Spark, or Databricks' SQL engine, against the same tables; they differ
in who uses them, how long they live and how they are billed. This section is taught from Databricks'
and Microsoft's documentation and was not run.

## All-purpose clusters

**An all-purpose cluster is the one people work on**: notebooks are attached to it, several people
can share it, and it runs until somebody stops it or it stops itself. You choose the machines for the
driver and the workers, the Databricks Runtime version, which fixes Spark's version and the libraries
around it, and whether the number of workers scales between a minimum and a maximum with the load.

**Its most important setting is auto termination**: the number of idle minutes after which the
cluster stops by itself. An all-purpose cluster with auto termination switched off is the most
expensive mistake on the platform, a set of machines billed every hour of every night because
somebody opened a notebook on Friday and went home.

## Job clusters

**A job cluster is created for one run of a job and terminated when the run ends.** Nobody attaches a
notebook to it; the job's tasks run on it and it disappears. Its DBUs are billed at the jobs rate,
which Databricks prices lower than the all-purpose rate for the same machines. **The nightly job
belongs on a job cluster**: Quitanda's cleaning notebook from lesson 20, run at three in the morning
by a Databricks job or by lesson 19's pipeline, on a cluster that exists for the half hour it needs.

## SQL warehouses

**A SQL warehouse is compute for SQL alone**, for analysts and for BI tools such as Power BI that
send SQL. It comes as classic, pro or serverless, and it scales by adding clusters when queries queue,
then shrinking when they stop. A warehouse also stops itself after idle minutes, and for a serverless
one Databricks keeps the machines warm, so it starts in seconds rather than minutes. It is the
Databricks counterpart of lesson 16's SQL pools and lesson 17's warehouse.

## Serverless compute

**Serverless compute for notebooks and jobs runs in Databricks' account, in the serverless compute
plane**, starts in seconds, and is billed in DBUs alone, with no virtual machine of yours behind it.
You give up the choice of machines and runtime versions and some of the network arrangements of the
previous section, and you stop paying for start-up minutes and idle ones. For a team that runs a few
short jobs a night, that trade is usually good; for one that runs large clusters all day, the classic
compute it controls can cost less.

## Two ways to start faster

**Pools keep machines ready.** A pool holds a number of idle virtual machines; a cluster that takes
its machines from a pool starts without waiting for Azure to create them. Databricks' documentation
says idle machines in a pool are not billed in DBUs, but Azure still bills them as virtual machines,
so a pool trades a little money for a lot of start-up time.

**Spot machines cost less and can be taken back.** Workers can be Azure Spot virtual machines, sold
cheaply from spare capacity and evicted when Azure needs it; Spark reruns the lost tasks on the
remaining workers. A job that must finish by six in the morning keeps its driver on an ordinary
machine and uses Spot for workers it can lose.
