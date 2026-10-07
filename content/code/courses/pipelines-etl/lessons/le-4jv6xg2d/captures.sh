#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` before the first block,
# which puts the shop back to the night of 28 February; and the replay of the
# website in the streaming block, started in the background by this script
# as `python ~/lab/lab/replay.py`, which the lesson names.
#
# Timings and clock times are one run each, on a machine shared with other
# work, and move from run to run; the lesson says so where it quotes one.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, Python 3.13, Airflow 3.3.2,
# dbt-core 1.12.5, 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
lab reset >/dev/null

block versions
on 'psql --version'
on 'python --version'
on 'airflow version'
on 'dbt --version | head -2'

block disk
on 'du -sh /var/lib/etl-data /var/lib/etl-pg /opt/etl'

block tables
on 'psql -c "\dt"'

block counts
on "psql -c \"SELECT (SELECT count(*) FROM customers) AS customers, (SELECT count(*) FROM orders) AS orders, (SELECT max(ordered_at) FROM orders) AS last_order\""

block day
root 'day 2026-03-01'
on "psql -c \"SELECT (SELECT count(*) FROM customers) AS customers, (SELECT count(*) FROM orders) AS orders, (SELECT max(ordered_at) FROM orders) AS last_order\""
on 'ls -l landing/events inbox'

block day-sql
on 'grep -c "^BEGIN" /var/lib/etl-data/days/2026-03-01.sql'
on 'grep -oE "^(INSERT INTO|UPDATE|DELETE FROM) [a-z_]+" /var/lib/etl-data/days/2026-03-01.sql | sort | uniq -c'

block day-again
root 'day 2026-03-01'

put batch.py <<'PY'
"""One day of sales per shop, from the shop's database into the warehouse."""
import datetime as dt
import sys

import psycopg

day = dt.date.fromisoformat(sys.argv[1])
with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
    rows = shop.execute(
        """SELECT o.shop_id, count(*), sum(p.amount_cents)
             FROM orders o JOIN payments p USING (order_id)
            WHERE o.ordered_at >= %s AND o.ordered_at < %s
              AND o.status = 'completed'
            GROUP BY o.shop_id
            ORDER BY o.shop_id""",
        (day, day + dt.timedelta(days=1)),
    ).fetchall()
    wh.execute("""CREATE TABLE IF NOT EXISTS daily_sales (
                    day date, shop_id integer, orders integer, revenue_cents bigint)""")
    with wh.cursor() as cur:
        cur.executemany("INSERT INTO daily_sales VALUES (%s, %s, %s, %s)",
                        [(day, *r) for r in rows])
print(f"{day}: {len(rows)} shops, {sum(r[1] for r in rows)} orders")
PY
code batch-py batch.py
block batch
on 'time python batch.py 2026-03-01'
on 'psql -d wh -c "SELECT * FROM daily_sales ORDER BY shop_id"'
block batch-twice
on 'python batch.py 2026-03-01'
on 'psql -d wh -c "SELECT count(*), sum(orders) FROM daily_sales"'

put consume.py <<'PY'
"""Read the website's events as they land, and say how far behind it is."""
import datetime as dt
import json
import os
import sys
import time

path, offset_file, seconds = sys.argv[1], sys.argv[2], float(sys.argv[3])
pos = int(open(offset_file).read()) if os.path.exists(offset_file) else 0
print(f"starting at byte {pos}")
stop = time.time() + seconds
seen, purchases, worst, report = 0, 0, 0.0, time.time() + 2
with open(path, encoding="utf-8") as f:
    f.seek(pos)
    while time.time() < stop:
        line = f.readline()
        if not line.endswith("\n"):        # nothing new yet, or half a line
            f.seek(pos)
            time.sleep(0.1)
            continue
        pos = f.tell()
        event = json.loads(line)
        seen += 1
        purchases += event["type"] == "purchase"
        happened = dt.datetime.fromisoformat(event["occurred_at"])
        lag = (dt.datetime.now().astimezone() - happened).total_seconds()
        worst = max(worst, lag)
        with open(offset_file, "w") as o:
            o.write(str(pos))
        if time.time() >= report:
            print(f"{time.strftime('%H:%M:%S')}  {seen} events, "
                  f"{purchases} purchases, at most {worst:.1f} s behind")
            worst, report = 0.0, report + 2
print(f"stopped at byte {pos}")
PY
code consume-py consume.py
lab exec 'rm -f landing/stream.jsonl stream.offset; touch landing/stream.jsonl'
lab exec 'setsid python ~/lab/lab/replay.py landing/events/2026-03-01.jsonl landing/stream.jsonl 600 </dev/null >/dev/null 2>&1 & echo $! > /home/ana/etl/replay.pid'
sleep 1
block stream
on 'python consume.py landing/stream.jsonl stream.offset 7'
sleep 3
on 'python consume.py landing/stream.jsonl stream.offset 5'
lab exec 'kill $(cat replay.pid); rm -f replay.pid'
