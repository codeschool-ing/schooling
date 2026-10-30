---
title: Mapping data flows: Spark, drawn as boxes
version: 1
---

**A mapping data flow is a transformation drawn in Data Factory's editor and run as a Spark job on a
cluster Data Factory starts for it.** Nobody writes Spark code: the boxes and their settings are
turned into Spark by the service. It is the transformation half of lesson 19's pipeline, for teams
that want the whole night in one visual tool. This section is taught from Microsoft's documentation
and was not run; there is no emulator for data flows, and they need a cluster to run at all.

## What it is made of

**A data flow is a graph of transformations, from one or more sources to one or more sinks.** The
editor offers the operations a cleaning job needs, each as a box with its own settings:

- **source** and **sink**, which read and write datasets, the same datasets and linked services as the
  copy activity of lesson 19;
- **filter**, **select** and **derived column**, which drop rows, keep or rename columns, and compute
  new ones with an expression language of Data Factory's own;
- **aggregate**, **join**, **lookup**, **union** and **conditional split**, which do what their names
  say, across streams of rows;
- **window**, **rank** and **pivot**, for the questions that need them;
- **alter row**, which marks rows to be inserted, updated, upserted or deleted in a database sink.

Quitanda's night, drawn this way, is a source on the raw CSV, a derived column that trims and lowers
the payment and turns `42,87` into cents, an aggregate that keeps one row per order, and a sink into
the curated folder: four boxes for what the section after next writes as one query.

**Behind the boxes is a script**, which the editor shows and which Data Factory stores in the data
flow's definition. It is what Terraform's `azurerm_data_factory_data_flow` takes, and what a review in
Git sees: a text, but one written by the editor rather than by a person, and rarely read by one.

## Where it runs

**Every data flow runs on a Spark cluster that the Azure integration runtime starts**, sized in
cores, and the section on the clock prices it. The cluster belongs to the run: Data Factory starts it,
runs the job, and stops it, unless a time to live keeps it for the next one. **There is no cluster to
look after**, no versions to upgrade and no library to install, and that is most of the reason teams
choose data flows. The same is true of everything you cannot change: the Spark version, the
configuration, what may be installed.

**To build one, the editor offers a debug session**: a cluster kept running while you work, with a
preview of rows after each box. It is billed while it runs, and it is how most data flow work is done,
looking at rows rather than writing tests, which the section on testing comes back to.

## Fabric's dataflows are something else

**Fabric has "Dataflow Gen2", which is not a mapping data flow.** It is Power Query, the transformation
tool of Excel and Power BI, run in Fabric and paid from the capacity of lesson 17. It draws similar
boxes for similar steps, and the engine underneath, the language and the limits are different. A
team moving from Data Factory to Fabric moves its pipelines more easily than its data flows, which is
worth knowing before many are drawn.
