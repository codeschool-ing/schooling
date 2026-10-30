---
title: Database Migration Service, and the Data Transfer Service
version: 1
---

**Datastream follows a database into a warehouse; Database Migration Service moves the database
itself.** The two use the same machinery underneath, a backfill and then CDC out of the source's
log, and they end in different places. A Datastream stream ends in BigQuery or Cloud Storage, and
the shop keeps running on its own PostgreSQL. A migration job ends in Cloud SQL or AlloyDB, lessons
6 to 8, and its last step is the shop moving there. Neither has an emulator, so this section is read,
and its commands are marked as not run.

## A migration job

**A Database Migration Service job is a source profile, a destination and a type.** The type is the
first decision, and there are two:

| type | what it does | when it is the answer |
|---|---|---|
| `ONE_TIME` | dumps the source and loads it into the destination, once | the source can stop writing for the copy |
| `CONTINUOUS` | loads the source, then replicates every change until you promote the destination | a live database moving with almost no downtime |

Quitanda's shop moving from the rack to Cloud SQL for PostgreSQL is the second kind. The source is a
connection profile like Datastream's, and the destination is a Cloud SQL instance the job creates or
one that exists. **Not run here:**

```sh
gcloud database-migration migration-jobs create shop-to-cloudsql \
  --region=southamerica-east1 --type=CONTINUOUS \
  --source=legacy-shop-dms --destination=shop-cloudsql
gcloud database-migration migration-jobs start shop-to-cloudsql --region=southamerica-east1
```

**For PostgreSQL to PostgreSQL the copy rides on logical replication**, the publications and
slots of the section before this one: by default through the `pglogical` extension, which the
source must have installed, and with `--use-postgres-native`, a flag this version of the command
line offers, through PostgreSQL's own publications and subscriptions. The same requirements follow from that: `wal_level=logical` on the
source, a user allowed to replicate, and a primary key, or a replica identity, on every table whose
updates must cross. A source without them fails the job's own checks before anything is copied,
which `gcloud database-migration migration-jobs verify` runs on demand.

**The cutover has a name here: promote.** `gcloud database-migration migration-jobs promote` stops
the replication and makes the destination a standalone primary that accepts writes. After it, the
applications are pointed at the new instance, and the job is over. The next section is about the
order around that one command, which is where migrations lose data.

## What it costs

From `cloud.google.com/database-migration/pricing`, read on 2026-10-30: **a homogeneous migration,
MySQL to Cloud SQL for MySQL or PostgreSQL to Cloud SQL for PostgreSQL or AlloyDB, is offered at no
additional charge.** What is billed is the destination itself, at Cloud SQL's or AlloyDB's prices, and
any network the migration crosses. A **heterogeneous** migration, Oracle or SQL Server into
PostgreSQL, is billed per GiB processed, at the same São Paulo tiers as Datastream's, $3.176 a GiB
for the first 2,500 GiB of changes in a month. The page contradicts itself on one point: its prose
says the first 50 GiB of backfill each month is free, and its table and its example say 500. The
table is what the example computes from, and it is the number this course would plan with, while
asking Google before relying on it.

## BigQuery Data Transfer Service

**The Data Transfer Service is for loads that happen on a schedule, not for every change.** A
*transfer configuration* names a source, a destination dataset, a schedule and the parameters of
the source, and BigQuery runs it, keeps a history of every run, and can re-run a past date on
request, which is the backfill of the previous lesson in a different product. Its sources include
Cloud Storage, Amazon S3 and Azure Blob Storage, other warehouses being migrated, such as Amazon
Redshift and Teradata, Google's own advertising and analytics products, and a growing list of
databases and SaaS applications. The scheduled queries of lesson 18 are transfer configurations
too.

For Quitanda the obvious one is the nightly export of lesson 1: an object in
`gs://quitanda-raw-prod/raw/orders/` loaded into a BigQuery table every night. **Not run here,
because `bq` has nowhere to go in this lab:**

```sh
bq mk --transfer_config --data_source=google_cloud_storage \
  --target_dataset=shop --display_name='nightly orders' \
  --params='{"data_path_template": "gs://quitanda-raw-prod/raw/orders/*", "destination_table_name_template": "orders", "file_format": "CSV", "skip_leading_rows": "1"}'
```

**Its pricing depends on the connector.** The BigQuery pricing page, read on 2026-10-30, lists the
Cloud Storage, Amazon S3, Azure Blob Storage, Redshift and Teradata connectors, among others, with
no charge for the transfer's orchestration, and the loading itself uses BigQuery's free shared pool
for batch loads. The connectors for databases and SaaS products, PostgreSQL and MySQL among them,
are billed by the slot-hours they consume, and the page suggests planning for up to 20 slot-hours
per hour a transfer runs. The São Paulo rate for those slot-hours is not one this course could tell
apart from BigQuery's other slot prices on the page, so no number is given for it here.

## Which of the three

**Datastream when the warehouse should follow the database within minutes, DMS when the database is
moving, and the Data Transfer Service when once a night is enough.** For Quitanda the answer is all
three, at different times: the transfer of the nightly export is what reports run on today;
Datastream into BigQuery is what lets them stop waiting for the night; and the day the shop moves
to Cloud SQL is a DMS job, with the same backfill, the same slot and the same cutover the next
section orders.
