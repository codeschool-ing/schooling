---
title: Connection profiles, a private path and a stream
version: 1
---

**A Datastream stream is three objects, and each answers one question.** A **connection profile**
for the source says how to reach the old database. A connection profile for the destination says
where the changes go. The **stream** says what to copy from one to the other, with or without a
backfill. They are created in that order, because the stream names both profiles. None of this has
an emulator, so **nothing in this section was run against Google**; what was run is the command
line's own help, which knows what a stream may read from:

```
ana@laptop:~/gcp$ gcloud datastream streams create --help | grep -oE -- '--[a-z-]+-source-config' | sort -u
--dataverse-source-config
--mongodb-source-config
--mysql-source-config
--oracle-source-config
--postgresql-source-config
--salesforce-marketing-cloud-source-config
--salesforce-source-config
--servicenow-source-config
--spanner-source-config
--sqlserver-source-config
```

**Ten kinds of source in this command line, and PostgreSQL is one.** Databases, MongoDB, Spanner
and a handful of SaaS products. Every command in this section was checked against the same help,
so the flags exist in this version of `gcloud`; whether a call succeeds is what only Google could
have answered.

## The source, and the path to it

**The source profile names a host, a database, a user and a password, and the password does not
belong on the command line.** A password typed after `--postgresql-password` sits in the shell's
history and in the process list of the machine it was typed on. The profile can instead name a
secret in **Secret Manager**, and Datastream reads the password from there. **Not run here:**

```sh
gcloud datastream connection-profiles create legacy-shop \
  --location=southamerica-east1 --display-name=legacy-shop --type=postgresql \
  --postgresql-hostname=198.51.100.20 --postgresql-port=5432 \
  --postgresql-database=shop --postgresql-username=datastream_reader \
  --postgresql-secret-manager-stored-password=projects/planner-dev/secrets/legacy-shop/versions/latest \
  --private-connection=quitanda-rack
```

**`--private-connection` is the path, and it is the part that takes the longest to build.**
Datastream runs in Google's network, and the shop's database is in a rack in São Paulo with no reason
to be on the internet. A *private connection* peers Datastream with a VPC network of Quitanda's,
and that network reaches the rack over a VPN or an Interconnect, which is `gcp-foundations`'
subject. The help lists two other ways, `--static-ip-connectivity`, where the database's firewall
admits a handful of Google addresses, and `--forward-ssh-hostname`, through a bastion host; both put
the database closer to the internet than a shop's database should be.

**The user is a reader and nothing else.** `datastream_reader` needs the `REPLICATION` attribute, to
read the log through a slot, and `SELECT` on the tables it copies, for the backfill. It needs no
right to write anything, and a CDC user that can write is a user who can change the history the
warehouse is built from.

## The destination

```sh
gcloud datastream connection-profiles create warehouse \
  --location=southamerica-east1 --display-name=warehouse --type=bigquery
```

A BigQuery profile names nothing but its type; the dataset is chosen by the stream. A Cloud Storage
profile names a bucket and a root path, `--bucket=quitanda-raw-prod --root-path=/cdc`, and the
stream writes under it.

## The stream, and the two files it reads

**The source configuration names the slot and the publication**, the two pieces of PostgreSQL the
next section creates by hand. The help shows the fields Datastream expects:

```
ana@laptop:~/gcp$ gcloud datastream streams create --help | grep -E '"(replicationSlot|publication)"'
                    "replicationSlot": "SAMPLE_REPLICATION_SLOT",
                    "publication": "SAMPLE_PUBLICATION"
```

Save Quitanda's as `source.json`, naming the one table this stream follows:

`source.json`:

```json
{
  "includeObjects": {
    "postgresqlSchemas": [
      {"schema": "public", "postgresqlTables": [{"table": "orders"}]}
    ]
  },
  "replicationSlot": "datastream_orders",
  "publication": "datastream_pub"
}
```

And the destination's as `destination.json`, one dataset in São Paulo, merge mode, and at most a
quarter of an hour of staleness:

`destination.json`:

```json
{
  "singleTargetDataset": {"datasetId": "planner-dev:shop_cdc"},
  "merge": {},
  "dataFreshness": "900s"
}
```

**`dataFreshness` is a cost decision as much as a freshness one.** Datastream writes changes into
BigQuery continuously, and BigQuery applies them to the table on a schedule no tighter than this, so
a shorter value means more frequent merges, which BigQuery's change data capture bills on its own
page. Fifteen minutes is fresh for a report and cheap for a merge.

The stream, with a backfill of the one table, **not run here**:

```sh
gcloud datastream streams create shop-orders --location=southamerica-east1 \
  --display-name=shop-orders \
  --source=legacy-shop --postgresql-source-config=source.json \
  --destination=warehouse --bigquery-destination-config=destination.json \
  --backfill-all
```

**Creating a stream does not start it.** A stream is created, validated, and then started with
`gcloud datastream streams update shop-orders --location=southamerica-east1 --state=RUNNING
--update-mask=state`, and
`--validate-only` on the create runs the checks without creating anything: that the profile reaches
the database, that the user may read the log, that the slot and the publication exist. A stream
that fails validation says which of those failed, and the most common answer is the one this lesson
practises next.
