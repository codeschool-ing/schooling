---
title: An instance, a database and a schema, in the emulator
version: 1
---

**A Spanner database lives inside an instance, and the instance is where the money is.** The instance
is the compute capacity, measured in nodes or processing units, and a configuration that says where
its copies of the data live: one region, two, or several. Databases are created inside it and share
its capacity, and tables are created inside a database by its schema. That is three layers where
Cloud SQL and AlloyDB had a server and its databases, and the reason is the subject of this lesson:
the instance is not a machine but a slice of a fleet, which can grow by adding more of it.

**This section and the next three are practised on the Spanner emulator**, the one Google ships with
the command line, which lesson 1 installed as `cloud-spanner-emulator`. It is a program that speaks
Spanner's API on your laptop and keeps everything in memory. It runs your schema, your SQL and your
transactions, and it does not run Spanner: there is one process, no replicas, no splits and nothing
to measure. The last section of this lesson lists what that leaves out, with the transcripts that
show it. **The emulator is published for x86-64 Linux only**, as lesson 1 said, so on an Arm machine
this lesson is read rather than practised.

## The emulator, in a terminal of its own

```sh
cd ~/gcp && export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud emulators spanner start
```

**It answers on two ports**: 9010 for gRPC, which the Python client uses through `SPANNER_EMULATOR_HOST`,
and 9020 for REST, which `gcloud` uses through `CLOUDSDK_API_ENDPOINT_OVERRIDES_SPANNER`. Both
variables are set by lesson 1's "Every time you open a terminal". Leave it running and type the rest
in your other terminal.

## An instance

**An instance needs a configuration, and the emulator has exactly one:**

```
ana@laptop:~/gcp$ gcloud spanner instance-configs list
NAME             DISPLAY_NAME              FREE_INSTANCE_AVAILABILITY
emulator-config  Emulator Instance Config
```

**On Google Cloud the list is long**: `regional-southamerica-east1` for São Paulo, dual-region and
multi-region names such as `nam-eur-asia1`, each a placement of replicas with a price. Here every
instance is created with `--config=emulator-config`, and the capacity is given in processing units:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda --config=emulator-config --description="Quitanda shop" --processing-units=100
Creating instance...
.....done.
ana@laptop:~/gcp$ gcloud spanner instances list
NAME      DISPLAY_NAME   CONFIG           NODE_COUNT  PROCESSING_UNITS  STATE  INSTANCE_TYPE
quitanda  Quitanda shop  emulator-config              100               READY
```

**100 processing units is the smallest instance Spanner sells**, a tenth of a node, and the
`PROCESSING_UNITS` column says so. `--processing-units` and `--nodes` are two names for one setting:
1,000 processing units are 1 node. Below 1,000 the steps are of 100, and above it they are whole
nodes, and the emulator enforces that rule with Spanner's own sentence:

```
ana@laptop:~/gcp$ gcloud spanner instances create quitanda-test --config=emulator-config --description="A test" --processing-units=150
ERROR: (gcloud.spanner.instances.create) HTTPError 400: {"code":3,"message":"Invalid CreateInstance request. Processing units should be multiple of 100 for values below 1000 and multiples of 1000 for values above 1000."}
```

## A schema

**A Spanner schema is DDL**, much like the `CREATE TABLE` of `sql-databases`, with three things that
are Spanner's own: every table names its `PRIMARY KEY` after the column list, a table can be
`INTERLEAVE`d in another, and a sequence can be bit-reversed. The next three sections are about those
three, and this file is the whole of Quitanda's shop database for this lesson.

`schema.sql`:

```sql
CREATE SEQUENCE OrderSeq OPTIONS (sequence_kind = 'bit_reversed_positive');

CREATE TABLE Customers (
  CustomerId STRING(36) NOT NULL,
  Name       STRING(MAX) NOT NULL,
  District   STRING(MAX),
) PRIMARY KEY (CustomerId);

CREATE TABLE Orders (
  CustomerId STRING(36) NOT NULL,
  OrderId    INT64 NOT NULL DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderSeq)),
  Day        DATE NOT NULL,
  TotalCents INT64 NOT NULL,
) PRIMARY KEY (CustomerId, OrderId),
  INTERLEAVE IN PARENT Customers ON DELETE CASCADE;

CREATE TABLE Stock (
  Product STRING(MAX) NOT NULL,
  Units   INT64 NOT NULL,
) PRIMARY KEY (Product);

CREATE TABLE ByCounter (Id INT64 NOT NULL) PRIMARY KEY (Id);
CREATE TABLE ByUuid (Id STRING(36) NOT NULL DEFAULT (GENERATE_UUID())) PRIMARY KEY (Id);
CREATE TABLE BySequence (Id INT64 NOT NULL DEFAULT (GET_NEXT_SEQUENCE_VALUE(SEQUENCE OrderSeq))) PRIMARY KEY (Id);
```

**`Customers`, `Orders` and `Stock` are the shop.** `ByCounter`, `ByUuid` and `BySequence` are three
tables with nothing but a key, one of each kind the next section compares. `STRING(36)` is the length
of a UUID written out, and `STRING(MAX)` is a string with no declared limit. Money is `INT64` cents,
as everywhere in this course.

```
ana@laptop:~/gcp$ gcloud spanner databases create shop --instance=quitanda --ddl-file=schema.sql
Creating database...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases ddl describe shop --instance=quitanda | grep -c 'CREATE TABLE'
6
```

**The database exists and holds six tables and a sequence**, created in one schema change. On
Google Cloud a schema change is a long-running operation, and adding an index to a large table takes
time the emulator never needs.

## Rows, with the command line

Three rows to work with, a customer and two products:

```
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Customers --data=CustomerId=c-17,Name=Ana,District=Lapa
commitTimestamp: '2026-10-30T18:46:45.832858Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Stock --data=Product=banana,Units=10
commitTimestamp: '2026-10-30T18:46:46.625355Z'
ana@laptop:~/gcp$ gcloud spanner rows insert --instance=quitanda --database=shop --table=Stock --data=Product=rice-5kg,Units=30
commitTimestamp: '2026-10-30T18:46:47.294626Z'
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop --instance=quitanda --sql='SELECT Product, Units FROM Stock ORDER BY Product'
Product   Units
banana    10
rice-5kg  30
```

**`rows insert` returns the commit timestamp** and nothing else. Every write in Spanner is committed at
a timestamp, and the fifth section of this lesson reads the database as it was at one of them. The
`execute-sql` that follows is a query in GoogleSQL, Spanner's default dialect, and answers as any SQL
database would.

## The other dialect

**A database is created in one of two dialects, and stays in it.** GoogleSQL is the default, and the
one this lesson uses. The other is PostgreSQL's, chosen with `--database-dialect=POSTGRESQL`, which
lets an application keep PostgreSQL's spelling of DDL, types and SQL:

```
ana@laptop:~/gcp$ gcloud spanner databases create shop-pg --instance=quitanda --database-dialect=POSTGRESQL
Creating database...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop-pg --instance=quitanda --ddl='CREATE TABLE customers (customer_id varchar(36) NOT NULL PRIMARY KEY, name text NOT NULL)'
Schema updating...
.....done.
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql="INSERT INTO customers (customer_id, name) VALUES ('c-17', 'Ana')"
Statement modified 1 row
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql='SELECT customer_id, name FROM customers'
customer_id  name
c-17         Ana
```

**`varchar`, `text` and a `PRIMARY KEY` written inside the column list** are PostgreSQL's spelling,
and the database accepted them. What it is underneath is still Spanner, which is lesson 8's warning
in a transcript of its own:

```
ana@laptop:~/gcp$ gcloud spanner databases execute-sql shop-pg --instance=quitanda --sql='SELECT version()'
ERROR: (gcloud.spanner.databases.execute-sql) HTTPError 501: {"code":12,"message":"Postgres function version() is not supported"}
ana@laptop:~/gcp$ gcloud spanner databases ddl update shop-pg --instance=quitanda --ddl='CREATE EXTENSION pg_trgm'
ERROR: (gcloud.spanner.databases.ddl.update) HTTPError 400: {"code":9,"message":"Statement is not supported."}
```

**`version()` is not supported, and neither is `CREATE EXTENSION`.** The PostgreSQL dialect is a
dialect, the grammar and the types and many of the functions; it is not a PostgreSQL server, and the
catalogue of extensions an application may lean on is not there. A program written for Cloud SQL or
AlloyDB that moves to it is reviewed query by query, and the keys and interleaving of the next two
sections apply in both dialects alike. Both refusals come from the emulator, which follows Spanner's
list of what each dialect supports; what the list holds on a given day is Spanner's documentation,
"PostgreSQL interface", to check.
