---
title: The fork, and how far it has gone
version: 1
---

In 2008 Sun Microsystems bought MySQL AB. In 2009 Oracle announced it was buying Sun, and Michael
Widenius — who had written the first version of MySQL and named it after his daughter My — forked
the code and started MariaDB, named after his other daughter. That is the whole origin, and it
explains the two things people get wrong about the pair.

**They are not two brands of the same product.** They have been developed separately for fifteen
years by different teams with different priorities.

**They are also not two different databases.** They share an ancestor, a wire protocol, a client,
a dialect and a storage engine, and the overwhelming majority of application code runs on either
without a character changing.

## What is still the same

Every capture in this lesson that was not about `RETURNING` or `GROUP BY` came back identical from
both. The same `CREATE TABLE` loaded into both without an edit. `AUTO_INCREMENT`, `DESCRIBE`,
`SHOW CREATE TABLE`, `||` as OR, `5 / 2` as `2.5000`, the case-insensitive default collation,
InnoDB as the storage engine, DDL committing implicitly — all shared, because all inherited.

The client is shared too: `mysql` connects to a MariaDB server and `mariadb` connects to a MySQL
one, because the protocol is the same. Most drivers list one and speak to both.

## Where they have actually diverged

| | MySQL 8 | MariaDB 10.11 |
|---|---|---|
| `ONLY_FULL_GROUP_BY` by default | yes | **no** |
| `INSERT … RETURNING` | no | **yes**, since 10.5 |
| integer display width | dropped: `int` | kept: `int(11)` |
| JSON | a real `JSON` type with binary storage | an alias for `LONGTEXT` plus functions |
| window functions, CTEs | 8.0 | 10.2 |
| system-versioned tables | no | yes |
| the storage engines on offer | InnoDB | InnoDB, Aria, ColumnStore, others |
| licence of the engine | GPL, plus a commercial edition | GPL only |
| replication | its own, plus Group Replication | its own, plus Galera |

The `DESCRIBE` captures in the last section show the third row without being asked to:
MariaDB printed `int(11)` and MySQL printed `int`. The number was never a width limit — it is a
display hint almost nothing has ever used — and MySQL 8 dropped it while MariaDB kept it. It is
the smallest possible difference and it is a good example of the shape: cosmetic, harmless, and
enough to make a schema diff between the two noisy.

The JSON row is the one that costs. On MySQL a `JSON` column is parsed once and stored in a binary
form, so extracting a field does not re-parse the document. On MariaDB the type name is accepted
and is an alias for `LONGTEXT` with a `CHECK` that it is valid JSON, so the functions work and the
performance characteristics do not match. Code moves; the query plan does not.

## Which to choose, if you are choosing

Most of the time this is not a technical decision, and pretending otherwise wastes the meeting.

**MySQL** if you want the larger installed base, the vendor's managed offering on every cloud, and
the larger pool of people who have operated it. Oracle publishes it under the GPL and there is no
sign of that changing; the discomfort people express is about who owns it rather than about a
licence term anybody can point to.

**MariaDB** if you want an engine under the GPL with no commercial edition behind it, or you want
Galera for multi-primary replication. Or because your Linux distribution ships MariaDB as its
default, which many do, and which is how most people end up on it without ever choosing.

**Neither, if the decision is actually open.** That sounds glib and it is the honest reading of
this lesson so far: if nothing constrains you, the strictness sections are an argument for
PostgreSQL, and the reason to be on MySQL or MariaDB is almost always that you already are.

## Migrating between them

Easy in one direction and getting harder in the other. MariaDB tracked MySQL closely for years, so
moving a MySQL 5.x application to MariaDB is usually a dump and a restore. Going from MariaDB back
to MySQL, or from MySQL 8 forward to MariaDB, meets the table above — the JSON row in particular,
and anything using a MariaDB-only feature like system-versioned tables.

The practical advice is the one from lesson 11's section on what an ORM hides: **know which engine
you are on and write for it.** A schema that carefully avoids everything either engine lacks is a
schema written for a migration that will probably never happen.
