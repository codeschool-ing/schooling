---
title: By database, and what sharing tables costs
version: 1
---

The most tempting integration in any company is the one that needs nobody's permission. The data is
already in a database, the database accepts connections, and a query takes ten minutes to write. No
file layout to agree, no service to ask for, no ESB flow to wait for. **Reading another system's
tables looks like the simplest integration there is, and it is the one whose cost arrives last and
largest.**

Hohpe and Woolf describe the shared database as a design: several applications agree on one schema
and all use it, so there is never any data to move. That version is rare, because agreeing one schema
across a finance system, a CRM and a route planner is harder than moving data between them. What
Joana's map found instead were 17 database links in two disguises: 5 integration tables, and 12 places
where one system simply reads another's tables, 7 of them reports.

## The integration table

Rota uses a table to tell SAP which trips the contracted trucks have made, so that SAP can pay
their owners. Rota writes each finished trip as a row in a small SQL Server database, with a status
of `N` for new. Every five minutes an ABAP job connects to that database, reads the `N` rows, records
each trip in SAP for payment, and sets the status to `P` for processed, or `E` with a message if SAP
refused it.

That is a reasonable design, and it is worth seeing why: **an integration table is a queue built out
of a table**. Rota does not need SAP to be up when a truck comes back; the trip waits in the table.
The format is a table the two teams designed together for this purpose, so neither side's internal
model leaks into it. It is closer to a file or a message than to reading somebody's tables.

It also has a queue's problems without a queue's tools, and the map found all of them:

- **Nobody watches the error rows.** On the morning Joana looked, 37 rows sat in status `E`, the oldest
  nine days old. Each one was a trip somebody expected to be paid for.
- **Polling is a latency and a load.** Every five minutes, whether anything arrived or not, the job
  queries the table; and a trip closed at 10:01 waits until 10:05.
- **Two writers update one row.** Rota can still correct a trip the job is reading, and the status column is the only
  thing standing between them. A job that crashes between recording the trip in SAP and setting `P`
  will record the same trip again on its next run, which is the double load
  of the previous section in another form.

A broker gives you error queues, alarms on depth and delivery without polling, and lesson 10 is about
what it does. An integration table is what people build when there is no broker, or when nobody
thought to use the one there is.

## Just reading their table

The second disguise has no design at all. Rota, the route planner, needs to know every farm: where it is and which days it is collected. That data lives in Coleta, on IBM i, so when
Rota was built in 2022 the team connected to Coleta's database over ODBC and read the farm table
directly, every night at 21:00. It took a day to build.

In 2023 Sebastião added GPS coordinates to the farm records, and to do it he split the address field
into two. **Nothing told Rota.** On the Sunday night after the change, Rota's query failed, the
route plan was not produced, and the dispatchers planned the Monday's 140 truck routes by hand from
the previous week's printout.

That is the failure in its loud form, and it was the lucky one. The quiet form is a change of
*meaning* with no change of shape. If Coleta started marking a farm suspended with a new status value
instead of deleting it, Rota's query would keep running, keep returning rows, and keep sending trucks
to a farm that has stopped supplying. **Reading a table couples you to everything the owner means by
it, including what they decide it means next year**, and they do not know you are there.

Three costs come with every direct read:

1. **The schema becomes an interface nobody agreed to.** The owner cannot change a column without
   breaking somebody they have never heard of, so after a few years nobody changes anything, and the
   system's design freezes around readers it never chose.
2. **The load and the locks are the owner's problem.** A report that scans a year of collection data
   runs on the same database as the lab technicians typing in test results. At Serra Alta one such
   report, refreshed every morning at 07:00, made Coleta's screens slow for twenty minutes a day for a
   year before anybody connected the two.
3. **The rules are skipped.** Reading skips the application's view of the data: whatever it filters,
   corrects or combines before showing it. Writing skips its validation entirely, which is why no
   system should ever write into another's tables.

## Why SAP's tables are off limits

Every one of those costs is larger with an ERP. SAP's tables are designed for SAP's own programs, with
meanings spread across configuration: whether a row in a table counts as an open item can depend on
settings in three other tables. Lesson 1 told the story of indirect access and the licensing dispute
behind it, and lesson 2 shows the supported ways in. Here the point is the architectural one.

**The vendor changes its tables when it upgrades, and you do not get a vote.** Serra Alta must move
off ECC by the end of 2027. S/4HANA moved material documents, which ECC kept in a header and an item
table, into a single new table, `MATDOC`, and keeps the old table names only as compatibility views. A
report that read the old tables directly now reads views SAP kept so that old programs would not
break, and how long a compatibility view lasts is SAP's decision. **Every direct read of SAP's tables
is a line on the migration plan**, and Joana's map found seven: two Power BI reports, four ABAP
programs in other systems' landscapes, and one Excel workbook with a database connection that
finance refreshes every Monday.

Joana's first proposal at Serra Alta, in lesson 1, was a direct read of exactly this kind: the Portal
B2B reading SAP's stock tables from a read replica. A replica fixes the second cost, the load, and
leaves the first and the third where they were.

## Change data capture

There is a modern variant that keeps what is good about reading the database and removes some of
what is bad: **change data capture**, CDC. Instead of querying the tables, a CDC tool reads the
database's own log of changes, the log it writes for recovery: the write-ahead log in PostgreSQL, the
binary log in MySQL, the journal on IBM i. Every committed insert, update and delete comes out of the
log in commit order, and the tool publishes each one as a message.

Debezium is the open-source example most people meet. It reads the log of a PostgreSQL, MySQL, SQL
Server or several other databases and publishes every row change as an event, usually to Kafka.

CDC removes two of the three costs and reduces the third:

- **No load on the tables.** The log is written anyway; reading it does not scan or lock a table the
  application is using.
- **No polling and nothing missed.** Every change arrives, in order, including deletes, which a query
  that looks for new rows never sees.
- **The schema is still the contract.** A CDC event is a row: the table's columns, before and after.
  When Sebastião splits the address field, the events change shape exactly as the table did. CDC moves
  the coupling to a better place, it does not remove it.

That last point is why CDC is usually the first half of something. The row events go to a small
translator that turns them into events about the business, like *farm 017605 was suspended*, and the
translator is the only code that knows the table. Lesson 13 uses exactly this to keep Coleta and its
replacement in step while both run, and lesson 11 names the translator.

## When sharing a database is fine

Two systems that share a database are one system in disguise, for better or worse. Inside one team's
application, behind one owner, a database used by three of that team's programs is not an integration
at all: it is a design decision inside a boundary, and the owner can change the schema because the
owner knows every reader. **The test is ownership: a database shared across owners is an interface
nobody designed.** If you must read one, ask the owner, write the reader down on the map, and tell
the owner which columns you depend on, so that the next change to them is a conversation rather than
a Monday morning of routes planned by hand.
