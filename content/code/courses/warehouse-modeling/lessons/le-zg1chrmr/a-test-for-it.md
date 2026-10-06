---
title: A test for undocumented columns
version: 1
---

"Every column has a description" is a rule, and a rule nobody checks is a wish. This program checks it, and one more
rule beside it: every column must also have a **classification**, read from a CSV file that section 9 explains.

```python
"""Fail if any column of the model has no description or no classification."""
import sys

import duckdb

con = duckdb.connect("wh.duckdb", read_only=True)
con.sql("CREATE TEMP TABLE classes AS FROM read_csv('classification.csv')")
problems = con.sql("""
    WITH model AS (
        SELECT table_name, column_name, comment FROM duckdb_columns()
        WHERE schema_name = 'main'
          AND regexp_matches(table_name, '^(dim|fact|bridge)_')
    )
    SELECT m.table_name, m.column_name,
           CASE WHEN m.comment IS NULL THEN 'no description' ELSE 'no classification' END
    FROM model m LEFT JOIN classes c USING (table_name, column_name)
    WHERE m.comment IS NULL OR c.class IS NULL
    UNION ALL
    SELECT c.table_name, c.column_name, 'classified but does not exist'
    FROM classes c ANTI JOIN model m USING (table_name, column_name)
    ORDER BY ALL
""").fetchall()

for table, column, problem in problems[:5]:
    print(f"{table}.{column}: {problem}")
if len(problems) > 5:
    print(f"... and {len(problems) - 5} more")
print(f"problems: {len(problems)}")
sys.exit(1 if problems else 0)
```

It reads the model's tables from DuckDB's own catalogue, so it cannot miss a table nobody listed, and it checks in both
directions: a column with no description or no classification is a problem, and so is a classification for a column
that no longer exists, which is how a renamed column shows up. It prints the first five problems, the count, and exits
1 if there is any.

On the warehouse as it stands, with one comment written:

```
ana@lab:~/wh$ python3 check_docs.py; echo "exit status $?"
bridge_book_author.author_key: no description
bridge_book_author.book_key: no description
bridge_book_author.position: no description
bridge_book_author.weight: no description
dim_author.author_id: no description
... and 86 more
problems: 91
exit status 1
```

**Ninety-one of 92 columns have no description.** That is not an unusual result for a warehouse built by one careful
person over twelve lessons; it is the normal one. Descriptions get written at the end, which in practice means never,
unless something fails without them.

That is what the exit status is for. Run in the pipeline that builds the warehouse, this test turns "please document
your columns" into a build that does not pass until they are. It is the same move as lesson 11's contract check: **a
promise becomes a file, and the file is executed**.
