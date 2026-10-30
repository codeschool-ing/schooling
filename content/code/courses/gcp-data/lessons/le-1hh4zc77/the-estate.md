---
title: Lakes, zones and assets, and a product that changed its name
version: 1
---

**Dataplex does not store data, and it does not move any.** The orders stay in Cloud Storage and
the tables stay in BigQuery, where lessons 1 to 18 put them. What Dataplex adds is a layer of
description over all of it: what exists, what each thing means, who may see which part, whether the
numbers in it are sane, and which job made it from what. The wrong picture is a new store, or a copy
of the estate. Nothing in this lesson changes a byte of Quitanda's data.

**And none of it runs here.** There is no emulator for Dataplex, for its catalog, for data lineage or
for BigQuery's policy tags, and the command line of lesson 1 has nowhere to send them. This lesson
teaches all four from Google's documentation and marks each command it shows as not run. Two
sections practise something real on your laptop: the arithmetic a data quality rule does, and the
graph a lineage service builds from events. Both say plainly that they are models of the idea, not
the service.

## Three names in three years

**Before anything else, the names, because the documentation you will read uses all of them.** As
far as this lesson knows, the history runs like this:

| | what it was called | what it did |
|---|---|---|
| until about 2024 | **Data Catalog** | a separate service: search over BigQuery and Pub/Sub metadata, tags with templates, and the policy tags of the last section |
| 2024 | **Dataplex Catalog** | the catalog moved inside Dataplex, with a new model of entries and aspects, and Data Catalog was deprecated in its favour |
| 2025 | **Dataplex Universal Catalog** | the name for Dataplex as a whole, catalog first |
| read on 2026-10-30 | **Knowledge Catalog** | the pricing page's heading says "Knowledge Catalog (formerly Dataplex)", and that Dataplex Universal Catalog "has evolved into the Knowledge Catalog" |

The last row is the only one this lesson read with its own eyes, on cloud.google.com/dataplex/pricing,
and that page also says the billing SKUs keep the name Dataplex. The rows above it are what the
author knew before this lesson was written, and the dates are approximate. **The course calls it
Dataplex**, which is the name on the invoice and in the command line, `gcloud dataplex`. Google
announced a date on which Data Catalog's own API stops answering; the deprecation notice in the Data
Catalog documentation has it, and this lesson does not quote it. Products are renamed on their
owner's schedule, and the concepts below outlast the names.

## Lakes, zones and assets

**A lake is a way of drawing boxes around buckets and datasets so they can be governed as groups.**
It is the oldest part of Dataplex, and the one the newer catalog features lean on least, so this
section keeps it short.

- **A lake** is the top box, usually one per domain: Quitanda would have `sales`, holding the orders.
- **A zone** is a box inside it with a type: a **raw** zone for data as it arrived, in any format, and
  a **curated** zone for data that has been cleaned and is held to a schema, Parquet or Avro or a
  BigQuery table.
- **An asset** is one real thing attached to a zone: a Cloud Storage bucket or a BigQuery dataset.

Quitanda's estate maps onto it without strain. `quitanda-raw-prod` is an asset of the raw zone,
`quitanda-curated-prod` and the BigQuery dataset `curated` are assets of the curated zone, and the
lake is `sales`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"The lake sales holds two zones. The raw zone has one asset, the Cloud Storage bucket quitanda-raw-prod, for data as it arrived in any format. The curated zone has two assets, the bucket quitanda-curated-prod and the BigQuery dataset planner-dev.curated.\" data-fig=\"g26-estate\"><rect x=\"16\" y=\"16\" width=\"688\" height=\"236\" rx=\"5\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lake</text><text x=\"62\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sales</text><rect x=\"32\" y=\"50\" width=\"300\" height=\"186\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"46\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">raw zone</text><rect x=\"48\" y=\"86\" width=\"268\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"60\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Cloud Storage bucket</text><text x=\"60\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda-raw-prod</text><text x=\"48\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">data as it arrived,</text><text x=\"48\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in any format</text><rect x=\"352\" y=\"50\" width=\"336\" height=\"186\" rx=\"5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"366\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">curated zone</text><rect x=\"368\" y=\"86\" width=\"304\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"380\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Cloud Storage bucket</text><text x=\"380\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda-curated-prod</text><rect x=\"368\" y=\"154\" width=\"304\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"380\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">BigQuery dataset</text><text x=\"380\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">planner-dev.curated</text><text x=\"32\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lakes and zones are boxes for governing; the assets are the real buckets and datasets, unchanged.</text></svg>", "caption": "Quitanda's estate as one lake with two zones, as this section would set it up. Drawn from the documentation; nothing here created one."}
```

Creating them is three commands, not run, since nothing here reaches Google:

```sh
gcloud dataplex lakes create sales --location=southamerica-east1
gcloud dataplex zones create raw --lake=sales --location=southamerica-east1 \
  --type=RAW --resource-location-type=SINGLE_REGION
gcloud dataplex assets create orders-raw --lake=sales --zone=raw --location=southamerica-east1 \
  --resource-type=STORAGE_BUCKET --resource-name=projects/planner-dev/buckets/quitanda-raw-prod
```

**What a lake buys is two things.** Permissions granted on the lake or the zone reach every asset in
it, so the analysts' group is given the curated zone once instead of each bucket and dataset by
hand. And **discovery** runs over the assets: Dataplex reads the files in a bucket, infers their
schema and partitions, and publishes what it found as tables that BigQuery can query in place, the
external tables of lesson 17. The pricing page says that organising data into lakes, zones and assets
is free, and that discovery runs as jobs billed to the services that run them, not to Dataplex.

**What a lake does not buy is a boundary.** A bucket in a zone is the same bucket, and anybody with
`storage.objects.get` on it through IAM reads it whatever the zone says. Dataplex manages IAM bindings
on the assets for you; it does not replace IAM with a permission system of its own. That is the main
difference from Lake Formation in AWS, which interposes itself between engines and files, and it is
why the column-level rule at the end of this lesson is BigQuery's and not Dataplex's.
