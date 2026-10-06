---
title: Generating the dictionary
version: 1
---

With every description in the database, the dictionary itself is no longer written. It is **generated**, from the
same catalogue the test reads:

```python
"""Write the field dictionary, in Markdown, from the database's own comments."""
import duckdb

con = duckdb.connect("wh.duckdb", read_only=True)
con.sql("CREATE TEMP TABLE classes AS FROM read_csv('classification.csv')")
tables = con.sql("""
    SELECT table_name, comment FROM duckdb_tables()
    WHERE schema_name = 'main' AND regexp_matches(table_name, '^(dim|fact|bridge)_')
    ORDER BY table_name
""").fetchall()

print("# Ponto Final warehouse: field dictionary\n")
for table, about in tables:
    print(f"## {table}\n\n{about}\n")
    print("| column | type | data | meaning |")
    print("|---|---|---|---|")
    for column, kind, cls, meaning in con.execute("""
        SELECT d.column_name, d.data_type, c.class, d.comment
        FROM duckdb_columns() d JOIN classes c USING (table_name, column_name)
        WHERE d.schema_name = 'main' AND d.table_name = ?
        ORDER BY d.column_index
    """, [table]).fetchall():
        print(f"| {column} | {kind} | {cls} | {meaning} |")
    print()
```

```
ana@lab:~/wh$ python3 dictionary.py > dictionary.md && wc -l dictionary.md
178 dictionary.md
ana@lab:~/wh$ awk '/^## fact_sales/ {p = 1} /^## / && !/fact_sales/ {p = 0} p' dictionary.md
## fact_sales

One row per line of an order that was not cancelled, in a shop or online.

| column | type | data | meaning |
|---|---|---|---|
| date_key | INTEGER | none | Day the order was placed, São Paulo time. Key of dim_date. |
| shop_key | BIGINT | none | Shop the order was placed in; the website is the shop Online. Key of dim_shop. |
| book_key | BIGINT | none | Book sold on this line. Key of dim_book. |
| customer_key | BIGINT | pseudonymous | Customer as they were when ordering; 0 for a sale nobody identified. Key of dim_customer. |
| promotion_key | BIGINT | none | Promotion applied to the line; 0 when there was none. Key of dim_promotion. |
| order_id | BIGINT | pseudonymous | Order number in the shop system. With line_no, identifies the row. |
| line_no | BIGINT | none | Position of the line within its order, from 1. |
| quantity | BIGINT | none | Copies sold on the line. Additive. |
| gross_cents | BIGINT | none | Quantity times the unit price charged, before any discount, in centavos. Additive. |
| discount_cents | BIGINT | none | Discount given on the line, in centavos. Additive. |
| net_cents | BIGINT | none | Net sales: gross_cents minus discount_cents, in centavos, without shipping. Additive. |
```

A 178-line Markdown document, one section per table, its grain on top and one row per column with type,
classification and meaning. It can be published wherever people look, a wiki, the repository, a catalogue tool, and
regenerated on every build. Because it is generated, **it cannot disagree with the database**: if a column exists,
it is in the document, and its description is the one stored on the column.

This turns the old problem round. A hand-written dictionary is a second copy of the truth that has to be kept in step
by people. A generated one has a single source, the comments, and the test of section 5 keeps that source complete.
The only thing left to people is what no program can do: **deciding what each column means and writing it down
well**.

The same pattern runs through the tools that do this at scale. dbt keeps descriptions in YAML beside each model and
generates a documentation site from them, the subject of `pipelines-etl` lesson 12. Catalogue tools harvest comments
from the databases they connect to. The source of the meaning stays next to the code that makes the column.
