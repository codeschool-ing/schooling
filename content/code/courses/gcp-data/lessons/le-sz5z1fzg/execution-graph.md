---
title: BigQuery's execution graph, from the documentation
version: 1
---

**BigQuery's plan is not a tree of operators in one process, it is a graph of stages across many
slots.** A stage is a piece of the query that many workers run in parallel, each on its own share of
the input, and the rows move from one stage to the next through the shuffle of lesson 13. In the
console it is the **Execution graph** tab of a finished job; in the API and in
`INFORMATION_SCHEMA.JOBS` it is the job's query plan, one entry per stage. Everything in this section
is from Google's documentation of the query plan and of query performance insights, and none of it was
run: there is no BigQuery job in this lab to open.

## The same query, as stages

**September's sales per district would run as about three stages**, and the documentation's own
examples have this shape. The exact split is BigQuery's decision and can differ; what does not differ
is the reason for each boundary.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"BigQuery&#x27;s execution graph for September&#x27;s sales per district, as three stages. S00, Input, run by many workers: READ district, total_cents from the September partitions of orders; AGGREGATE partial sums per district; WRITE to the shuffle, by district. An arrow labelled shuffle leads to S01, Aggregate: READ from S00; AGGREGATE the sums per district; WRITE to the shuffle. A second shuffle arrow leads to S02, Output: READ from S01; SORT by sales; WRITE the answer. Beside each stage, what it reports: records read and written, wait, read, compute and write time as average and maximum, shuffle bytes and slot-milliseconds.\" data-fig=\"l16-stages\"><defs><marker id=\"l16-stages-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"430\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S00: Input</text><text x=\"434\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">many workers</text><text x=\"36\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">READ $1, $2 FROM orders</text><text x=\"36\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WHERE dt BETWEEN '2026-09-01' AND '2026-09-29'</text><text x=\"36\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">AGGREGATE SUM($2) GROUP BY $1</text><text x=\"36\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WRITE TO __stage00_output</text><rect x=\"20\" y=\"150\" width=\"430\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S01: Aggregate</text><text x=\"434\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a few workers</text><text x=\"36\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">READ FROM __stage00_output</text><text x=\"36\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">AGGREGATE SUM GROUP BY $1</text><text x=\"36\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WRITE TO __stage01_output</text><rect x=\"20\" y=\"270\" width=\"430\" height=\"82\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S02: Output</text><text x=\"434\" y=\"286\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one worker</text><text x=\"36\" y=\"306\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">READ FROM __stage01_output</text><text x=\"36\" y=\"322\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SORT BY sales DESC</text><text x=\"36\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">WRITE TO __stage02_output</text><polyline points=\"235,112 235,148\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l16-stages-ah-0)\"></polyline><text x=\"245\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">shuffle, by district</text><polyline points=\"235,232 235,268\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l16-stages-ah-0)\"></polyline><text x=\"245\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">shuffle</text><rect x=\"480\" y=\"12\" width=\"220\" height=\"340\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">each stage reports</text><text x=\"496\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">records read and written</text><text x=\"496\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">wait, read, compute, write:</text><text x=\"496\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">average and maximum</text><text x=\"496\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">shuffle bytes, spilled</text><text x=\"496\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">slot-milliseconds</text></svg>", "caption": "An illustration of the stages, after the examples in Google's documentation; no BigQuery job was run, and BigQuery decides the real split for each query."}
```

**The first stage reads.** Its workers each take a share of the table, the September partitions of it,
read the two columns, and already add up `total_cents` per district for their own share: a partial
aggregate, so that what leaves the stage is a handful of rows per worker and not every order. **They
write those rows to the shuffle**, partitioned by district, so that every partial sum for Pinheiros
reaches the same worker of the next stage.

**The second stage finishes the aggregation** from what the first wrote, one district per group, and
**the third sorts the eight results and writes the answer.** The boundaries fall where the work needs
rows that another worker holds: a total per district needs every worker's partial for that district,
and a sort needs every district.

## What each stage reports

**Each stage lists its steps**, and the step names are the documentation's: `READ` of a table or of an
earlier stage's output, `COMPUTE` for expressions, `FILTER`, `AGGREGATE`, `SORT`, `JOIN`, and `WRITE`
to the shuffle or to the output. Read in order inside a stage, and stage by stage from the first, they
are the same story as DuckDB's tree read from the bottom.

**Each stage reports records read and records written**, and the ratio between them is where a query
gets small. The first stage of the district query would read September's rows and write a few rows per
worker; that drop is the partial aggregate working. A stage that writes as many rows as it reads, into
a shuffle, is moving the whole table across the network.

**Each stage reports its time as wait, read, compute and write, each as an average and a maximum across
its workers.** The average is the typical worker and the maximum is the slowest one, and the stage ends
when the slowest one does. A maximum far above the average is **skew**: one worker was handed far more
than the others, usually because one value of the shuffle key is far more common than the rest. The
documentation's performance insights name it as **partition skew**, and the cure is the one the
distribution of any parallel system needs: a key whose values are spread more evenly, or a filter
that removes the giant before the shuffle.

**Each stage reports the shuffle bytes it wrote, and how many of them spilled to disk.** The shuffle is
held in memory first; a stage that writes more than the memory available spills the rest, and runs
slower. The documentation's insights call the cause **insufficient shuffle quota**.

**And each stage reports its slot time**, in slot-milliseconds. Added over the stages it is the job's
`total_slot_ms`, the number lesson 14 used: on a reservation, it is what the query cost; on demand, it
is what the query used without being billed for it. Divided by the job's elapsed milliseconds, it is
the average number of slots the query held while it ran. A query of 120,000 slot-ms that took four
seconds averaged 30 slots.

## The questions to bring to it

**Which stage took the time, and was it waiting or working?** A long wait with little read or compute is
**slot contention**, another insight of the documentation's: the query was ready and the slots were
busy with other queries, which on a reservation is a reason to look at its maximum and on demand a
reason to look at what else the project runs at the same hour.

**Where did the rows fall?** The stage where records written drop far below records read is where the
query became cheap to move. If that drop comes late, after a join that multiplied the rows, the filter
or the aggregate belongs earlier.

**Did any stage write its whole input to the shuffle?** That is a join or an aggregation on a key the
data was not arranged for, and the bytes of that shuffle are paid in time on demand and in slots on a
reservation.

**None of these questions is about the bytes billed.** On demand, the bill was fixed before the graph
existed, by the columns and the partitions. The execution graph explains time and slots, which is why
the next section goes back to the bytes and asks what an engine actually reads to answer a query.
