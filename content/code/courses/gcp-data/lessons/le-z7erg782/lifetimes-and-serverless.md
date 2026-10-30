---
title: The cluster that lives for one night, and the one that is never there
version: 1
---

**A long-running cluster waits for work; an ephemeral cluster is created for its work and deleted
with it.** The machines and the software are the same, and the bill is not: the first is paid for
every hour of the month, the second for the hours of the job and the minutes it took to boot. And
Dataproc has a third shape with no cluster at all, **Serverless**, where you submit a
batch and Google finds the machines. This section takes the three in that order. No command in it
was run, apart from one more question put to the command line's own help.

## Long-running, and the timer that deletes it

**A cluster created with the command of the first section lives until somebody deletes it.** That
is right for a cluster people work on all day, a notebook attached to it or an analyst running
queries through Hive or Trino, and for a cluster that holds something slow to rebuild. It is wrong
for a cluster that ran one job at three in the morning and has been idle since four. The guard
against the second case is a timer set at creation, and the command line knows two of them:

```
ana@laptop:~/gcp$ gcloud dataproc clusters create --help | grep -E -- '^ +--(delete|stop)-max-idle'
     --delete-max-idle=DELETE_MAX_IDLE
     --stop-max-idle=STOP_MAX_IDLE
```

**`--delete-max-idle` deletes the cluster after it has run no job for that long**, and
`--stop-max-idle` stops it instead, which keeps its disks, and bills them, while the machines are
off. Their neighbours `--delete-max-age` and `--delete-expiration-time` delete it at an age or at a
moment whatever it is doing. On a long-running cluster, thirty minutes of idleness is a common
choice, and it is the difference between a forgotten cluster costing one evening and costing a
month:

```sh
gcloud dataproc clusters create quitanda-spark --region=southamerica-east1 \
  --num-workers=2 --worker-machine-type=n2-standard-4 \
  --delete-max-idle=30m
```

**Not run here**, like every `gcloud dataproc` command that needs Google on the other end.

## Ephemeral, as a workflow template

**A workflow template is a file that describes a cluster and the jobs to run on it.** Instantiating
it creates the cluster, runs the jobs in the order their dependencies give, and
deletes the cluster when the last one ends, whether it succeeded or not. It is Dataproc's own
answer to "a cluster for one night", with no scheduler in it: something else decides when to start
it, which is lesson 24's subject. Save the nightly job as `nightly.yaml`:

`nightly.yaml`:

```yaml
jobs:
- stepId: daily-orders
  pysparkJob:
    mainPythonFileUri: gs://quitanda-raw-prod/jobs/daily_orders.py
    args: ['--dt', '2026-10-29', '--src', 'gs://quitanda-raw-prod/raw',
           '--dst', 'gs://quitanda-curated-prod']
placement:
  managedCluster:
    clusterName: quitanda-nightly
    config:
      gceClusterConfig:
        zoneUri: southamerica-east1-a
      masterConfig:
        machineTypeUri: n2-standard-4
      workerConfig:
        numInstances: 2
        machineTypeUri: n2-standard-4
```

**`managedCluster` is the line that makes it ephemeral.** A template can name an existing cluster
by its labels instead, with `clusterSelector`, and then it creates and deletes nothing. The date is
written into the file here to keep it readable; a real template declares it as a parameter and is
given the day when it is instantiated. Starting it is one command, **not run here**:

```sh
gcloud dataproc workflow-templates instantiate-from-file \
  --file=nightly.yaml --region=southamerica-east1
```

**The bill of an ephemeral cluster is the job plus the boot.** The machines are billed from the
moment they are created, with a one-minute minimum and per-second billing after it, so the minutes
spent starting the image and running the initialization actions are paid on every night. The local
run of this lesson's job spent most of its seconds starting Spark; a cluster adds the machines'
own start on top, and nothing in this lab can put a number on that.

## Serverless: a batch, and no cluster

**Dataproc Serverless runs a Spark workload with no cluster for you to create or delete.** You
submit a *batch*, Google starts a driver and executors for it, runs it, and stops them, and you pay
for the resources it consumed, per second with a one-minute minimum. The same program, **not run
here**:

```sh
gcloud dataproc batches submit pyspark gs://quitanda-raw-prod/jobs/daily_orders.py \
  --region=southamerica-east1 --batch=daily-orders-2026-10-29 \
  -- --dt 2026-10-29 --src gs://quitanda-raw-prod/raw --dst gs://quitanda-curated-prod
```

**There is no machine type, no worker count and no image on that line.** A batch picks a runtime version, which fixes Spark the way an image does. Its size is set with
ordinary Spark properties such as `spark.executor.instances`, and by default, the pricing page
says, a batch uses one driver and two
executors of 4 vCPU and 16 GiB each, 12 DCUs in all. A **DCU**, a Data Compute Unit, is the unit
Serverless bills: 0.6 for each vCPU and 0.1 for each GiB of memory up to 8 GiB per vCPU, per hour.
After a batch ends, `gcloud dataproc batches describe` reports what it used as
`approximateUsage.milliDcuSeconds`, which is how its bill is checked.

**What Serverless takes away is what a cluster lets you do.** No initialization action runs on its
machines, so a library has to arrive in a custom container image or as a Python file shipped with
the batch. There is no HDFS and no YARN to tune, no notebook left attached between jobs, and no
Hive or Trino beside Spark. It also needs a subnet whose machines can reach Google's APIs without a
public address, the subnet setting called Private Google Access.

## Dataproc on GKE

**The third deployment runs Dataproc's Spark on a Google Kubernetes Engine cluster you already
have**, as pods in node pools Dataproc creates there. It is billed with the same management fee per
vCPU as a cluster on Compute Engine, plus the GKE machines themselves. Its case is an organisation
that already runs everything on Kubernetes and wants Spark to share the machines, the monitoring
and the people. For a team without one, it adds a Kubernetes cluster to operate in order to run
Spark.

## Which shape, for which work

| | you choose | you pay for | idle costs |
|---|---|---|---|
| long-running cluster | machine types, counts, Spot, image, init actions | VMs, disks and the fee, from creation to deletion | everything, until deleted or stopped |
| ephemeral cluster | the same, in a template | the same, for the job and the boot | nothing: it is gone |
| Serverless batch | a runtime and Spark properties | DCU-hours and shuffle storage the batch used | nothing |
| on GKE | the Kubernetes cluster and its node pools | the nodes, plus the fee on their vCPUs | the nodes you keep |

**An ephemeral cluster or a Serverless batch is the default for scheduled batch work**, and
Quitanda's nightly job is the example. Choose the cluster when the job needs the machine itself, an
initialization action, a component beyond Spark, or Spot secondaries for a large job; choose
Serverless when it needs none of that and nobody wants a cluster definition to maintain.
**Long-running earns its place when people work on the cluster** or when work arrives all day, and
then with `--delete-max-idle` set, so that the day it stops being used is the day it stops being
paid for.
