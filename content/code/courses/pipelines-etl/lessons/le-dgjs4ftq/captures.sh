#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` before the first block;
# in the `torn` and `snapshot` blocks, the day of trade that lands while the
# script is asleep, played from here in the background a second after the
# script starts; and the price API, started with `lab.sh api`.
#
# Timings are one run each and move from run to run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
lab reset >/dev/null
lab until 2026-03-02 >/dev/null
lab api >/dev/null
code file-prices-api-py /home/ana/pontofinal/prices_api.py

put torn.py <<'PY'
"""Read orders, then their lines, as two separate statements."""
import time

import psycopg

with psycopg.connect("dbname=shop", autocommit=True) as shop:
    orders = shop.execute("SELECT count(*) FROM orders").fetchone()[0]
    time.sleep(4)                      # a slow extraction, or a busy network
    lines = shop.execute("SELECT count(DISTINCT order_id) FROM order_lines").fetchone()[0]
print(f"orders read: {orders}, orders the lines belong to: {lines}")
PY
code torn-py torn.py
block torn
(sleep 1; lab day 2026-03-03 >/dev/null) &
on 'python torn.py'
wait

put snapshot.py <<'PY'
"""The same two reads, inside one transaction that sees one moment."""
import time

import psycopg

with psycopg.connect("dbname=shop") as shop:
    shop.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
    orders = shop.execute("SELECT count(*) FROM orders").fetchone()[0]
    time.sleep(4)
    lines = shop.execute("SELECT count(DISTINCT order_id) FROM order_lines").fetchone()[0]
print(f"orders read: {orders}, orders the lines belong to: {lines}")
PY
code snapshot-py snapshot.py
block snapshot
(sleep 1; lab day 2026-03-04 >/dev/null) &
on 'python snapshot.py'
wait

block reader
on "psql -q -c \"CREATE ROLE etl_reader LOGIN; GRANT SELECT ON ALL TABLES IN SCHEMA public TO etl_reader\""
on "psql -U etl_reader -c \"SELECT count(*) FROM orders\""
on "psql -U etl_reader -c \"UPDATE orders SET status = 'cancelled' WHERE order_id = 100001\""

block api-401
on 'curl -s "http://127.0.0.1:8081/v1/prices?page_size=2"; echo'
block api-page
on 'curl -s -H "X-Api-Key: $PRICES_API_KEY" "http://127.0.0.1:8081/v1/prices?page_size=2" | python -m json.tool'
block api-429
on 'for i in 1 2 3 4 5 6 7; do curl -s -o /dev/null -w "%{http_code} " -H "X-Api-Key: $PRICES_API_KEY" "http://127.0.0.1:8081/v1/prices?page_size=1"; done; echo'

put prices.py <<'PY'
"""Every list price the publishers changed since a moment, page by page."""
import json
import os
import sys
import time

import requests

URL = "http://127.0.0.1:8081/v1/prices"
HEADERS = {"X-Api-Key": os.environ["PRICES_API_KEY"]}
params = {"updated_since": sys.argv[1], "page_size": 200}
rows, pages, waits = [], 0, 0
while True:
    r = requests.get(URL, headers=HEADERS, params=params, timeout=10)
    if r.status_code == 429:
        waits += 1
        time.sleep(float(r.headers.get("Retry-After", "1")))
        continue
    r.raise_for_status()
    body = r.json()
    rows += body["data"]
    pages += 1
    if body["next_cursor"] is None:
        break
    params["cursor"] = body["next_cursor"]
with open(sys.argv[2], "w") as out:
    for row in rows:
        out.write(json.dumps(row) + "\n")
print(f"{len(rows)} prices in {pages} pages, {waits} waits for the rate limit")
PY
code prices-py prices.py
block prices
on 'python prices.py 2026-01-01T00:00:00-03:00 landing/prices.jsonl'
on 'python prices.py 2026-03-01T00:00:00-03:00 landing/prices_march.jsonl'
on 'head -2 landing/prices_march.jsonl'

block files
root 'day 2026-03-05'
on 'ls -l inbox'
on 'head -3 inbox/stock_2026-03-04.csv'
on 'head -3 inbox/stock_2026-03-05.csv | cat -v'
on 'file inbox/stock_2026-03-0*.csv'

put load_stock.py <<'PY'
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
PY
code load-stock-py load_stock.py
block drift
on 'python load_stock.py inbox/stock_2026-03-04.csv'
on 'python load_stock.py inbox/stock_2026-03-05.csv; echo "exit status $?"'

block partial
lab exec "head -n 600 inbox/stock_2026-03-04.csv > /tmp/stock_2026-03-04.csv"
on 'python load_stock.py /tmp/stock_2026-03-04.csv'
on 'tail -2 /tmp/stock_2026-03-04.csv'

block events
on 'wc -l landing/events/2026-03-05.jsonl'
on "python -c \"import json,collections; ids=collections.Counter(json.loads(l)['event_id'] for l in open('landing/events/2026-03-05.jsonl')); print(sum(1 for c in ids.values() if c > 1), 'event ids appear twice')\""
on "python -c \"import json; ev=[json.loads(l) for l in open('landing/events/2026-03-05.jsonl')]; late=[e for e in ev if not e['occurred_at'].startswith('2026-03-05')]; print(len(late), 'events from another day'); print(late[0])\""
lab api-down
