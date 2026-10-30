---
title: Three engines and two editions
version: 1
---

**Cloud SQL is one service with three engines inside it, and the engine decides almost everything
that matters to a program**: the SQL dialect, the drivers, the extensions, the port, and whether
there is a licence to pay. What Cloud SQL adds on top is the same for all three. An instance of
PostgreSQL and an instance of SQL Server are created with the same command, backed up the same way
and made highly available the same way, and they cost very different amounts for the same machine.

| engine | `--database-version` | licence on Cloud SQL |
|---|---|---|
| MySQL | `MYSQL_8_0`, `MYSQL_8_4`, … | none, open source under the GPL |
| PostgreSQL | `POSTGRES_16`, `POSTGRES_17`, … | none, open source |
| SQL Server | `SQLSERVER_2022_STANDARD`, … | included in the price, never your own |

The versions are not a matter of memory. The command line carries its own reference, and it lists
every value the flag accepts:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --database-version=/,/^$/p'
     --database-version=DATABASE_VERSION; default="MYSQL_8_0"
        The database engine type and versions. If left unspecified, MYSQL_8_0
        is used. See the list of database versions at
        https://cloud.google.com/sql/docs/mysql/admin-api/rest/v1beta4/SqlDatabaseVersion.
        Apart from listed major versions, DATABASE_VERSION also accepts
        supported minor versions. DATABASE_VERSION must be one of: MYSQL_5_6,
        MYSQL_5_7, MYSQL_8_0, MYSQL_8_4, MYSQL_9_7, POSTGRES_9_6, POSTGRES_10,
        POSTGRES_11, POSTGRES_12, POSTGRES_13, POSTGRES_14, POSTGRES_15,
        POSTGRES_16, POSTGRES_17, POSTGRES_18, POSTGRES_19,
        SQLSERVER_2017_EXPRESS, SQLSERVER_2017_WEB, SQLSERVER_2017_STANDARD,
        SQLSERVER_2017_ENTERPRISE, SQLSERVER_2019_EXPRESS, SQLSERVER_2019_WEB,
        SQLSERVER_2019_STANDARD, SQLSERVER_2019_ENTERPRISE,
        SQLSERVER_2022_EXPRESS, SQLSERVER_2022_WEB, SQLSERVER_2022_STANDARD,
        SQLSERVER_2022_ENTERPRISE, SQLSERVER_2025_EXPRESS,
        SQLSERVER_2025_STANDARD, SQLSERVER_2025_ENTERPRISE.
```

**The default is MySQL**, `MYSQL_8_0`, so an instance created without the flag is a MySQL instance,
whatever the team meant. **Name the version in every command you write**, so that what you created
does not depend on whose default answered. And the list is wider than what Google supports for new
work: versions such as `POSTGRES_9_6` and `MYSQL_5_6` are still accepted, and the pricing page has a
table called "Extended support" that charges extra, per vCPU and hour, for an instance kept on a major
version past the end of its standard support. The last section of this lesson puts a number on it.

**SQL Server's edition is in the version string**: Express, Web, Standard and Enterprise, with no
Web for 2025, and the licence follows the edition. **There is no bring-your-own-licence**: the pricing page says, in a
note, that Cloud SQL does not support BYOL for SQL Server, so the licence is in the hourly price and a
company with SQL Server licences already bought pays again. How to choose among the engines as
databases is `sql-databases` lesson 12; this course takes the choice as made, and Quitanda's orders
are in PostgreSQL.

## Enterprise and Enterprise Plus

**An edition is a level of service, chosen per instance, on top of any of the three engines**:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --edition=/,/^$/p'
     --edition=EDITION
        Specifies the edition of Cloud SQL instance. EDITION must be one of:
        enterprise, enterprise-plus.
```

The differences, as Google's documentation describes them ("Introduction to Cloud SQL editions"):

| | Enterprise | Enterprise Plus |
|---|---|---|
| machines | shared-core, or the vCPU and memory you name | predefined machine types, named by series |
| availability in the SLA | 99.95% | 99.99%, maintenance included |
| planned maintenance | a restart of the engine | a switch Google documents at under a second |
| data cache | none | an SSD cache beside the memory, billed per GiB |
| transaction logs for recovery | up to 7 days | up to 35 days |

**The machines are where the command changes.** The reference says so:

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^        Enterprise Edition: Use --tier/,/C4A series/p'
        Enterprise Edition: Use --tier for shared-core instances (e.g.,
        db-f1-micro, db-g1-small). For dedicated-core instances, do not use
        --tier; instead, customize your instance by specifying its CPU and
        memory with the --cpu and --memory flags.

        Enterprise Plus Edition: --tier is required to specify the predefined
        machine type. The --cpu and --memory flags are not supported for
        Enterprise Plus. Examples include db-perf-optimized-N-2 (N2 series) or
        db-c4a-highmem-2 (C4A series).
```

**On Enterprise, a machine is two numbers**: `--cpu=2 --memory=8GiB`, or a shared-core tier such as
`db-f1-micro` for a database nobody depends on. **On Enterprise Plus, a machine is a name**:
`db-perf-optimized-N-2` is two vCPU on the N2 series with 16 GiB of memory, eight per vCPU, and the
two numbers are refused. The section on cost shows what that ratio does to the price.

**Which one for Quitanda's orders?** The orders database takes money: a lost hour of it is a lost
hour of sales. The difference between 99.95% and 99.99% is about 22 minutes against 4 in a month of
730 hours, and the maintenance that Enterprise counts outside its SLA is inside Enterprise Plus's. A
company can reasonably pay for that on the orders and refuse it on the reporting copy. The rest of
this lesson uses Enterprise, because it is the cheaper of the two and the arithmetic is easier to
follow; lesson 7 makes it highly available, which is a separate decision from the edition.

AlloyDB, Google's own PostgreSQL-compatible engine with a storage layer of its own, is not on this
list, and Spanner is not either; lesson 8 places AlloyDB between Cloud SQL and Spanner, and lesson 9
is Spanner.
