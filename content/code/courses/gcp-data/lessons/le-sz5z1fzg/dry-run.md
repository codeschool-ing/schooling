---
title: The dry run and the maximum bytes billed
version: 1
---

**A dry run asks BigQuery what a query would process, and runs nothing.** BigQuery parses the query,
resolves its tables and columns, applies the partition filter, and answers with the number of bytes it
would process. It costs nothing: the query does not run, and Google's documentation on estimating
query costs states that a dry run is not billed. It is the program of the last section done by the
service itself, against the real table and the real metadata. Nothing in this section was run, for the
reason lesson 13 gave: `bq` has nowhere to go here.

## On the command line

This is the command you would type, and its output is not shown because there is none to show:

```sh
bq query --use_legacy_sql=false --dry_run \
  'SELECT district, SUM(total_cents) AS sales
   FROM quitanda.orders
   WHERE dt BETWEEN "2026-09-01" AND "2026-09-29"
   GROUP BY district'
```

**`--dry_run` makes `bq` print a sentence with the number of bytes the query would process** and
exit. On the real table that number would be the 15,023,069 `bqbill.py` printed, give or take the
difference between DuckDB's view of the table and BigQuery's: the same rows, the same types, the same
rule. The console's query editor does the same thing as you type, showing the estimate above the editor
before you press Run, and it is the most useful number on the screen.

## In a program

**A program asks for a dry run through the client library**, and a program is where the habit pays,
because a program runs the same query thousands of times. In Python, with the
`google-cloud-bigquery` library, it is one setting of the job:

```python
from google.cloud import bigquery

client = bigquery.Client(project='planner-dev')
config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
job = client.query(SQL, job_config=config)
print(job.total_bytes_processed)
```

**`use_query_cache=False` is how Google's own Python example of a dry run is written**, so that the
estimate describes the query as it would run, and not a stored result of it, which would bill nothing. The library is not installed in this lab, since there is no BigQuery
for it to talk to, and the block above was not run.

## The maximum bytes billed

**`maximum_bytes_billed` is the dry run's verdict enforced by BigQuery.** It is a limit set on a query:
if the query would be billed more than the limit, BigQuery refuses it with an error before reading
anything, and the refusal costs nothing. On the command line it is a flag:

```sh
bq query --use_legacy_sql=false --maximum_bytes_billed=1073741824 \
  'SELECT * FROM quitanda.orders WHERE dt = "2026-09-29"'
```

and in the library it is `bigquery.QueryJobConfig(maximum_bytes_billed=1073741824)`, 1 GiB. A program
that sets it on every query it sends cannot be the program that reads the whole history by mistake.
**It is the per-query guardrail; lesson 14's custom quotas are the per-day one**, and the two are made
for different mistakes: the maximum stops one bad query, the quota stops a reasonable query run too
often.

**The limit has to be chosen for the query, not for the project.** A limit of 1 GiB on a dashboard
that reads 10 MB leaves room for a hundredfold mistake before it acts; a limit of 1 GiB on the nightly
transformation of a large table refuses it every night. The dry run is how the number is chosen: run it
once, take what it prints, and set the maximum a comfortable margin above.

## What neither can know

**Both are computed before the query runs, so both miss what only running reveals.** For a clustered
table, the dry run reports an upper bound and the bill is often lower, as lesson 15 explained, and a
maximum set from the dry run can refuse a query that would in fact have been billed less. And on
capacity pricing, neither says anything about slots: a dry run reports bytes, and a query on a
reservation is billed by slot time, which only the execution graph of the section after next shows.
