---
title: Six parts, and the chain they make
version: 1
---

**Data Factory moves data and runs other services' work on a schedule; it is the job that has to
run at three in the morning, not the engine that does the heavy lifting.** A pipeline in Data
Factory copies a file, calls a stored procedure, starts a Databricks notebook, waits for a folder to
fill, and decides what to do when one of those fails. Most of the computing happens somewhere else.
This section and most of this lesson are taught from Microsoft's documentation and were not run; the
fourth and fifth sections check declarations with Terraform, offline, and say so.

## The six parts

A factory is an Azure resource, created in a subscription and a region, and everything else lives
inside it:

- **a linked service** is a connection: where a store is and how to sign in to it. One for the
  storage account, one for the orders database, one for Databricks. It is the only part that knows a
  credential, or better, which identity to use.
- **a dataset** is a named view of data inside a linked service: this container and this folder, as
  CSV with a header; that table in that database. A dataset can take parameters, so one dataset
  covers every day's export.
- **an activity** is one step: `Copy`, which moves data from a source dataset to a sink dataset;
  `Lookup`, which reads a few rows; `ForEach`, `If Condition` and `Until`, which control the flow;
  and activities that hand work to another service, such as a stored procedure, a Databricks
  notebook or an Azure Function.
- **a pipeline** is a group of activities and the arrows between them: run this after that succeeds,
  run that one only if this fails. Pipelines take parameters and can call each other.
- **a trigger** decides when a pipeline runs: on a clock, for every window of time since a start
  date, or when a file arrives. Its section is the fifth.
- **an integration runtime** is the compute that runs the activities, which is to say where the copy
  happens and from which network it reaches the stores. The next section is about it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"The parts of Quitanda's factory as a chain of references. The trigger tr_orders_nightly starts the pipeline pl_orders_nightly, which holds the activity CopyOrders. The activity's input is the dataset ds_raw_orders and its output the dataset ds_curated_orders. Both datasets name the linked service ls_lake, which points at the storage account stquitandalakeprd and runs on the integration runtime AutoResolveIntegrationRuntime.\" data-fig=\"l19-chain\"><defs><marker id=\"l19-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"20\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"95\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">trigger</text><text x=\"95\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tr_orders_nightly</text><rect x=\"200\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"275\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pipeline</text><text x=\"275\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pl_orders_nightly</text><rect x=\"380\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"455\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">activity</text><text x=\"455\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">CopyOrders</text><line x1=\"170\" y1=\"55\" x2=\"197\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><line x1=\"350\" y1=\"55\" x2=\"377\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><rect x=\"300\" y=\"120\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"380\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dataset</text><text x=\"380\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ds_raw_orders</text><rect x=\"480\" y=\"120\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"560\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dataset</text><text x=\"560\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ds_curated_orders</text><line x1=\"430\" y1=\"80\" x2=\"385\" y2=\"117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><line x1=\"480\" y1=\"80\" x2=\"555\" y2=\"117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><text x=\"392\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">input</text><text x=\"528\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">output</text><rect x=\"390\" y=\"210\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"470\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linked service</text><text x=\"470\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ls_lake</text><line x1=\"380\" y1=\"170\" x2=\"440\" y2=\"207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><line x1=\"560\" y1=\"170\" x2=\"500\" y2=\"207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><rect x=\"150\" y=\"210\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"235\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">integration runtime</text><text x=\"235\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">AutoResolveIntegrationRuntime</text><line x1=\"390\" y1=\"235\" x2=\"323\" y2=\"235\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><text x=\"355\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">runs on</text><rect x=\"580\" y=\"210\" width=\"125\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"642\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the store</text><text x=\"642\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">stquitandalakeprd</text><line x1=\"550\" y1=\"235\" x2=\"577\" y2=\"235\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l19-ah)\"/><text x=\"360\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each arrow is a reference by name; only the linked service knows how to sign in</text></svg>", "caption": "Quitanda's nightly load, part by part. The trigger knows only the pipeline, the activity only its datasets, and only the linked service knows where the data is and how to reach it."}
```

**Every arrow in that picture is a reference by name.** A pipeline names its datasets, a dataset
names its linked service, a linked service names its runtime. That is what lets one linked service
serve fifty datasets, and it is also how a factory breaks: rename a dataset and every pipeline that
named it fails at its next run, which is lesson 1's argument about names in another setting.

## What a pipeline does not do

**A copy activity copies; it does not clean.** It can map columns and convert a CSV into Parquet,
and nothing more interesting than that. Removing duplicates, fixing a total written with a comma,
joining the orders to the customers: that is a transformation, and Data Factory hands it to an engine,
a mapping data flow or a notebook, which is lesson 20's choice. The usual shape of a night is
therefore a pipeline of three or four activities, a copy into the raw layer, a transformation run
somewhere else, a check, and a message when something fails, with Data Factory deciding the order and
the retries.

**It is the same idea as an Airflow DAG**, written as JSON documents instead of Python and run by
Microsoft instead of by a scheduler you keep running. Fabric has the same pipelines inside it, as
lesson 17 mentioned, billed in capacity units instead of by the run.
