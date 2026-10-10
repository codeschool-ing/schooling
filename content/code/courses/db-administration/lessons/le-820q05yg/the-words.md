---
title: The words, and the traps in them
version: 1
---

The parts are the same; **the words for how data is grouped are not**, and that is where a DBA
moving between engines gets lost. The same word, `database`, names a different level in each one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"Four columns, one per engine, each a stack of nested boxes. PostgreSQL: cluster, database, schema, table. MySQL: server, then database, which is the same thing as a schema, then table. SQL Server: instance, database, schema, table. Oracle: container database, pluggable database, schema, which is the same thing as a user, then table.\"><text x=\"93.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">PostgreSQL</text><rect x=\"10\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cluster</text><rect x=\"22\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">database</text><rect x=\"34\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">schema</text><rect x=\"46\" y=\"148\" width=\"94\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"93.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text><text x=\"271.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">MySQL</text><rect x=\"188\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><rect x=\"200\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">database = schema</text><rect x=\"212\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text><text x=\"449.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">SQL Server</text><rect x=\"366\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">instance</text><rect x=\"378\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">database</text><rect x=\"390\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">schema</text><rect x=\"402\" y=\"148\" width=\"94\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"449.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text><text x=\"627.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">Oracle</text><rect x=\"544\" y=\"52\" width=\"166\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CDB</text><rect x=\"556\" y=\"84\" width=\"142\" height=\"166\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PDB</text><rect x=\"568\" y=\"116\" width=\"118\" height=\"102\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">schema = user</text><rect x=\"580\" y=\"148\" width=\"94\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"627.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">table</text></svg>", "caption": "What contains what. The outer box is one running server in every engine; the words for the levels inside it are where the confusion starts."}
```

**In PostgreSQL** one server is a **cluster**. It holds several **databases**, and a connection is
always to exactly one of them: a query cannot join a table in `shop` to a table in `ana`. Inside a
database are **schemas**, namespaces for tables, and a query can join across them freely.

**In MySQL** there is no level between the server and the tables. What MySQL calls a `DATABASE` is,
by every other engine's meaning, a schema, and the two words are synonyms there: `CREATE SCHEMA`
creates a database. A query can join tables in two of them, because they are namespaces on one
server and not separate databases at all.

**In SQL Server** an **instance** holds **databases** and each database holds **schemas**, the same
shape as PostgreSQL. The difference is in the people: a **login** is an account on the instance,
and a **user** is that login's identity inside one database. Somebody can log in and still be
refused by a database in which their login has no user.

**In Oracle** the **schema** and the **user** are one thing: creating a user creates an empty schema
of the same name, and a table belongs to the user who owns it. Since version 12 an Oracle database
can be a **container** (CDB) holding several **pluggable databases** (PDBs), which is the level that
behaves like a PostgreSQL database.

## The same table, four addresses

| engine | how a query names it |
|---|---|
| PostgreSQL | `billing.invoices`, from a connection to the right database |
| MySQL | `billing.invoices`, from any connection, where `billing` is a database |
| SQL Server | `shop.billing.invoices` — database, schema, table — or `billing.invoices` inside `shop` |
| Oracle | `billing.invoices`, where `billing` is the user who owns it |

**When somebody says "the database", ask which level they mean.** A request to "create a database for
the new service" means a new database on PostgreSQL, a new database (that is, a schema) on MySQL,
and on Oracle most likely a new user. Getting it wrong is not a disaster, but it decides what can be
backed up, restored and granted separately, which lessons 12 and 20 are about.
