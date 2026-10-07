"""Check a table in the warehouse against its contract; exit 1 on any breach."""
import json
import sys

import duckdb

contract = json.load(open(sys.argv[1]))
table = contract["table"]
con = duckdb.connect("wh.duckdb", read_only=True)
breaches = []

actual = dict(con.execute(
    "SELECT column_name, data_type FROM duckdb_columns() WHERE table_name = ?",
    [table]).fetchall())
for column, wanted in contract["columns"].items():
    if column not in actual:
        breaches.append(f"column {column} is missing")
    elif actual[column] != wanted:
        breaches.append(f"column {column} is {actual[column]}, contract says {wanted}")

for column in contract["not_null"]:
    if column in actual:
        n = con.sql(f"SELECT count(*) FROM {table} WHERE {column} IS NULL").fetchone()[0]
        if n:
            breaches.append(f"{n} rows with no {column}")

key = ", ".join(contract["unique"])
n = con.sql(f"SELECT count(*) FROM (SELECT {key} FROM {table} GROUP BY ALL HAVING count(*) > 1)").fetchone()[0]
if n:
    breaches.append(f"{n} values of ({key}) appear more than once")

for b in breaches:
    print("BREACH:", b)
print(f"{table}: {len(contract['columns'])} columns checked, breaches: {len(breaches)}")
sys.exit(1 if breaches else 0)
