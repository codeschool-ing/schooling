#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of warehouse-modeling, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: ~/wh/wh.duckdb and ~/wh/extract, the
# warehouse and the extract of lessons 2 to 5, made here by `lab.sh
# warehouse`. The lake is the directory ~/wh/lake on the lab's own disk,
# standing in for a bucket in object storage; nothing here reached a cloud.
# The Python programs are the course's own, in lab/delta/, copied into ~/wh by
# `put` and shown in the lesson as they are.
#
# A Delta table's data files get random names, so the names in the listings
# change on every run; the lesson quotes counts and never a name.
#
# Recorded on Ubuntu 24.04, DuckDB 1.5.6, deltalake 1.6.6 (delta-rs),
# pyarrow 25.0.1, TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
COURSE=$(cd "$(dirname "$LAB_SH")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
# Each command gets 120 seconds. In one recording a Python program printed its
# line and then never exited, waiting at interpreter shutdown; the limit ends
# such a run instead of the whole script waiting for it.
on() { printf 'ana@lab:~/wh$ %s\n' "$*"; timeout 120 bash "$LAB_SH" exec "$*" 2>&1 || true; }
put() { lab exec "cat > '$1'"; }
code() { printf '##### %s\n' "$1"; lab exec "cat '$2'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/wh-capture.lock; flock 9
lab reset >/dev/null
lab warehouse >/dev/null
for f in write_sales read_sales fix_line history bad_append vacuum; do
  put $f.py < "$COURSE/lab/delta/$f.py"
done

block raw
on 'mkdir -p lake/raw/orders && cp extract/orders.csv lake/raw/orders/orders_2025-12-31.csv'
on "duckdb -c \"SELECT count(*) AS orders, min(ordered_at) AS first, max(ordered_at) AS last FROM read_csv('lake/raw/orders/*.csv')\""

put new-export.sql <<'EOF'
-- A week later, a file from the website's new version, made here from the
-- last week of December: one column renamed, and shipping written as text.
COPY (SELECT order_id + 1000000 AS order_id, shop_id, customer_id AS client_id,
             ordered_at + INTERVAL 7 DAY AS ordered_at, status,
             CASE WHEN shipping_cents = 0 THEN 'free' ELSE CAST(shipping_cents AS VARCHAR) END
                 AS shipping_cents,
             paid_at + INTERVAL 7 DAY AS paid_at, shipped_at + INTERVAL 7 DAY AS shipped_at,
             delivered_at + INTERVAL 7 DAY AS delivered_at
      FROM read_csv('lake/raw/orders/orders_2025-12-31.csv')
      WHERE ordered_at >= '2025-12-25')
TO 'lake/raw/orders/orders_2026-01-07.csv' (HEADER);
EOF
code new-export-sql new-export.sql
block drift
on 'duckdb < new-export.sql'
on 'head -2 lake/raw/orders/orders_2026-01-07.csv'
on "duckdb -c \"SELECT count(*) AS orders, sum(shipping_cents) AS shipping FROM read_csv('lake/raw/orders/*.csv')\""
on "duckdb -c \"SELECT count(*) AS orders, count(customer_id) AS with_customer FROM read_csv('lake/raw/orders/*.csv', union_by_name = true)\""

code write-py write_sales.py
block delta-write
on 'python write_sales.py 2024 overwrite'
on 'python write_sales.py 2025 append'
on 'find lake/sales -type f | sort | sed "s/part-.*parquet/part-….parquet/"'

block log
on 'ls lake/sales/_delta_log'
on "jq -c 'keys[0]' lake/sales/_delta_log/00000000000000000000.json"
on "jq -c 'select(.add) | .add | {partitionValues, size, records: (.stats | fromjson | .numRecords)}' lake/sales/_delta_log/00000000000000000001.json"

code read-py read_sales.py
block read
on 'python read_sales.py'

code fix-py fix_line.py
block fix
on 'python fix_line.py'
on "jq -c 'keys[0]' lake/sales/_delta_log/00000000000000000002.json"
on 'python read_sales.py'

code history-py history.py
block travel
on 'python read_sales.py 1'
on 'python read_sales.py 0'
on 'python history.py'

code bad-py bad_append.py
block schema
on 'python bad_append.py 2>&1 | tail -1'
on 'python history.py | tail -1'
on 'python bad_append.py merge'

code vacuum-py vacuum.py
block vacuum
on 'python vacuum.py'
on 'find lake/sales -name "*.parquet" | wc -l'
