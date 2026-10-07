"""Load one day of the distributor's stock file into the warehouse's raw layer."""
import csv
import sys

import psycopg

EXPECTED = ["isbn", "available", "as_of"]
path = sys.argv[1]
with open(path, newline="", encoding="utf-8") as f:
    reader = csv.reader(f)
    header = next(reader)
    if header != EXPECTED:
        sys.exit(f"{path}: header is {header}, expected {EXPECTED}; nothing loaded")
    rows = list(reader)
with psycopg.connect("dbname=wh") as wh:
    wh.execute("CREATE SCHEMA IF NOT EXISTS raw")
    wh.execute("""CREATE TABLE IF NOT EXISTS raw.stock (
                    isbn text, available integer, as_of timestamptz, file text)""")
    wh.execute("DELETE FROM raw.stock WHERE file = %s", (path,))
    with wh.cursor() as cur:
        cur.executemany("INSERT INTO raw.stock VALUES (%s, %s, %s, %s)",
                        [(*row, path) for row in rows])
print(f"{path}: {len(rows)} rows loaded")
