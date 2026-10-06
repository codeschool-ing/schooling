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
