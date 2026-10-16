---
title: Five engines, a sixth, and who pays for the licence
version: 1
---

**RDS is one service with several engines inside it, and the engine decides almost everything that
matters to a program**: the SQL dialect, the drivers, the extensions, the port, and whether there is
a licence to pay. What RDS adds on top is the same for all of them. An instance of PostgreSQL and an
instance of SQL Server are created with the same command, backed up the same way and failed over the
same way, and they cost very different amounts for the same machine.

| engine | `--engine` | licence on RDS |
|---|---|---|
| PostgreSQL | `postgres` | none, it is open source |
| MySQL | `mysql` | none, open source under the GPL |
| MariaDB | `mariadb` | none, open source under the GPL |
| Oracle | `oracle-se2`, `oracle-ee` | Standard Edition 2 included in the price or your own; Enterprise only your own |
| SQL Server | `sqlserver-ex`, `-web`, `-se`, `-ee` | included in the price |
| Db2 | `db2-se`, `db2-ae` | your own, from IBM |

**Db2 is the sixth, and the newest**: IBM's database, added to RDS in 2023, mostly for companies
moving a Db2 they already run. Aurora is not on this list, because it is not an engine RDS runs on an
ordinary volume; it is AWS's own storage underneath a PostgreSQL or MySQL that speaks the same protocol,
and lesson 8 is about it. How to choose among the engines as databases is `sql-databases` lessons 12
and 13; this course takes the choice as made, and Quitanda's orders are in PostgreSQL.

## Licence included, or bring your own

**"Licence included" means the hourly price contains the vendor's licence**, and AWS pays the vendor.
You need no contract with Microsoft or Oracle and no count of cores, and you pay for it every hour the
instance runs, which the last section of this lesson puts a number on. **"Bring your own licence"** means
the hourly price is only AWS's, and you must already hold a licence that covers the cores the instance
runs on, under the vendor's rules for clouds, which are theirs to write and to audit. Oracle Enterprise
Edition is offered only that way, which is why a company moving an Oracle EE database to RDS has a
conversation with Oracle's licensing team before it has one with AWS.

## What moto knows about engines

**On a real account, the first question is which versions exist**, and it has a command:

```
ana@laptop:~/aws$ aws rds describe-db-engine-versions --engine postgres

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**That is a crash, not an answer.** The command line expected XML and got an HTML error page, which
is how a server written in Python says it raised an exception. In the other terminal, the one running
moto, the traceback ends in a line that names the reason, `NotImplementedError: The
describe_db_engine_versions action has not been implemented`. moto has not written that action. On AWS, `describe-db-engine-versions --engine postgres` lists every
PostgreSQL version RDS offers in the region, with its parameter group family and what it can be
upgraded to; it was not run here. Creating an instance without naming a version shows what moto does
instead:

```
ana@laptop:~/aws$ for e in postgres mysql oracle-se2 sqlserver-se; do aws rds create-db-instance --db-instance-identifier try-$e --engine $e --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query "DBInstance.[Engine,EngineVersion,Endpoint.Port,LicenseModel]" --output text; done
postgres	9.3.3	5432	general-public-license
mysql	5.6.21	3306	general-public-license
oracle-se2	11.2.0.4.v3	1521	general-public-license
sqlserver-se	11.00.2100.60.v1	1433	general-public-license
```

**Every one of those defaults is a version AWS stopped offering years ago.** PostgreSQL 9.3, MySQL 5.6,
Oracle 11.2 and SQL Server 2012, whose internal version number is `11.00`: moto chose a default once
and nobody moved it. AWS picks the current default version for an engine when none is named, so the
same command on a real account would have created something different. And the licence column says
`general-public-license` for Oracle and for SQL Server, which is true of neither; moto fills the field
and does not reason about it. **Name the version and the licence in every command you write**, so that
what you created does not depend on whose default answered.

MariaDB is where moto's defaults run out entirely, and Oracle Enterprise and Db2 are the licence
column's two extremes:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-mariadb --engine mariadb --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.EngineVersion'

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-mariadb --engine mariadb --engine-version 11.4 --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.[Engine,EngineVersion,Endpoint.Port,LicenseModel]' --output text
mariadb	11.4	3306	general-public-license
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-oracle-ee --engine oracle-ee --license-model bring-your-own-license --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.[Engine,LicenseModel]' --output text
oracle-ee	bring-your-own-license
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-db2 --engine db2-se --license-model bring-your-own-license --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password

aws: [ERROR]: An error occurred (InvalidParameterValue) when calling the CreateDBInstance operation: Value db2-se for parameter Engine is invalid. Reason: engine db2-se not supported
```

**With no version, moto fell over again; with one, it worked.** The `oracle-ee` instance was accepted
under `bring-your-own-license`, which is the only way AWS sells it. And `db2-se` is refused as an engine
moto does not support, which is a statement about moto: on AWS it is a valid engine, and the request
would have gone on to check the licence. Three results, three different reasons, and only one of them
is AWS's behaviour. That ratio is why this course reads the AWS documentation beside every RDS command
it runs.
