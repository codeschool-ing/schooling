---
title: Unity Catalog: one place to say who may read what
version: 1
---

**Unity Catalog is Databricks' catalogue of tables and the permissions on them, kept above the
workspaces rather than inside one.** It answers the question lesson 6 answered for a container and
lesson 17 for a workspace, at the level of a table, a column or a row: who may read this, and through
which compute. This section is taught from Databricks' and Microsoft's documentation and was not run;
the SQL in it is the shape of the statements, not a transcript.

## Three levels, under a metastore

**Every table has a three-part name, `catalog.schema.table`**, and the levels are where permissions
are granted:

- **the metastore** is the top: one per region, attached to every workspace in that region that uses
  it, so that two workspaces see the same catalogues and the same grants.
- **a catalog** is the first level of the name, usually one per environment or per area of the
  business: `quitanda_prd`, `quitanda_dev`.
- **a schema** groups tables, views, volumes of files and functions: `quitanda_prd.sales`.
- **a table** is the Delta table of lesson 18, with a name: `quitanda_prd.sales.orders`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Unity Catalog drawn as nested boxes. A metastore, one per region, holds the catalog quitanda_prd, which holds the schema sales, which holds the external table orders and the managed table tmp_afternoon; the full name of the first is quitanda_prd.sales.orders, the name a grant names. The external table's files are in an external location, curated at stquitandalakeprd, which uses a storage credential, the access connector dbac-quitanda-prd, which reads the lake, the curated container of stquitandalakeprd.\" data-fig=\"l21-uc\"><defs><marker id=\"l21u-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"420\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">metastore: one per region</text><rect x=\"40\" y=\"54\" width=\"380\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"52\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">catalog</text><text x=\"408\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">quitanda_prd</text><rect x=\"60\" y=\"88\" width=\"340\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"72\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">schema</text><text x=\"388\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">sales</text><rect x=\"240\" y=\"122\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"315\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">external table</text><text x=\"315\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">orders</text><rect x=\"80\" y=\"122\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"155\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">managed table</text><text x=\"155\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">tmp_afternoon</text><text x=\"230\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">quitanda_prd.sales.orders</text><text x=\"230\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the three-part name a grant names</text><rect x=\"470\" y=\"30\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"585\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">external location</text><text x=\"585\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">curated@stquitandalakeprd</text><rect x=\"470\" y=\"110\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"585\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">storage credential</text><text x=\"585\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dbac-quitanda-prd</text><rect x=\"470\" y=\"190\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"/><text x=\"585\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the lake</text><text x=\"585\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">stquitandalakeprd/curated</text><line x1=\"585\" y1=\"76\" x2=\"585\" y2=\"107\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21u-ah)\"/><line x1=\"585\" y1=\"156\" x2=\"585\" y2=\"187\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21u-ah)\"/><line x1=\"390\" y1=\"145\" x2=\"467\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l21u-ah)\"/><text x=\"645\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uses</text><text x=\"595\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads as</text></svg>", "caption": "Names on the left, access on the right. A grant is made on a name; the files are reached through an external location and the connector's identity, never with a key."}
```

**Managed tables and external tables differ in who owns the files.** A managed table's files live in
storage that Unity Catalog chooses and manages, and dropping the table deletes them. An external table
points at a path you manage, in an external location, and dropping it removes the name and leaves the
files. Quitanda's curated orders, written by the nightly job into its own lake, are external; a table
an analyst creates for an afternoon's question is managed, and goes when it is dropped.

## Reaching the lake without a key

**Unity Catalog reads Azure storage as a managed identity, through two objects.** A **storage
credential** wraps the identity of the access connector declared in the third section. An
**external location** pairs a path, such as the curated container of `stquitandalakeprd`, with that
credential, and is itself something permissions are granted on. No storage key is written anywhere,
and a cluster reading the orders table never holds a credential for the account: Unity Catalog checks
the grant, and the access happens through the identity.

## Grants

**Permissions are granted in SQL and inherited downwards.** To let the analysts read the orders, the
analysts need to be allowed into the catalog and the schema, and to select from the table:

```sql
GRANT USE CATALOG ON CATALOG quitanda_prd TO `analysts`;
GRANT USE SCHEMA ON SCHEMA quitanda_prd.sales TO `analysts`;
GRANT SELECT ON TABLE quitanda_prd.sales.orders TO `analysts`;
```

`analysts` is a group, synchronised from Entra ID; granting to groups and never to people is the same
advice `azure-foundations` lesson 9 gives for Azure's own roles. A `SELECT` granted on the schema
instead would reach every table in it, present and future, which is convenient and is also how a new
table of customer addresses becomes readable by the analysts the day it is created.

**Below a table, a row filter and a column mask** let one table show different rows or a masked column
to different groups: the delivery team sees the orders of its region, and only the finance group sees
a customer's tax number unmasked. They are functions attached to the table, and every engine that reads
it through Unity Catalog applies them.

## What it records

**Unity Catalog keeps an audit of who accessed what, and the lineage of tables**: which notebook or job
read which tables to write which, down to the column, captured as the jobs run. Databricks exposes both
as system tables a team can query. Lineage is the question lesson 25's Purview answers across a whole
company; Unity Catalog answers it for everything that runs in Databricks.

**The catalogue is only as complete as what goes through it.** A cluster or a tool that reads the
storage account directly, with a key or a SAS from lesson 6, sees every file and every column, and
Unity Catalog never hears of it. The grants above are a guarantee only once nothing reads the lake
around them, which for Quitanda means taking away every other way in: the account's keys disabled, as
lesson 6 recommends, and the identity of the access connector the only principal with a data role on
the curated container.
