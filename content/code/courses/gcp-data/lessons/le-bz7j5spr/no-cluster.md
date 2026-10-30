---
title: A warehouse with no cluster to size
version: 1
---

**BigQuery is not a database server you rent.** With Cloud SQL, in lesson 6, you chose a machine, a
disk and a region, and you paid for that machine every hour it existed. BigQuery asks for none of
that. There is no instance to create, no node type, no number of machines and nothing to switch off
at night. What it has instead is two separate systems: one that keeps the tables, and one that runs
the queries. They meet only while a query is running, and **each of them sends its own bill**.

That is the whole lesson in one sentence, and the rest of it is what follows from it. Everything in
this section comes from Google's documentation, chiefly the overview of BigQuery's architecture and
the pricing page at `cloud.google.com/bigquery/pricing`, which this course read on 2026-10-30. None
of it was run here, for a reason the next section gives in full.

## Storage, which you never see

**A BigQuery table is stored by Google in a columnar format, on Google's own distributed file
system**, and the documentation names both: the format is called Capacitor and the file system is
Colossus. Each column of a table is written apart from the others and compressed, and the data is
replicated across the zones of the location the table lives in. You never handle a file, a block or
a disk. You cannot choose the compression, see the files, or add space: a table grows when rows are
written into it, and that is all.

**What you pay for is what the tables hold, per GiB and per month.** The unit is the gibibyte,
1,073,741,824 bytes, and the price is prorated by the second, so a table that exists for half a
month costs half. Two choices change the rate, both of them about the storage and neither about
speed: whether a table has been modified in the last 90 days, and whether you are billed for its
size before or after compression. The last section of this lesson is those two choices, priced.

## Compute, which you rent by the slot

**A query runs on slots**, and the pricing page defines a slot in two words: a virtual CPU. The
engine that runs the queries, which Google's papers call Dremel, turns a query into a plan of
**stages**. A stage that reads a table is cut into many pieces of work, one per piece of the table,
and as many slots as are free take those pieces at the same time. Between one stage and the next,
the rows each slot produced are **shuffled**: sent through a tier of memory to the slots of the next
stage, grouped by whatever key that stage needs, such as the store for a sum per store.

**The number of slots is not something you set on the default model.** A project that pays per byte
read has, in the pricing page's words, "up to 2,000 concurrent slots, shared among all queries in a
single project", and BigQuery decides how many of them each query gets. A query against a small
table is given a few; a query against a large one is given many and finishes in about the same
time. That is what serverless means here: the size of the machine follows the size of the question,
and nobody sized it in advance.

The other way to pay is to reserve slots and be billed for them by the hour, whatever the queries
read. That is the subject of lesson 14, and for now it is enough to know it exists.

## The network between them

**Compute reads storage across Google's network, and it reads only the columns a query names.** A
query that adds up `total_cents` for one day reads the `total_cents` column and the column that
holds the day, and leaves the other columns of the table where they are. This is why the two
systems can be priced apart: adding slots to a query does not move or copy the table, and a table
that doubles in size does not need a bigger machine to hold it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"BigQuery&#x27;s storage and compute, apart. On the left, storage: the orders table kept as separate columns, order_id, customer_id, store_id, district, total_cents and dt, of which total_cents and dt are highlighted. An arrow labelled only the columns named carries those two to the right, to compute: a first stage of four slots that read, a shuffle, and a second stage of two slots that sum per store. Under storage, its bill: per GiB-month, to the project that owns the table. Under compute, its bill: per TiB read or per slot-hour, to the project that runs the query.\" data-fig=\"l13-arch\"><defs><marker id=\"l13-arch-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-arch-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"250\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">storage</text><text x=\"145\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Colossus, each column apart</text><rect x=\"40\" y=\"62\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"40\" y=\"90\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"40\" y=\"118\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">store_id</text><rect x=\"40\" y=\"146\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">district</text><rect x=\"40\" y=\"174\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">total_cents</text><rect x=\"40\" y=\"202\" width=\"210\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt</text><rect x=\"450\" y=\"12\" width=\"250\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">compute</text><text x=\"575\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">slots, in stages</text><text x=\"575\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">stage 1: read</text><rect x=\"468\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"491\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"524\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"547\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"580\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"603\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"636\" y=\"82\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"659\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><polyline points=\"575,108 575,146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-arch-ah-0)\"></polyline><text x=\"585\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">shuffle</text><text x=\"575\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">stage 2: sum per store</text><rect x=\"520\" y=\"172\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"543\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><rect x=\"584\" y=\"172\" width=\"46\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">slot</text><polyline points=\"250,185 360,185 360,95 462,95\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l13-arch-ah-1)\"></polyline><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">only the columns named</text><rect x=\"20\" y=\"260\" width=\"250\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"145\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">billed per GiB-month</text><text x=\"145\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">to the project that owns the table</text><rect x=\"450\" y=\"260\" width=\"250\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"575\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">billed per TiB read, or per slot-hour</text><text x=\"575\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">to the project that runs the query</text></svg>", "caption": "Storage keeps every column apart and compute reads only the ones a query names, which is why each can be billed on its own terms."}
```

## Projects, datasets and tables

**A table lives in a dataset, and a dataset lives in a project.** The dataset is the unit with a
location, fixed when it is created: Quitanda's would be `quitanda`, in `southamerica-east1`, in the
project `planner-dev`, and its full name is `planner-dev.quitanda.orders`. A query can only read
tables in one location, so a dataset created in the wrong region is a dataset that has to be copied
before it can be joined with the others. It is the same lesson as a bucket's location in lesson 1,
and it is learnt the same way.

**A query is a job, and a job belongs to the project that runs it.** That project pays for the
compute, whichever project owns the tables. The pricing page puts it plainly: "You are charged for
queries run against shared data. The data owner is not charged when their data is accessed." So the
team that owns `quitanda.orders` pays to store it, and the analysts who query it from their own
project pay for every query they run. Storage is billed to the owner, compute to the reader, and
that alone is a reason the two lines are separate.

## Two bills, in two units

| | what it measures | unit | southamerica-east1 |
|---|---|---|---|
| storage | the bytes the tables hold | GiB-month | from 0.016 to 0.07 USD, by model |
| compute, on demand | the bytes a query reads | TiB | 11.25 USD, the first TiB a month free |
| compute, capacity | the slots reserved | slot-hour | from 0.062 USD, by edition |

**The prices are from `cloud.google.com/bigquery/pricing`, read on 2026-10-30, in USD, for
`southamerica-east1`.** The storage line has four prices and the last section explains them. The
first 10 GiB of storage each month is free, and so is the first TiB of query data. The two compute
lines are the two pricing models of lesson 14, and a project uses one or the other for a given
query, never both.

**What BigQuery leaves out is as telling as what it charges.** There is no distribution key to
choose, because no table lives on a particular machine. There is no index to build and no vacuum to
schedule, because the storage is Google's to arrange. The two decisions left to you that change the
bill are how a table is **partitioned** and how it is **clustered**, which is lesson 15, and they
work by the same principle as everything above: the cheapest byte is the one a query never reads.
