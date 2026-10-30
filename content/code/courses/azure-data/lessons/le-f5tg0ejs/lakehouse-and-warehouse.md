---
title: Lakehouse or warehouse: who writes, and in what language
version: 1
---

**A Fabric lakehouse and a Fabric warehouse store their tables the same way, as Delta tables in
OneLake, and differ in who may write them.** That is the whole of the choice, and it is usually
made by the people rather than the data: a team that writes Python and Spark gets a lakehouse, and
a team that writes T-SQL gets a warehouse. This section is taught from Microsoft's documentation
and was not run.

## Side by side

| | lakehouse | warehouse |
|---|---|---|
| written by | Spark: notebooks and Spark job definitions; also pipelines and dataflows | T-SQL: `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `CREATE TABLE AS SELECT`, `COPY INTO`; also pipelines |
| read with T-SQL | yes, through its **SQL analytics endpoint**, which is read-only | yes |
| transactions | one table per write, Delta's own | across several tables in one transaction |
| files that are not tables | yes, the `Files` area | no |
| schema | defined by whatever writes the table | declared with `CREATE TABLE` |
| stored as | Delta tables in OneLake | Delta tables in OneLake |

**The SQL analytics endpoint is created with every lakehouse, and it cannot write.** It lets an
analyst run `SELECT` over the lakehouse's tables in T-SQL, define views and grant access, but an
`INSERT` into a lakehouse table through it is refused, because the table belongs to Spark. A
warehouse is the item where T-SQL owns the tables, and so the one where `UPDATE` works.

**Multi-table transactions are the reason a warehouse exists beside a lakehouse.** Loading Quitanda's
night means writing the orders, their items and the day's summary. In a lakehouse each Delta write
commits on its own, so a reader between the second and the third sees orders whose summary is not
there yet. In a warehouse the three can be one `BEGIN TRANSACTION` and one `COMMIT`, and a reader
sees all of the night or none of it, which is the guarantee `sql-databases` taught on a single
server, now over files in a lake.

## Reading across them

**Because both are Delta in OneLake, neither has to export to the other.** Inside a workspace, a
warehouse query can name a lakehouse's table by its three-part name, item, schema and table, and
join it to its own:

```sql
SELECT o.neighbourhood, sum(o.total_cents) / 100 AS reais, max(t.target_reais) AS target
FROM sales.dbo.orders AS o
JOIN finance.dbo.targets AS t ON t.neighbourhood = o.neighbourhood
GROUP BY o.neighbourhood;
```

Here `sales` is the lakehouse the sixth section writes into and `finance` a warehouse beside it.
This query was not run: it is shown for the shape of the name, and for what is missing from it,
which is any copy of `orders` into the warehouse. Spark can read the warehouse's tables the same
way, as Delta folders, without a connector.

## Where this sits next to lesson 16

**A Fabric warehouse is a dedicated SQL pool with the knobs taken away.** There is no DWU to choose
and no pool to pause, and no distribution column: lesson 16's sixty distributions and the choice
between hash, round-robin and replicated are made by the engine. What you get back is that every
query is paid in CUs out of the capacity, smoothed like everything else, rather than by a pool that
costs the same idle as busy. What you give up is the control over how rows are spread, which on
Synapse is how a skilled team makes a large join cheap. A team that has spent years tuning
distributions has a reason to stay; a team starting now usually has fewer.
