---
title: An instance, not a database
version: 1
---

**Azure SQL Managed Instance rents you a whole instance of SQL Server, where Azure SQL Database rents
you one database.** The engine is the same. What changes is the boundary: inside an instance, many
databases sit side by side, a query can name two of them, SQL Agent runs jobs on a schedule, and logins
belong to the instance rather than to one database. Everything lesson 8 listed under "there is no
instance" is here again, and still run, patched and backed up by Microsoft.

**This section is taught from Microsoft's documentation, and nothing in it was run against Azure.** The
two after it run the instance features themselves, on the SQL Server in the container, which is a whole
instance too.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two boundaries side by side. On the left, Azure SQL Database: a logical server holding two databases, quitanda and delivery, each in its own box; a query from quitanda naming delivery.dbo.deliveries is refused, and there is no SQL Agent. On the right, SQL Managed Instance, inside a subnet of the company's virtual network: one instance box holding the databases quitanda, delivery and msdb, with SQL Agent running jobs from msdb, a query from quitanda reading delivery directly, and a linked server reaching out to another SQL Server.\" data-fig=\"l09-boundary\"><defs><marker id=\"arr-l09-boundary-phosphor\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"arr-l09-boundary-wire\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"30\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Azure SQL Database</text><rect x=\"20\" y=\"40\" width=\"300\" height=\"220\" rx=\"10\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><text x=\"34\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">logical server</text><rect x=\"40\" y=\"90\" width=\"110\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">quitanda</text><rect x=\"190\" y=\"90\" width=\"110\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">delivery</text><line x1=\"150\" y1=\"125\" x2=\"186\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"3 3\"></line><line x1=\"162\" y1=\"144\" x2=\"174\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></line><line x1=\"174\" y1=\"144\" x2=\"162\" y2=\"156\" stroke=\"var(--amber)\" stroke-width=\"1.8\"></line><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refused</text><text x=\"170\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no SQL Agent</text><text x=\"380\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">SQL Managed Instance</text><rect x=\"370\" y=\"40\" width=\"330\" height=\"250\" rx=\"10\" fill=\"none\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></rect><text x=\"384\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your subnet</text><rect x=\"385\" y=\"70\" width=\"300\" height=\"160\" rx=\"8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"397\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instance</text><rect x=\"400\" y=\"100\" width=\"85\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">quitanda</text><rect x=\"500\" y=\"100\" width=\"85\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">delivery</text><rect x=\"600\" y=\"100\" width=\"70\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">msdb</text><line x1=\"485\" y1=\"125\" x2=\"496\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l09-boundary-phosphor)\"></line><rect x=\"590\" y=\"175\" width=\"90\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SQL Agent</text><line x1=\"635\" y1=\"175\" x2=\"635\" y2=\"154\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l09-boundary-phosphor)\"></line><path d=\"M 442 150 L 442 255 L 470 255\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#arr-l09-boundary-wire)\"></path><text x=\"476\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">linked server</text><text x=\"476\" y=\"263\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">another SQL Server</text></svg>", "caption": "Azure SQL Database draws the boundary around each database, so a three-part name has nowhere to go; Managed Instance draws it around the instance, and the old habits work again."}
```

## What the boundary changes

| | Azure SQL Database | SQL Managed Instance |
|---|---|---|
| what you rent | one database, or a share of a pool | an instance holding many databases |
| a query naming another database | refused | allowed, by its three-part name |
| SQL Agent | absent; elastic jobs are the replacement | present, with `msdb` and its job history |
| linked servers | absent | to other SQL Servers and to Azure SQL |
| CLR, Service Broker, Database Mail | absent | present |
| `RESTORE` of a `.bak` file | absent; backups are the service's own | from Blob Storage, by its URL |
| where it answers | a public endpoint behind a firewall, or a private endpoint | inside your virtual network |
| `SERVERPROPERTY('EngineEdition')` | 5 | 8 |

**The right-hand column is a list of reasons an application written for SQL Server will not move to
Azure SQL Database without changes.** Each is a feature somebody used fifteen years ago and nobody
removed: a job in SQL Agent that rebuilds a summary table at night, a stored procedure that reads the
finance database to check a refund, a linked server to an old system nobody dares to touch. Managed
Instance exists so that a company with those can leave the cupboard first and remove them later, or
never.

**The `RESTORE` row is the one migration leans on.** A backup taken by the old server's own `BACKUP
DATABASE`, copied into a blob container, can be restored straight into a Managed Instance by its URL.
Lesson 2's block blobs and lesson 6's SAS tokens are what make that copy work, and the last section of
this lesson is what Microsoft builds on top of it.

## What stays the same as lesson 8

The managed part is identical: Microsoft applies the patches and keeps the engine current, backups are
automatic with a point-in-time restore inside a retention period, high availability is inside the
price, and General Purpose and Business Critical are built the way lesson 8 described them. What is
still yours is also identical, the schema, the queries and the index the support screen needed. An
instance does not make a missing index cheaper; it makes it a bigger bill, because the smallest
instance is far larger than the smallest database.
