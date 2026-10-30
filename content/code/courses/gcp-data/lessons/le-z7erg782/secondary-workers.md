---
title: Secondary workers, Spot, autoscaling and what runs at boot
version: 1
---

**A secondary worker is the one role a cluster can lose without losing anything but time**, and
that is why it is the role Dataproc lets you fill with cheaper machines. The previous section ordered
the roles by what their loss costs; this one puts prices behind that order, makes the cluster grow
and shrink on its own, and installs what a job needs on every machine as it boots. None of it was
run against Google, because there is no Dataproc here. What was run is the command line's own
description of the flags, which needs no network:

```
ana@laptop:~/gcp$ gcloud dataproc clusters create --help | grep -A2 -- '--secondary-worker-type=TYPE; default'
          --secondary-worker-type=TYPE; default="preemptible"]
        [--stop-expiration-time=STOP_EXPIRATION_TIME
          | --stop-max-age=STOP_MAX_AGE]
--
         --secondary-worker-type=TYPE; default="preemptible"
            The type of the secondary worker group. TYPE must be one of:
            preemptible, non-preemptible, spot.
```

**Three types, and the default is the one Google can take back.** The first match is the synopsis,
where the flag sits among its neighbours; the second is the flag's own entry. A secondary group
created without `--secondary-worker-type` is preemptible, so a cluster that asks for secondary
workers gets reclaimable machines unless it says otherwise.

## Preemptible, Spot and non-preemptible

**Preemptible and Spot VMs are Compute Engine's spare capacity, sold below the standard price and
taken back when Google needs it**, with about thirty seconds of warning. The two differ in one way
that matters to a cluster: a preemptible VM is stopped after at most 24 hours whatever happens, and
a Spot VM has no such limit, so a long-running cluster with Spot secondaries keeps them until the
capacity is wanted elsewhere. Spot prices are variable, the Compute Engine pricing page says, and
can change up to once a day, which is why this lesson's price program has no line for them.

**Non-preemptible secondaries are standard VMs that still hold no HDFS.** They cost what a primary
worker costs, and they are for a cluster that wants to grow and shrink quickly: a secondary can be
added or removed in the time a machine takes to boot or stop, because no blocks have to move first.

The order of the roles is the rule. **The secondary workers may be Spot, because losing one costs
time.** The primary workers should be standard VMs, because losing one costs HDFS blocks, and the
master always should be, because losing it ends the cluster. Here is the cluster of the previous
section with four Spot secondaries added. **It was not run here.**

```sh
gcloud dataproc clusters create quitanda-spark \
  --region=southamerica-east1 \
  --image-version=2.2-debian12 \
  --master-machine-type=n2-standard-4 --master-boot-disk-size=100GB \
  --num-workers=2 --worker-machine-type=n2-standard-4 --worker-boot-disk-size=100GB \
  --num-secondary-workers=4 --secondary-worker-type=spot
```

On Google Cloud a reclaimed secondary is recreated when capacity returns, and YARN gives the tasks it
was running to the machines that are left. **The job carries on, slower, and finishes.** What it
cannot survive is a cluster where most of the work sits on machines that may all go at once: if
Spot capacity in the zone disappears, a cluster of two primaries and forty secondaries becomes a
cluster of two, and a two-hour job becomes a much longer one. A secondary group sized as a share of
the work, rather than as most of it, keeps the worst case bounded.

## Autoscaling: a policy the cluster follows

**An autoscaling policy is a separate resource that a cluster points at**, and it decides how many
workers the cluster should have from what YARN reports: memory that pending work is asking for, and
memory that nobody is using. It is written as a file. Save this as `autoscaling.yaml`:

`autoscaling.yaml`:

```yaml
workerConfig:
  minInstances: 2
  maxInstances: 2
secondaryWorkerConfig:
  minInstances: 0
  maxInstances: 20
basicAlgorithm:
  cooldownPeriod: 2m
  yarnConfig:
    scaleUpFactor: 1.0
    scaleDownFactor: 1.0
    gracefulDecommissionTimeout: 1h
```

**The primaries are fixed at two and only the secondaries move**, between none and twenty. That is
the usual shape: the machines that hold HDFS stay put, and the ones that only add processors come
and go. `cooldownPeriod` is how long the policy waits between two decisions, so that a cluster does
not grow and shrink on every passing task. `scaleUpFactor` and `scaleDownFactor` say how much of the
gap to close in one decision, here all of it. `gracefulDecommissionTimeout` is how long a worker
being removed may keep running the tasks it already has before it is taken away anyway, so that a
shrinking cluster finishes work rather than abandoning it.

Importing the policy and pointing a cluster at it are two commands. **Neither was run here.**

```sh
gcloud dataproc autoscaling-policies import quitanda-nightly \
  --source=autoscaling.yaml --region=southamerica-east1
gcloud dataproc clusters update quitanda-spark \
  --autoscaling-policy=quitanda-nightly --region=southamerica-east1
```

**Autoscaling is for a cluster whose work changes size**: one shared by several jobs, or a
long-running cluster with a busy night and a quiet day. A cluster created for one job of known size
is better sized at creation, because every scaling decision waits for YARN to report a shortage
first, and a cluster that starts small and grows has spent its first minutes short.

## Initialization actions: what every machine runs as it boots

**An initialization action is a script in Cloud Storage that Dataproc runs on every machine of a
new cluster**, as root, after the image's own software is set up and before the cluster is ready
for jobs. It is how a library, an agent or a configuration file reaches the machines, which is one
of the things Dataflow, with no machines of yours to touch, does differently: there the library goes
into the pipeline's own container or its requirements. Save this one as `install-libs.sh`:

`install-libs.sh`:

```sh
#!/bin/bash
set -euo pipefail
ROLE=$(/usr/share/google/get_metadata_value attributes/dataproc-role)
python3 -m pip install -q holidays==0.105
if [[ "$ROLE" == 'Master' ]]; then
  echo 'master only: nothing else to do for this cluster'
fi
```

The library is the one the nightly job would need to know which days are Brazilian public holidays,
and it goes on every machine because any executor may run the code that calls it. **The role check
is how one script does different things on different machines**: Dataproc writes each machine's role
into its metadata, and a script that should run once per cluster, such as one that creates a
database, runs only on the master.

The script is uploaded to a bucket, and the cluster is created naming it. **Not run here:**

```sh
gcloud storage cp install-libs.sh gs://quitanda-raw-prod/jobs/install-libs.sh
gcloud dataproc clusters create quitanda-spark --region=southamerica-east1 \
  --initialization-actions=gs://quitanda-raw-prod/jobs/install-libs.sh \
  --initialization-action-timeout=10m
```

**A failing initialization action fails the cluster**, and that is the useful behaviour: a cluster
missing the library would accept the job and fail it at three in the morning instead of at
creation. Ten minutes is the default timeout, and every minute of it is billed on every machine,
because the machines are running while the script does. A script that downloads and compiles for
twenty minutes is a reason to build a custom image with the library already on it, so that the
cost is paid once rather than on every cluster.
