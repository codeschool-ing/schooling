---
title: The catalog: entries, aspects and search
version: 1
---

**A catalog answers "what do we have, and what does it mean" without anybody opening the data.**
Quitanda has a few hundred tables by now, and the question an analyst asks first is not a query but
a search: is there a table of deliveries, who owns it, is it the cleaned one or the raw one, may I put
it in a report. Dataplex's catalog is the index that answers those, and its model has three nouns.

## Entries, entry groups and aspects

**An entry is the catalog's record of one data asset**: a BigQuery dataset or table, a Cloud Storage
bucket, a Pub/Sub topic, a Spanner table, a Cloud SQL database. **Entries for Google Cloud's own
services appear by themselves.** The catalog ingests the technical metadata of BigQuery and the rest
as resources are created and changed, into system entry groups whose names begin with `@`, such as
`@bigquery`, and nobody has to register a table for it to be found. An **entry group** is a container
of entries; a team that wants to catalogue something outside Google Cloud, the old ERP's tables say,
makes an entry group of its own and writes custom entries into it, each of an **entry type** it
defines.

**An aspect is a piece of structured metadata attached to an entry**, and it is where the meaning
lives. Every aspect has an **aspect type**, which is a schema: field names, their types, which are
required. The system attaches some aspects on its own, the schema of a BigQuery table being one of
them, and a team defines the rest. Quitanda wants every curated table to say who owns it and whether
it holds personal data, so it would define one aspect type. Its template, `ownership.json`, is shown
as the documentation describes the format and was not checked by anything here:

```json
{
  "name": "ownership",
  "type": "record",
  "recordFields": [
    {"name": "owner_team", "type": "string", "index": 1, "constraints": {"required": true}},
    {"name": "contains_personal_data", "type": "bool", "index": 2, "constraints": {"required": true}},
    {"name": "retention_days", "type": "int", "index": 3}
  ]
}
```

```sh
gcloud dataplex aspect-types create ownership --location=southamerica-east1 \
  --metadata-template-file-name=ownership.json
```

**An aspect type with `required` fields is a rule, not a suggestion.** An aspect that leaves out
`owner_team` is refused when it is written, which is the difference between a catalog with
structured metadata and a wiki page per table. The older Data Catalog called the same idea a **tag**
with a **tag template**, and the documentation of its migration maps one onto the other: a tag
template becomes an aspect type, and a tag becomes an aspect.

## Search, and what the catalog is not

**Search runs over names, descriptions and aspect values together.** Not run:

```sh
gcloud dataplex entries search "orders" --project=planner-dev
```

It would return the BigQuery table `curated.orders`, the dataset that holds it, and any custom entry
whose name or description mentions orders, each with its aspects.
It returns only the ones the person searching may see: the catalog filters results by the IAM permissions on the underlying resources,
so it never reveals that a table exists to somebody who cannot read its metadata.

**The catalog is an index over the data's own metadata, not the place the engines read it from.**
BigQuery keeps each table's schema in BigQuery; the catalog's entry for the table is a reflection of
it, kept up to date by ingestion. Dropping a table removes its entry, and an entry cannot create a
table. Where an engine does need an external catalog to know what files form a table, as Spark and
open table formats do, Google Cloud's answer is the BigLake metastore of lesson 17, a different
service from this one. **So a stale catalog misleads people, and it never breaks a query.** That
makes its accuracy a matter of discipline, which is why the required fields above matter.

## The price of metadata

From cloud.google.com/dataplex/pricing, read 2026-10-30, the same in every region: metadata storage
is **$0.002739726 per GiB-hour**, and the page says that technical metadata ingested automatically
from Google Cloud services, such as BigQuery, is stored at no charge. API calls are free, search
included. So what Quitanda pays for is the aspects it writes itself:

```
ana@laptop:~/gcp$ python3 -c 'gib = 0.002739726 * 730; print(round(gib, 4), round(300 * 1024 / 2**30 * gib, 6))'
2.0 0.000572
```

**A GiB of metadata is two dollars a month.** The page's own example puts a small aspect at about a
kilobyte, so a GiB is about a million of them; Quitanda's few hundred tables with one ownership
aspect each are a few hundred kilobytes, and the bill for them rounds to nothing. The catalog's cost
is the discipline of keeping it true, not its storage.
