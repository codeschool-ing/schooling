#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of pipelines-etl, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# STAGED, and not typed in the lesson: `lab.sh reset` before the first block,
# and in the `nightly` block, the loop that plays a day and applies it twelve
# times; the lesson shows the loop and its last lines.
#
# LSNs, WAL sizes and timings depend on the machine and on what else wrote to
# the cluster; they move from run to run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16 with its built-in test_decoding
# plugin, Python 3.13, 4 cores, TZ=America/Sao_Paulo, on 2026-10-07.
. "$(dirname "$0")/../../capture.sh"
lab reset >/dev/null

block wal-level
on 'psql -c "SHOW wal_level"'

block slot
on "psql -c \"SELECT * FROM pg_create_logical_replication_slot('wh_cdc', 'test_decoding')\""
lab exec "psql -q -c \"SELECT pg_create_logical_replication_slot('forgotten', 'test_decoding')\" >/dev/null"

put snapshot_customers.sql <<'SQL'
-- The starting point: the customers as they are now, copied whole.
CREATE SCHEMA IF NOT EXISTS cdc;
DROP TABLE IF EXISTS cdc.customers;
CREATE TABLE cdc.customers (
  customer_id integer PRIMARY KEY, name text, email text, city text, state text,
  created_at timestamptz, updated_at timestamptz);
SQL
code snapshot-sql snapshot_customers.sql
block initial
on 'psql -q -d wh -f snapshot_customers.sql'
on 'psql -c "\copy customers TO /tmp/customers.csv" && psql -d wh -c "\copy cdc.customers FROM /tmp/customers.csv"'

block day
root 'day 2026-03-01'
on "psql -c \"SELECT count(*) FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL)\""
on "psql -At -c \"SELECT data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) WHERE data LIKE 'table public.customers: UPDATE%' LIMIT 1\""
on "psql -c \"SELECT lsn, xid, left(data, 60) AS data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) LIMIT 7\""

put apply_cdc.py <<'PY'
"""Apply the shop's committed changes to customers, read from a logical
replication slot, to the copy in the warehouse."""
import re

import psycopg

FIELD = re.compile(r"(\w+)\[[^\]]+\]:('(?:[^']|'')*'|\S+)")


def values(text):
    out = {}
    for name, raw in FIELD.findall(text):
        out[name] = None if raw == "null" else raw.strip("'").replace("''", "'")
    return out


done = {"INSERT": 0, "UPDATE": 0, "DELETE": 0, "other tables": 0}
with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
    changes = shop.execute(
        "SELECT lsn, data FROM pg_logical_slot_get_changes('wh_cdc', NULL, NULL)").fetchall()
    for lsn, data in changes:
        if not data.startswith("table "):
            continue                                   # BEGIN and COMMIT lines
        if not data.startswith("table public.customers: "):
            done["other tables"] += 1
            continue
        op, _, rest = data.removeprefix("table public.customers: ").partition(": ")
        row = values(rest)
        if op == "DELETE":
            wh.execute("DELETE FROM cdc.customers WHERE customer_id = %s", (row["customer_id"],))
        else:
            cols = list(row)
            wh.execute(
                f"INSERT INTO cdc.customers ({', '.join(cols)}) VALUES ({', '.join(['%s'] * len(cols))})"
                f" ON CONFLICT (customer_id) DO UPDATE SET "
                + ", ".join(f"{c} = excluded.{c}" for c in cols if c != "customer_id"),
                list(row.values()))
        done[op] += 1
print(f"{len(changes)} changes read up to {changes[-1][0] if changes else '-'}: {done}")
PY
code apply-py apply_cdc.py
block apply
on 'python apply_cdc.py'
on 'python apply_cdc.py'

block nightly
for d in 02 03 04 05 06 07 08 09 10 11 12 13; do lab day 2026-03-$d >/dev/null; lab exec 'python apply_cdc.py' >/dev/null; done
root 'day 2026-03-14'
on 'python apply_cdc.py'
on "psql -d wh -c \"SELECT count(*) FROM cdc.customers WHERE customer_id = 1880\""

block compare
on 'psql -c "\copy customers TO /tmp/customers.csv" && psql -d wh -c "CREATE TEMP TABLE now_in_shop (LIKE cdc.customers)" -c "\copy now_in_shop FROM /tmp/customers.csv" -c "SELECT (SELECT count(*) FROM (TABLE now_in_shop EXCEPT TABLE cdc.customers) a) AS only_in_shop, (SELECT count(*) FROM (TABLE cdc.customers EXCEPT TABLE now_in_shop) b) AS only_in_copy"'

block retained
on 'psql -q -c CHECKPOINT && python apply_cdc.py'

on "psql -c \"SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal FROM pg_replication_slots\""
on 'psql -c "SHOW max_slot_wal_keep_size"'
on "psql -c \"SELECT pg_drop_replication_slot('forgotten')\""

block identity
on 'grep -A1 "^UPDATE customers" /var/lib/etl-data/days/2026-03-15.sql | head -1'
on 'psql -q -c "ALTER TABLE customers REPLICA IDENTITY FULL"'
root 'day 2026-03-15'
on "psql -At -c \"SELECT data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) WHERE data LIKE 'table public.customers: UPDATE%' LIMIT 1\""
on 'python apply_cdc.py'
