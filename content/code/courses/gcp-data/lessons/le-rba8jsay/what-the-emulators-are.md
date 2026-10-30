---
title: What the emulators are, and where they stop
version: 1
---

**An emulator answers the data plane of one service, and nothing else.** Google Cloud's API has two
halves. The *control plane* is where projects, IAM, networks, billing and the resources themselves
are created: a Cloud SQL instance, a Dataflow job, a BigQuery reservation. The *data plane* is what
those resources do once they exist: store an object, deliver a message, answer a read. Google
publishes emulators for the data plane of four services, and somebody outside Google wrote one for
Cloud Storage. **For the control plane there is no emulator at all**, of any service, from anybody.

That is a short list, and this course is built around what is missing from it rather than hiding
it:

| what | in this lab | what it is |
|---|---|---|
| Cloud Storage | fake-gcs-server 1.54.0 | an open-source imitation of the JSON API, by a person outside Google |
| Pub/Sub | the Pub/Sub emulator, a `gcloud` component | Google's own, a Java program |
| Firestore | the Firestore emulator | Google's own, the one Firebase uses |
| Bigtable | `cbtemulator` | Google's own, in Go, memory only |
| Spanner | the Spanner emulator | Google's own, in C++ |
| BigQuery | **nothing**; DuckDB runs the SQL | no emulator from Google; lesson 13 says what DuckDB stands in for |
| Cloud SQL, AlloyDB, Memorystore | **nothing**; PostgreSQL 16 and Redis 7 run the engine | the engine is real, the managed service around it is absent |
| Dataflow, Dataproc, Composer, Datastream, Dataplex | **nothing**; Apache Beam and Spark run locally where they can | taught from Google's documentation |
| projects, IAM, billing, networks | **nothing** | taught from Google's documentation |

**So each lesson is one of three kinds**, and says which beside every transcript. Some are practised
against an emulator. Some run the open-source engine that the managed service is built on, and say
plainly that what answered was PostgreSQL or Spark and not Cloud SQL or Dataproc. The rest are read:
they show the command you would type against a real project, say that it was not run, and show no
output, because an invented answer would be worse than none.

## What an emulator does not check

Start an empty one, in the other terminal as before, and try the edges:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-emu-demo --location=us-east1
Creating gs://quitanda-emu-demo/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-emu-demo --format='value(location,location_type)'
southamerica-east1	region
ana@laptop:~/gcp$ echo hello > note.txt && gcloud storage cp note.txt gs://quitanda-emu-demo/note.txt
Copying file://note.txt to gs://quitanda-emu-demo/note.txt
  

ana@laptop:~/gcp$ curl -s http://localhost:4443/storage/v1/b/quitanda-emu-demo/o/note.txt?alt=media
hello
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-emu-demo/note.txt --format='value(acl[0].entity)'
projectOwner-test-project
```

Three things happened that Cloud Storage would not do.

**The bucket was asked for in `us-east1` and reports `southamerica-east1`.** fake-gcs-server keeps
no location of its own per bucket: it answers with the one it was started with, the `-location` of
the-lab's fifth block. That is why the lab starts it with São Paulo, so that what it reports is what
this course asks for. A location is a promise about where your data physically lives, and here it
is a string.

**`curl` read the object with no credentials at all.** The emulator checks no signature, no token
and no IAM policy, so every request is allowed. Lesson 4 is about who may read a bucket, and every
refusal in it is taught from the documentation, because nothing here can produce one.

**The object's owner is `projectOwner-test-project`**, and that string is the emulator's signature:
a project called `test-project`, which is not `planner-dev`, invented by fake-gcs-server for every
object it holds. If a describe ever shows you an ACL naming a project of yours, you are not talking
to the emulator.

## The services with nowhere to go

```
ana@laptop:~/gcp$ bq ls
ERROR: (bq) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
ana@laptop:~/gcp$ env -u CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE gcloud storage buckets list
ERROR: gcloud crashed (ConnectionError): HTTPSConnectionPool(host='storage.googleapis.com', port=443): Max retries exceeded with url: /storage/v1/b?alt=json&maxResults=1000&project=planner-dev&projection=full (Caused by NameResolutionError("HTTPSConnection(host='storage.googleapis.com', port=443): Failed to resolve 'storage.googleapis.com' ([Errno -3] Temporary failure in name resolution)"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

**`bq` has no emulator to send to**, so it does what `gcloud` did in the previous section without
`CLOUDSDK_AUTH_DISABLE_CREDENTIALS`: it looks for an account and stops. The second command removed
the endpoint line, and `gcloud` went for `storage.googleapis.com`, the real address. On the machine
these transcripts were recorded on it could not resolve the name, because the recording had no
network. **On yours it would reach Google**, with no credentials, and be refused, since listing a
project's buckets needs an account that may do so. That refusal is the one safety this design
relies on, and it is why the third line of the block matters more than the others: with credentials
disabled, a terminal that has lost its endpoint asks Google as nobody.

## A real account, if you want one

**Nothing in this course needs one**, and no lesson assumes you have one. If you later practise on a
real project, `gcp-foundations` lesson 1 has a section on doing it safely and lesson 12 of that course
is about budgets. Their order of steps is the most valuable thing a real account can teach: a budget with an alert before anything else, a
second factor on the account, and nothing left running. Google's free tier is one way to start, and
neither this course nor that one depends on it.
