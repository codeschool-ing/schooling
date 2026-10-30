---
title: Requester Pays, and who the bill goes to
version: 1
---

**By default the project that owns a bucket pays for everything done to it, including by others.** A
partner in `us-east1` who copies Quitanda's 5 TiB of order history, with access Quitanda granted,
moves 5 TiB out of Latin America, and the 716.80 of the previous section lands on Quitanda's bill.
**Requester Pays** is the bucket setting that moves most of the meters to whoever asks.

On a bucket with Requester Pays on, as Google's documentation describes it (cloud.google.com, "Requester
Pays", in the Cloud Storage guides):

- **the requester pays for the operations, the network transfer and the retrieval fees**; the owner
  keeps paying for storage, and for the early deletion of lesson 2;
- **every request must name the project to bill**: `userProject` as a parameter in the JSON API,
  the header `x-goog-user-project` in the XML API, `--billing-project` on the command line. A request
  that names none is refused with HTTP 400;
- **the caller needs permission to bill that project**, `serviceusage.services.use` on it, so a
  request with no Google identity behind it has nothing to bill and cannot read the bucket. A
  Requester Pays bucket cannot also be a public one in the sense of lesson 4.

It fits data shared with other companies that read it on their own schedule: a dataset sold to
partners, or a research dataset whose owner pays only to keep it. It does not fit anything Quitanda's
own teams read, since the charges would move from one of Quitanda's projects to another and nothing
would be saved; that split is the billing export of `gcp-foundations` lesson 14, done with labels.

## In fake-gcs-server

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ printf 'order_id,customer_id,total_cents\nord-01-1,c-17,4590\n' > history.csv && gcloud storage cp --no-user-output-enabled history.csv gs://quitanda-curated-prod/shared/history.csv
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-curated-prod --requester-pays --log-http 2>&1 | grep -A1 '^== body start'
== body start ==
{"billing": {"requesterPays": true}, "name": "quitanda-curated-prod"}
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-curated-prod --format=json | grep -c -i requester
0
ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-curated-prod/shared/history.csv
order_id,customer_id,total_cents
ord-01-1,c-17,4590
```

**`--log-http` shows the request `gcloud` sent**, and it is the right one: a `PATCH` of the bucket
with `{"billing": {"requesterPays": true}}`, the field the JSON API documents. **fake-gcs-server
accepted it and kept nothing.** The description afterwards has no line mentioning it, where Cloud
Storage would print `requester_pays: true`, and a read that names no billing project succeeded, where
Cloud Storage refuses it. The emulator of this course does not implement the setting.

What it can show is the request a client sends when it does name a project, which is the half of
Requester Pays that is the reader's job:

```
ana@laptop:~/gcp$ gcloud storage cat --billing-project=planner-dev gs://quitanda-curated-prod/shared/history.csv --log-http 2>&1 | grep -c -i 'x-goog-user-project'
0
ana@laptop:~/gcp$ : > requests.log
ana@laptop:~/gcp$ python3 -c 'from google.cloud import storage; b = storage.Client().bucket("quitanda-curated-prod", user_project="planner-dev"); print(b.blob("shared/history.csv").download_as_text(), end="")'
order_id,customer_id,total_cents
ord-01-1,c-17,4590
ana@laptop:~/gcp$ grep -o 'GET /download[^ ]*' requests.log
GET /download/storage/v1/b/quitanda-curated-prod/o/shared%2Fhistory.csv?alt=media&userProject=planner-dev
```

**`gcloud` sent no billing project here, and the reason is this lab.** It puts the
`X-Goog-User-Project` header beside the credentials it attaches to a request, and the third line of
lesson 1's "Every time you open a terminal" told it to attach none. On a real project, with
credentials, the same command carries the header. **The Python client puts it in the address
instead**, `userProject=planner-dev`, which is the emulator's log line above, and which is what a
Requester Pays bucket reads to decide whose bill the download goes on.

So nothing of Requester Pays was enforced here. What it does to a bill is the arithmetic of the
previous sections with the payer changed: the partner's 5 TiB copy to `us-east1` costs 716.80 whoever
pays, and the setting decides which project's invoice carries it.
