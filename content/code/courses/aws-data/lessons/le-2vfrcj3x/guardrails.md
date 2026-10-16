---
title: Workgroups, partition projection and CTAS
version: 1
---

**A lake priced by the byte needs a limit on the byte**, because the expensive query is not a
complicated one: it is `SELECT *` with no filter, typed by somebody exploring, against the table
with the most history. Athena's limit lives in a **workgroup**, the unit that every query runs in.
A workgroup carries where results are written, whether its settings override what a client asks
for, and how many bytes one query may read before Athena cancels it.

## A workgroup with a cutoff

```
ana@laptop:~/aws$ aws athena create-work-group --name analysts --configuration 'ResultConfiguration={OutputLocation=s3://quitanda-athena-results-prod/analysts/},EnforceWorkGroupConfiguration=true,BytesScannedCutoffPerQuery=10485760'
ana@laptop:~/aws$ aws athena get-work-group --work-group analysts --query 'WorkGroup.Configuration.[BytesScannedCutoffPerQuery,EnforceWorkGroupConfiguration]' --output text
10485760	True
ana@laptop:~/aws$ aws athena start-query-execution --work-group analysts --query-string "SELECT * FROM quitanda.orders_csv"
{
    "QueryExecutionId": "3b75ad5a-d87c-49cf-9d27-370e0bcdd10a"
}
ana@laptop:~/aws$ aws athena get-query-execution --query-execution-id 3b75ad5a-d87c-49cf-9d27-370e0bcdd10a --query 'QueryExecution.[WorkGroup,Status.State,Statistics.DataScannedInBytes]' --output text
analysts	SUCCEEDED	0
```

**moto kept the cutoff and enforced nothing.** `BytesScannedCutoffPerQuery` is 10,485,760, ten
megabytes, the smallest cutoff Athena accepts, and `EnforceWorkGroupConfiguration` is on, so a
client cannot point its results elsewhere. Then a `SELECT *` over the CSV month, a table moto does
not have, in a workgroup that should have stopped it at ten megabytes of the 40,641,097 that table
holds, came back `SUCCEEDED` having read 0 bytes. On AWS that query is cancelled once its scan passes
the cutoff, and the person who typed it gets an error naming the limit rather than a bill.

That is the part of this section that could be run, and it shows only that the request is well
formed. What the cutoff does was not run here; it is described from AWS's documentation, and the
place to see it is the first query on a real account that crosses it.

Two more things belong to a workgroup and are worth setting on day one. **One workgroup per kind of
user**: the analysts' ad hoc questions, the dashboard's scheduled ones, the nightly jobs. Each then
has its own results prefix, its own cutoff and its own line in the bill, because Athena reports the
bytes per workgroup. And **a limit for the whole workgroup**, per hour or per day, which raises an alarm when it is crossed and cancels nothing. The per-query cutoff stops one bad question; the workgroup limit notices a dashboard that asks a reasonable question too often.

## Partitions nobody has to add

"Athena reads the files where they lie" named the commonest surprise, a day that is in S3 and not in the catalog.
**Partition projection removes the catalog from the question**: the table says how partition values
are formed, and Athena computes the list of keys for a query instead of looking it up. For the
orders it is a few properties on the table:

```sql
ALTER TABLE quitanda.orders SET TBLPROPERTIES (
  'projection.enabled'          = 'true',
  'projection.dt.type'          = 'date',
  'projection.dt.format'        = 'yyyy-MM-dd',
  'projection.dt.range'         = '2026-10-01,NOW',
  'projection.dt.interval'      = '1',
  'projection.dt.interval.unit' = 'DAYS',
  'storage.location.template'   = 's3://quitanda-curated-prod/orders/dt=${dt}/'
)
```

With that in place, tonight's file is readable tomorrow morning with nothing registered. A query for `dt = '2026-10-15'` goes straight to one prefix without asking the catalog which partitions exist, and on a table of tens of thousands of partitions that question is where a query's first seconds go. The
price is that the template is now a promise about the keys: a file written under any other name is
invisible, and a day with no file is a prefix Athena lists and finds empty. Not run here, since moto
runs no Athena SQL; it is the form AWS documents for a date projection.

## CTAS: a query that writes a table

`CREATE TABLE … AS SELECT` runs a query and writes its result as a new table, in the format you name,
under the prefix you name. **It is how Athena itself turns the raw layer into the curated one**:

```sql
CREATE TABLE quitanda.orders_from_csv
WITH (
  format            = 'PARQUET',
  write_compression = 'SNAPPY',
  external_location = 's3://quitanda-curated-prod/orders_from_csv/',
  partitioned_by    = ARRAY['dt']
) AS
SELECT order_id, customer_id, hour, items, total_cents, payment, neighbourhood, dt
FROM quitanda.orders_csv
```

The partition column goes last in the `SELECT`, which is the rule CTAS reads it by. The query is
billed like any other, for the CSV it reads, once, and every query after it reads the Parquet. Two
limits decide whether it is the right tool. **One CTAS writes at most 100 partitions**, so October's
31 days fit and a year does not, which turns a backfill into a series of `INSERT INTO` statements of
a hundred days each. And it is one statement with no memory of what it did yesterday: the job that
converts each new day, every night, is the subject of lesson 17. This statement was not run either.
