---
title: Descriptions kept in the database
version: 1
---

A dictionary kept in a separate document, a wiki page or a spreadsheet, starts out right and drifts. Columns are
added, renamed and dropped by people changing SQL, who are not thinking about the wiki. The first defence is to keep
**the description where the column is**, so that whoever changes one is looking at the other.

Most databases can store a comment on a table or a column. DuckDB, like PostgreSQL, uses `COMMENT ON`:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "COMMENT ON COLUMN fact_sales.net_cents IS 'Net sales: gross_cents minus discount_cents, in centavos, without shipping. Additive.'"
ana@lab:~/wh$ duckdb -readonly wh.duckdb -c "SELECT column_name, comment FROM duckdb_columns() WHERE table_name = 'fact_sales' AND column_name LIKE '%cents'"
┌────────────────┬───────────────────────────────────────────────────────────────────────────────────────┐
│  column_name   │                                        comment                                        │
│    varchar     │                                        varchar                                        │
├────────────────┼───────────────────────────────────────────────────────────────────────────────────────┤
│ gross_cents    │ NULL                                                                                  │
│ discount_cents │ NULL                                                                                  │
│ net_cents      │ Net sales: gross_cents minus discount_cents, in centavos, without shipping. Additive. │
└────────────────┴───────────────────────────────────────────────────────────────────────────────────────┘
```

The comment is stored in the catalogue of the database, beside the column's name and type, and comes back from the
same system view that lists the columns. It costs nothing at query time and needs no extra tool. Two columns away,
`gross_cents` and `discount_cents` still show `NULL`, which is the honest state of most warehouses: some columns have
been explained, by whoever happened to care.

Keeping descriptions in the database has a limit worth knowing. A comment is attached to a column, so it survives a
`SELECT` but not a rebuild: Ana's warehouse is rebuilt from SQL files by `lab.sh warehouse`, and a rebuilt table comes
back with no comments. **The comments have to be in a file the build runs**, under version control with the SQL that
creates the tables. That file is section 6.
