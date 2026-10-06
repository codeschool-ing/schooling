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
