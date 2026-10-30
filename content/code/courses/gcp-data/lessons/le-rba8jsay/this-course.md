---
title: What this course is, and what it assumes
version: 1
---

**This course is about where data lands on Google Cloud, where it lives, and where it is asked
questions**, and about the bill each of those choices writes. It follows the data of one company,
Quitanda, a grocery delivery service in São Paulo: the files its shop exports every night, the
database its orders live in, the clicks its app sends every second, and the warehouse its analysts
query.

It runs in six parts:

| lessons | what | the question each part answers |
|---|---|---|
| 1 to 5 | Cloud Storage | where a file lives, how long, who can read it, and what reading it costs |
| 6 to 9 | Cloud SQL, AlloyDB and Spanner | three answers to "I need a relational database", and what each one charges for |
| 10 to 12 | Firestore, Bigtable and Memorystore | a store designed around its queries, and the cache in front of everything |
| 13 to 18 | BigQuery | the warehouse, and the two decisions that set what a query costs |
| 19 to 22 | Pub/Sub and Dataflow | data that never stops arriving, late and out of order, and what "delivered" means |
| 23 to 27 | Dataproc, Composer, Datastream, Dataplex, and the choice | the jobs that run at night, the database you copy from, the map of it all, and how to choose the store |

**It assumes two courses.** From `gcp-foundations`, the resource hierarchy and projects, IAM's
principals and roles, regions and zones, and the `gcloud` command line itself. From `sql-databases`,
the relational vocabulary: a table, a primary key, an index, a transaction. A lesson that leans on
either says which lesson of which course, and none of them explains an IAM role or a `JOIN` from
the beginning.

## Three kinds of lesson

**Google Cloud cannot be imitated whole on a laptop, and this course does not pretend it can.** The
section on what the emulators are, later in this lesson, sets out exactly what answers in your lab. The consequence for the lessons is
that each section is one of three kinds:

- **practised against an emulator**, where Google or somebody else publishes one: Cloud Storage,
  Pub/Sub, Firestore, Bigtable and Spanner;
- **practised against the engine underneath**, where the managed service is built on open-source
  software you can run: PostgreSQL for Cloud SQL and AlloyDB, Redis for Memorystore, Apache Beam for
  Dataflow, Spark for Dataproc, and DuckDB running SQL over the files BigQuery would read;
- **read**, where nothing local answers: creating an instance, a reservation, a cluster or a job,
  and everything about projects, IAM and billing. A read section shows the command and says that it
  was not run, and never shows an answer it did not get.

Every transcript in a fence was recorded on the lab the next section builds, and you can reproduce
it there. What you cannot reproduce is marked where it appears.
