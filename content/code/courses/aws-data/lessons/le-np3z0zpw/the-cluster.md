---
title: A cluster of your own machines, with Spark already on them
version: 1
---

**EMR is not a service that runs Spark for you, the way Glue is.** It is a set of EC2 machines in
your account, started from an image that already has Hadoop, Spark and their neighbours installed
and configured to find each other. Glue, in lesson 17, hides the machines: you ask for a number of
workers and pay for the time they ran. EMR gives you the machines. You choose their type and their count, they are yours from the minute they
boot to the minute you stop them, and you pay for every
one of those minutes twice, once to EC2 for the machine and once to EMR for the software on it.

That one difference explains most of this lesson. Because the machines are yours, you can install
any library on them, keep them running between jobs, pick a cheaper kind of machine, and log in to
one when something is wrong. Because the machines are yours, a cluster nobody remembered to stop
costs the same at four in the morning as at four in the afternoon.

## Three roles, and why they are different

**Every machine in a cluster has one of three roles, and the role decides what is lost when that
machine disappears.** EMR's documentation calls them nodes:

- the **primary node** coordinates. It runs YARN's ResourceManager, which hands out memory and
  processors to the jobs, and HDFS's NameNode, which knows where every block of the cluster's own
  file system lives. There is one, or three for a cluster that has to survive losing one. The API
  still spells the role `MASTER`, its old name, and so does every command in this lesson;
- a **core node** works and stores. It runs a NodeManager, which executes the tasks YARN gives it,
  and a DataNode, which holds blocks of HDFS. A cluster has at least one;
- a **task node** only works. It runs a NodeManager and stores nothing. It is optional, and a
  cluster may have none.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"An EMR cluster drawn as a dashed boundary holding three columns of machines. The primary node runs ResourceManager and NameNode; if it is lost the cluster ends, and it is on demand. Two core nodes each run DataNode and NodeManager; if one is lost, HDFS blocks go with it, and they are on demand. Two task nodes run only NodeManager; if one is lost the cost is some time, and they are Spot. Outside the cluster, an arrow labelled EMRFS points to s3://quitanda-raw-prod, where the data lives.\" data-fig=\"l24-roles\"><defs><marker id=\"ah-l24-roles\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"480\" height=\"255\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one EMR cluster</text><rect x=\"40\" y=\"60\" width=\"135\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"107.5\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">primary</text><text x=\"107.5\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ResourceManager</text><text x=\"107.5\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NameNode</text><text x=\"107.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if lost: the cluster ends</text><text x=\"107.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">on demand</text><rect x=\"195\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">core</text><text x=\"262.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"195\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"262.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">core</text><text x=\"262.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DataNode</text><text x=\"262.5\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"262.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if lost: HDFS blocks</text><text x=\"262.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">on demand</text><rect x=\"350\" y=\"60\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">task</text><text x=\"417.5\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><rect x=\"350\" y=\"135\" width=\"135\" height=\"65\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"417.5\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">task</text><text x=\"417.5\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NodeManager</text><text x=\"417.5\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">if lost: some time</text><text x=\"417.5\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Spot</text><rect x=\"555\" y=\"100\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">s3://quitanda-raw-prod</text><text x=\"630\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the data lives here</text><line x1=\"500\" y1=\"135\" x2=\"553\" y2=\"135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l24-roles)\"></line><text x=\"527\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">EMRFS</text></svg>", "caption": "What a node runs decides what its loss costs, and what it costs decides which nodes may be Spot."}
```

**The difference between core and task is HDFS.** Take a task node away and the tasks it was
running are given to another machine and run again: the job is slower, and nothing is lost. Take a
core node away and the blocks it held go with it. HDFS keeps copies of each block on other core
nodes, which is what lets a cluster survive one such loss, but shrinking the core group means
moving those blocks first, and a core node that vanishes without warning can fail the job that was
reading it. A primary node that vanishes ends the cluster. That ordering, from "costs some time" to
"costs everything", is what decides which machines may be the cheap ones that AWS can take back,
and the next section uses it.

## Keep the data out of the cluster

**On EMR the data a job reads and writes lives in S3, not in HDFS.** Spark on EMR reads an
`s3://` path directly, through a layer EMR calls EMRFS, so the orders under
`s3://quitanda-raw-prod/raw/orders/` are read where they lie and the result is written to
`quitanda-curated-prod`. HDFS on the core nodes is then scratch space: shuffle files, intermediate
results, anything the job can make again.

That is what makes a cluster disposable. A cluster whose only copy of something is in HDFS can never
be stopped, because stopping it deletes the data. A cluster that keeps everything in S3 can be
created for one night's job and terminated when the job ends, and the next night's cluster finds
everything where the last one left it. The rest of this lesson assumes the second kind, and the
section on steps shows what it looks like.

**Every job on EMR runs on the release you pick**, a label such as `emr-7.9.0`, which fixes the
versions of Spark, Hadoop, Hive and the rest. Two clusters on the same label run the same software.
Glue fixes its versions too, in fewer combinations and with no way to add a library to the machine
itself, which is one of the reasons a team moves a job from Glue to EMR, and the last section of
this lesson weighs it against the others.
