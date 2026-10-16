---
title: Partitions, one row each
version: 1
---

**A partition is a row in the catalog with a value and a prefix of its own.** The table says that
`dt` comes from the key; each partition says one value of `dt` and where that value's files are. A
reader that wants `dt = '2026-10-15'` asks the catalog for that row, gets one location, and lists
nothing else. That is how Athena skips 30 days of 31, and it is why lesson 15's new day stayed
invisible to Athena until somebody added its row.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Two boxes side by side. On the left, the Glue Data Catalog in sa-east-1 holds the database quitanda, which holds the table orders: seven columns in Parquet, a location, and the partition key dt. Inside the table are partitions, one row each, for dt 2026-10-01, 2026-10-02 and 2026-10-31, and 31 rows in all. On the right, S3 holds the bytes: the bucket quitanda-curated-prod with one prefix per day, each holding orders.parquet. An arrow goes from each partition row to its prefix.\" data-fig=\"l16-catalog\"><rect x=\"10\" y=\"10\" width=\"370\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Glue Data Catalog, sa-east-1</text><rect x=\"24\" y=\"42\" width=\"342\" height=\"256\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"38\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">database</text><text x=\"90\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">quitanda</text><rect x=\"38\" y=\"72\" width=\"314\" height=\"214\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">table</text><text x=\"88\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"52\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">7 columns, Parquet</text><text x=\"52\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">s3://quitanda-curated-prod/orders/</text><text x=\"52\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition key</text><text x=\"132\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">dt</text><text x=\"52\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partitions, one row each</text><rect x=\"52\" y=\"180\" width=\"286\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"62\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dt=2026-10-01</text><rect x=\"52\" y=\"206\" width=\"286\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"62\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dt=2026-10-02</text><rect x=\"52\" y=\"252\" width=\"286\" height=\"20\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"62\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dt=2026-10-31</text><text x=\"62\" y=\"239\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… 31 rows</text><rect x=\"420\" y=\"10\" width=\"290\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3, the bytes</text><text x=\"434\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">quitanda-curated-prod</text><rect x=\"434\" y=\"180\" width=\"262\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders/dt=2026-10-01/orders.parquet</text><line x1=\"338\" y1=\"190\" x2=\"428\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><path d=\"M 428 186 L 434 190 L 428 194 Z\" fill=\"var(--phosphor)\"></path><rect x=\"434\" y=\"206\" width=\"262\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders/dt=2026-10-02/orders.parquet</text><line x1=\"338\" y1=\"216\" x2=\"428\" y2=\"216\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><path d=\"M 428 212 L 434 216 L 428 220 Z\" fill=\"var(--phosphor)\"></path><rect x=\"434\" y=\"252\" width=\"262\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"444\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders/dt=2026-10-31/orders.parquet</text><line x1=\"338\" y1=\"262\" x2=\"428\" y2=\"262\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><path d=\"M 428 258 L 434 262 L 428 266 Z\" fill=\"var(--phosphor)\"></path><text x=\"444\" y=\"239\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…</text></svg>", "caption": "The catalog describes and S3 stores. Each partition is a row with a value of dt and a prefix of its own; a query filtered on dt asks the catalog for rows and opens only their prefixes."}
```

## Thirty-one rows

The lake needs its files before the partitions mean anything, so `lake.py` from lesson 15 writes
October again into the empty moto:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod && aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-raw-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ python3 lake.py
755,511 orders in 31 days
  s3://quitanda-raw-prod/raw/orders/  31 objects    40,641,097 bytes
  s3://quitanda-curated-prod/orders/  31 objects    12,703,975 bytes
```

A partition carries a whole storage descriptor, columns and format included, which makes 31 of them a
lot to type. A short program writes them out of the table's own JSON, changing only the location:

`partitions.py`:

```python
import json
import sys

table = json.load(open('orders-table.json'))
storage = table['StorageDescriptor']
partitions = []
for d in range(1, 32):
    day = f'2026-10-{d:02d}'
    partitions.append({'Values': [day],
                       'StorageDescriptor': dict(storage, Location=f"{storage['Location']}dt={day}/")})
json.dump(partitions, sys.stdout, indent=1)
```

```
ana@laptop:~/aws$ python3 partitions.py > partitions.json && jq length partitions.json
31
ana@laptop:~/aws$ aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --query 'length(Partitions)'
31
```

**One request made 31 rows**, and `batch-create-partition` takes up to 100 at a time, so a year of
days is four requests. Asking for some of them back is a filter on the partition keys, written
almost as SQL:

```
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --expression "dt BETWEEN '2026-10-10' AND '2026-10-12'" --query 'Partitions[].[Values[0],StorageDescriptor.Location]' --output text
2026-10-10	s3://quitanda-curated-prod/orders/dt=2026-10-10/
2026-10-11	s3://quitanda-curated-prod/orders/dt=2026-10-11/
2026-10-12	s3://quitanda-curated-prod/orders/dt=2026-10-12/
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --expression "payment = 'pix'"

aws: [ERROR]: An error occurred (InvalidInputException) when calling the GetPartitions operation: Invalid partition expression!
```

**That expression is what Athena sends when a query filters on `dt`.** The catalog answers with
three rows and their locations, and the engine opens those three prefixes and no other. moto evaluated both expressions for real. The second filters on `payment`, a column inside the files, and the catalog refused it, because it knows nothing about what is inside them.

## A row is not a file

Sent a second time, the batch does not fail as a whole. It answers with one error per partition
that already exists:

```
ana@laptop:~/aws$ aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json --query 'length(Errors)'; echo "exit $?"
31
exit 0
ana@laptop:~/aws$ aws glue batch-create-partition --database-name quitanda --table-name orders --partition-input-list file://partitions.json --query 'Errors[0]'
{
    "PartitionValues": [
        "2026-10-01"
    ],
    "ErrorDetail": {
        "ErrorCode": "AlreadyExistsException",
        "ErrorMessage": "Partition already exists."
    }
}
```

**31 errors and an exit status of zero**, so a script that reruns the same batch every night
neither breaks nor notices. A job that registers its own day should read the `Errors` list rather
than trust the exit status.

And a partition can name a prefix where nothing is:

```
ana@laptop:~/aws$ aws glue create-partition --database-name quitanda --table-name orders --partition-input '{"Values": ["2026-12-25"], "StorageDescriptor": {"Location": "s3://quitanda-curated-prod/orders/dt=2026-12-25/"}}'
ana@laptop:~/aws$ aws glue get-partitions --database-name quitanda --table-name orders --expression "dt > '2026-10-31'" --query 'Partitions[].Values[0]' --output text
2026-12-25
ana@laptop:~/aws$ aws s3 ls s3://quitanda-curated-prod/orders/dt=2026-12-25/; echo "exit $?"
exit 1
ana@laptop:~/aws$ aws glue delete-partition --database-name quitanda --table-name orders --partition-values 2026-12-25
```

**The catalog accepted Christmas Day, and S3 has nothing under it.** The row and the files are two
facts kept in two services, and nothing ties one to the other: a partition with no files is a query
that returns nothing, and a prefix with no partition is a day that does not exist for Athena. The
last command took the row away again, because the rest of this lesson counts what is there.

## Who adds the rows

There are four ways, and a lake usually ends up using two of them:

- **the writer**, which calls `batch-create-partition` right after it writes a day, so the row exists
  the moment the files do;
- **`MSCK REPAIR TABLE`** in Athena, which lists the whole prefix and adds what is missing, and gets
  slower as the prefix grows;
- **a crawler**, the next section;
- **partition projection**, lesson 15, which needs no rows at all.

## What the catalog costs

```
ana@laptop:~/aws$ python3 prices.py glue
AWS public price list, sa-east-1, USD, excluding tax

Glue, USD
  ETL job, per DPU-hour                                 0.69000  DPU-hour
  ETL job, Flex, per DPU-hour                           0.45000  DPU-hour
  crawler, per DPU-hour                                 0.69000  DPU-hour
  Data Catalog, per 100,000 objects beyond free         1.00000  month
  Data Catalog, per million requests beyond free        1.00000  million
```

**Both catalog lines say "beyond free"**, and the free part is large: AWS's pricing page gives the
first million objects stored and the first million requests each month at no charge. An object is a
database, a table, a partition or a version of a table. This lake is one database, one table and 31
partitions, 33 objects, and ten years of 20 tables partitioned by day would be 73,000 partitions,
still under the free million. **The requests are the line that grows**: every Athena query asks the
catalog for its table and its partitions, so a dashboard of many panels refreshed every minute is
where the catalog stops being free, at 1 dollar a million requests beyond the first million.

