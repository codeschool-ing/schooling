---
title: A cluster of your own machines, with Spark already on them
version: 1
---

**Dataproc is not a service that runs Spark for you, the way Dataflow runs Beam.** A Dataproc
cluster is a set of Compute Engine virtual machines in your project, started from an image that
already has Hadoop, Spark and their neighbours installed and configured to find each other.
Dataflow, in lesson 21, hides its machines: you submit a pipeline, and the service decides how many
workers it gets and bills the time they ran. Dataproc hands you the machines. You choose their type and their count, and they exist from the minute they boot to the minute you
delete them. You pay for
every second of that twice, once to Compute Engine for the machine and once to Dataproc for the
management fee on its processors.

**The name is moving, and the commands are not.** Google's pricing page, read on 2026-10-30, calls
the product *Managed Service for Apache Spark (formerly Dataproc)*. The command line, the API and
the documentation's paths still say `dataproc`, and so does every command in this lesson, because
that is what you type.

That one difference from Dataflow explains most of this lesson. Because the machines are yours, you
can install any library on them, keep them running between jobs, choose a cheaper kind of machine,
and connect to one when something is wrong. Because the machines are yours, a cluster nobody
remembered to delete costs the same at four in the morning as at four in the afternoon.

## Three roles, and why they are different

**Every machine in a cluster has one of three roles, and the role decides what is lost when that
machine disappears.**

- the **master** coordinates. It runs YARN's ResourceManager, which hands out memory and processors
  to the jobs, and HDFS's NameNode, which knows where every block of the cluster's own file system
  lives. A standard cluster has one; a high-availability cluster has three, so that losing one is
  survivable;
- a **primary worker** works and stores. It runs a NodeManager, which executes the tasks YARN gives
  it, and a DataNode, which holds blocks of HDFS. A standard cluster has at least two;
- a **secondary worker** only works. It runs a NodeManager and holds no HDFS blocks. It is optional,
  a cluster may have none, and by default it is a machine Google may take back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A Dataproc cluster drawn as a dashed boundary holding three columns of machines. The master runs ResourceManager and NameNode; if it is lost the cluster ends, and it is a standard VM. Two primary workers each run DataNode and NodeManager; if one is lost, HDFS blocks go with it, and they are standard VMs. Two secondary workers run only NodeManager; if one is lost the cost is some time, and they are Spot or preemptible. Outside the cluster, an arrow labelled connector points to gs://quitanda-raw-prod, where the data lives.\" data-fig=\"l23-roles\"><defs><marker id=\"ah-l23-roles\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"480\" height=\"255\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one Dataproc cluster</text><rect x=\"40\" y=\"60\" width=\"135\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107.5\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">master</text><text x=\"107.5\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ResourceManager</text><text x=\"107.5\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NameNode</text><text x=\"107.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if lost: the cluster ends</text><text x=\"107.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">standard VM</text><rect x=\"195\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">primary worker</text><text x=\"262.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"195\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">primary worker</text><text x=\"262.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"262.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if lost: HDFS blocks</text><text x=\"262.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">standard VM</text><rect x=\"350\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">secondary</text><text x=\"417.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"350\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">secondary</text><text x=\"417.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"417.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if lost: some time</text><text x=\"417.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Spot or preemptible</text><rect x=\"555\" y=\"100\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">gs://quitanda-raw-prod</text><text x=\"630\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the data lives here</text><line x1=\"500\" y1=\"135\" x2=\"553\" y2=\"135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l23-roles)\"></line><text x=\"527\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">connector</text></svg>", "caption": "What a node runs decides what its loss costs, and what it costs decides which nodes may be the ones Google can take back."}
```

**The difference between a primary and a secondary worker is HDFS.** Take a secondary worker away
and the tasks it was running are given to another machine and run again: the job is slower, and
nothing is lost. Take a primary worker away and the blocks it held go with it. HDFS keeps copies of
each block on other primary workers, which is what lets a cluster survive one such loss, but
shrinking the primary group means moving those blocks first. A master that vanishes ends a standard
cluster. That ordering, from "costs some time" to "costs everything", decides which machines may be
the cheap ones Google can reclaim, and the next section uses it.

## Keep the data out of the cluster

**On Dataproc the data a job reads and writes lives in Cloud Storage, not in HDFS.** Every image
ships the **Cloud Storage connector**, which lets Spark and Hadoop read a `gs://` path as if it were
a file system, so the orders under `gs://quitanda-raw-prod/raw/orders/` are read where they lie and
the result is written to `quitanda-curated-prod`. HDFS on the primary workers is then scratch
space: shuffle files, intermediate results, anything the job can make again.

That is what makes a cluster disposable. A cluster whose only copy of something is in HDFS can
never be deleted, because deleting it deletes the data. A cluster that keeps everything in Cloud
Storage can be created for one night's job and deleted when the job ends, and the next night's
cluster finds everything where the last one left it. The rest of this lesson assumes the second
kind.

## What a cluster is made of, as a command

Here is a small cluster for Quitanda's nightly job, as it would be created in São Paulo. **It was
not run here**: no emulator answers for Dataproc, and on a real project this command starts billing
four machines the moment it returns.

```sh
gcloud dataproc clusters create quitanda-spark \
  --region=southamerica-east1 \
  --image-version=2.2-debian12 \
  --master-machine-type=n2-standard-4 --master-boot-disk-size=100GB \
  --num-workers=2 --worker-machine-type=n2-standard-4 --worker-boot-disk-size=100GB
```

**Each line is one decision.** The region is where the machines run, and it should be the region of
the buckets, so that reading the orders crosses no regional boundary and pays no transfer for it,
lesson 5's subject. The **image version** fixes the versions of everything on the machines: Debian,
Java, Hadoop, Spark, Hive and the rest. Two clusters on the same image run the same software, and
upgrading Spark is creating a cluster on a newer image, never upgrading one in place. The machine
type, `n2-standard-4`, is 4 vCPU and 16 GiB of memory, and the boot disk is sized explicitly
because the disk is billed by the gibibyte for as long as the machine exists.

**A cluster can also be smaller than this.** `--single-node` creates a master that is its own worker,
one machine in all, which is enough for development and for a job small enough that one machine
finishes it. It cannot have secondary workers and it cannot survive losing its one machine, which
are the two things the next section is about.
