"""Load the raw layer: the shop's tables copied whole, and the files that
landed — the publishers' prices and the website's events — as JSON."""
import glob
import os

import psycopg

TABLES = ["shops", "books", "customers", "orders", "order_lines", "payments"]
COLUMNS = """SELECT string_agg(format('%%I %%s', attname, format_type(atttypid, atttypmod)),
                               ', ' ORDER BY attnum)
               FROM pg_attribute
              WHERE attrelid = %s::regclass AND attnum > 0 AND NOT attisdropped"""

SHOP_DB = os.environ.get("SHOP_DB", "shop")   # the tests point these at their own databases
WH_DB = os.environ.get("WH_DB", "wh")

with psycopg.connect(dbname=SHOP_DB) as shop, psycopg.connect(dbname=WH_DB) as wh:
    wh.execute("CREATE SCHEMA IF NOT EXISTS raw")
    shop.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
    for table in TABLES:
        columns = shop.execute(COLUMNS, (table,)).fetchone()[0]
        # Emptied and refilled, never dropped: dbt's views are built on these tables.
        wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{table} ({columns})")
        wh.execute(f"TRUNCATE raw.{table}")
        src, dst = shop.cursor(), wh.cursor()
        with src.copy(f"COPY {table} TO STDOUT") as out, \
             dst.copy(f"COPY raw.{table} FROM STDIN") as into:
            for chunk in out:
                into.write(chunk)
        print(f"raw.{table}: {src.rowcount} rows")

    for name, pattern in [("prices", "landing/prices.jsonl"),
                          ("events", "landing/events/*.jsonl")]:
        wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{name} (doc jsonb NOT NULL, file text NOT NULL)")
        wh.execute(f"TRUNCATE raw.{name}")
        n = 0
        with wh.cursor().copy(f"COPY raw.{name} (doc, file) FROM STDIN") as into:
            for path in sorted(glob.glob(pattern)):
                for line in open(path, encoding="utf-8"):
                    into.write_row((line, path))
                    n += 1
        print(f"raw.{name}: {n} documents")
