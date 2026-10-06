---
title: Generating the staging layer
version: 1
---

The metadata for Ana's staging layer is a list of fifteen tables, and only one of them says anything more than its
name:

```json
{
  "schema": "staging",
  "directory": "extract",
  "tables": [
    {"name": "shops"},
    {"name": "categories"},
    {"name": "publishers"},
    {"name": "authors"},
    {"name": "books", "types": {"isbn": "VARCHAR"}},
    {"name": "book_authors"},
    {"name": "customers"},
    {"name": "customer_changes"},
    {"name": "promotions"},
    {"name": "orders"},
    {"name": "order_lines"},
    {"name": "payments"},
    {"name": "stock_counts"},
    {"name": "events"},
    {"name": "event_attendance"}
  ]
}
```

The generator reads it and writes SQL:

```schooling-example
{
  "language": "python",
  "file": "gen_staging.py",
  "parts": [
    {
      "code": "\"\"\"Write the staging SQL from sources.json instead of by hand.\"\"\"\nimport json\nimport sys\n\nmeta = json.load(open(sys.argv[1]))\n\n",
      "note": "The metadata file is named on the command line, so the same program can generate any layer described the same way."
    },
    {
      "code": "print(\"SET TimeZone = 'America/Sao_Paulo';\")\nprint(f\"CREATE SCHEMA {meta['schema']};\")\n",
      "note": "What is written once, before any table: the time zone and the schema, whose name also comes from the metadata."
    },
    {
      "code": "for t in meta[\"tables\"]:\n    options = [\"sample_size = -1\"]\n    if \"types\" in t:\n        pairs = \", \".join(f\"'{c}': '{ty}'\" for c, ty in t[\"types\"].items())\n        options.append(f\"types = {{{pairs}}}\")\n",
      "note": "The exceptions live here. Every table gets the same option; a table whose entry carries `types` gets them added, and no table needs code of its own."
    },
    {
      "code": "    path = f\"{meta['directory']}/{t['name']}.csv\"\n    print(f\"CREATE TABLE {meta['schema']}.{t['name']} AS \"\n          f\"FROM read_csv('{path}', {', '.join(options)});\")",
      "note": "One statement per entry, with the file's path built from the directory and the name, which is why the extract's files must be named after their tables."
    }
  ]
}
```

```
ana@lab:~/wh$ python3 gen_staging.py sources.json > staging.sql && wc -l staging.sql && sed -n 1,3p staging.sql && grep books staging.sql
17 staging.sql
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA staging;
CREATE TABLE staging.shops AS FROM read_csv('extract/shops.csv', sample_size = -1);
CREATE TABLE staging.books AS FROM read_csv('extract/books.csv', sample_size = -1, types = {'isbn': 'VARCHAR'});
ana@lab:~/wh$ duckdb fresh.duckdb < staging.sql
```

Then the generated layer is built into an empty database and compared with the hand-written one, column by column:

```sql
-- Every staging column, by hand against generated, both ways round.
ATTACH 'wh.duckdb' AS hand (READ_ONLY);
ATTACH 'fresh.duckdb' AS generated (READ_ONLY);
WITH h AS (SELECT table_name, column_name, data_type FROM duckdb_columns()
           WHERE database_name = 'hand' AND schema_name = 'staging'),
     g AS (SELECT table_name, column_name, data_type FROM duckdb_columns()
           WHERE database_name = 'generated' AND schema_name = 'staging')
SELECT (SELECT count(*) FROM h) AS hand_columns,
       (SELECT count(*) FROM g) AS generated_columns,
       (SELECT count(*) FROM (FROM h EXCEPT FROM g)) AS only_by_hand,
       (SELECT count(*) FROM (FROM g EXCEPT FROM h)) AS only_generated;
```

```
ana@lab:~/wh$ duckdb < compare.sql
┌──────────────┬───────────────────┬──────────────┬────────────────┐
│ hand_columns │ generated_columns │ only_by_hand │ only_generated │
│    int64     │       int64       │    int64     │     int64      │
├──────────────┼───────────────────┼──────────────┼────────────────┤
│           77 │                77 │            0 │              0 │
└──────────────┴───────────────────┴──────────────┴────────────────┘
```

Seventeen lines of SQL, and the one exception, `books`, carries its forced type. Built into an empty database and
compared with the staging layer written by hand in lesson 2, **every one of the 77 columns matches, by name and by
type, in both directions**. The generated layer is the hand-written one, and from now on adding a source is one line
of JSON.

Two things are worth seeing in the result. The exception is visible: `"types": {"isbn": "VARCHAR"}` is in the
metadata, where anybody reading the list can see that this table is different and why the generator has an option
for it. In fifteen hand-written statements it was one line among fifteen. And the comparison is itself the test a
generator needs: **a generated layer is trusted because it was compared with a known-good one**, and the comparison
can run every time the generator changes.

Where metadata-driven pipelines stop paying is just as visible. Staging is fifteen copies of one pattern; the type 2
load of lesson 5 is one careful program, and generating it from metadata would mean a template as complicated as the
program it replaces. **Generate the layers that repeat, write the ones that think**: bronze to silver, staging, type 1
dimensions and Data Vault are good candidates; the business logic of the gold layer is not.
