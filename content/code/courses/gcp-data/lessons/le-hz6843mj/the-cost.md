---
title: What an external table costs
version: 1
---

**An external table moves three lines of the bill and leaves the fourth where it was.** The queries
cost what they cost on a native table: on demand, 11.25 USD per TiB in `southamerica-east1`, by the bytes
of the columns read in the partitions kept. What changes is where the data is stored and at what rate,
whether the storage ever becomes long-term, and the requests that reading files makes to Cloud Storage.
This section prices each, on Cloud Storage's page and BigQuery's, both read on 2026-10-30.

## The storage

**A native table is billed on its logical or physical bytes; an external one on the size of its
files.** Lesson 13 priced 1 TiB of logical bytes, compressing three to one, as a native table: 23.55 USD
a month all active and logical, 17.10 with nine tenths long-term, and 13.14 under physical billing with
nine tenths long-term. The same data as Parquet files compressing three to one is a third of a TiB in a
Standard bucket, at 0.035 USD per GiB-month:

```
ana@laptop:~/gcp$ python3 -c 'print(round(1024 / 3 * 0.035, 2), round(1024 / 3 * 0.035 * 12, 2))'
11.95 143.36
```

**11.95 USD a month, and 143.36 for a year**, cheaper than any of the native lines while the table is
young. But it never gets cheaper by itself. The BigQuery pricing page is explicit that long-term
storage "applies only to BigQuery storage, not to data stored in external data sources", so a Standard
bucket charges 0.035 for a file nobody has written to in three years. A life-cycle rule from lesson 3
can move old files to Nearline, at 0.02 USD per GiB-month in São Paulo, and lesson 2 explained what that
class charges every time something reads it, which an external table queried by analysts does.

**And the files are only stored once.** The case lesson 13 warned about, the export loaded into a table
and left in the bucket, billed twice, does not arise: the files are the table. For data that has to stay
in the bucket anyway, because other engines read it or because it is the record of what the export
delivered, an external table is the version of the warehouse that adds no storage at all.

## The requests

**Every file a query opens is requests to Cloud Storage**, and the reader of this lesson counted them:
one listing of the prefix and 87 ranged reads for September's two columns. Cloud Storage prices them by
class, per thousand, for a bucket in a single region, on its pricing page: 0.005 USD for Class A, which
includes listing, and 0.0004 USD for Class B, which includes reading an object. For the requests this
lesson's reader made, per thousand queries and for a month of hourly runs:

```
ana@laptop:~/gcp$ python3 -c 'q = 87 / 1000 * 0.0004 + 1 / 1000 * 0.005; print(round(1000 * q, 4), round(720 * q, 4))'
0.0398 0.0287
```

**Four cents for a thousand such queries, and under three cents for a month of hourly ones.** At this
size the requests are a rounding error on the query bill. They grow with the number of files a query
opens, not with the bytes in them, which is lesson 15's small-file problem turning up as a line of the
invoice: the same orders cut into an hour per file would make sixteen times the requests for the same
answer. Whether BigQuery's own reads of an external table appear on the bucket's bill, and how many
requests it makes, is between its reader and Cloud Storage; this arithmetic prices the reader that ran
here, and it is the shape of the cost rather than BigQuery's number.

**The network costs nothing, as long as the two are in one place.** BigQuery requires an external table's
dataset to be in a location compatible with the bucket, and a query in `southamerica-east1` reading a
bucket in `southamerica-east1` moves no data between regions. Lesson 5's egress is what a bucket in
another region would add, and the location rule is there partly to prevent it.

## Choosing

**Load into a native table** when the warehouse is the main reader, the table is queried often, and its
history will sit for years: long-term storage, clustering, cached results and BigQuery's own statistics
are all on the native side. **Leave the files in place, as an external or BigLake table,** when other
engines read the same files, when the data has to stay in the bucket regardless, or when it is queried
rarely enough that loading it would cost more care than querying it in place. For Quitanda, the nightly
orders go into a native, partitioned, clustered table, because the dashboards read them every hour; the
raw exports stay in `quitanda-raw-prod` and are reachable as an external table on the day somebody
needs to check what an export actually delivered.
