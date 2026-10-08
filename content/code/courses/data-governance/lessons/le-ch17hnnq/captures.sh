#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 to 10 leave
# (`lab.sh state 10`). The feed is the orders of 30 June 2026, the day before
# the lab's today, so it does not move with the day the capture is run.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, OpenBao 2.5.5, 4 cores,
# TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 10 >/dev/null 2>&1 </dev/null

put feed.sql <<'EOF'
-- What Rota Certa, the delivery company, receives every morning: enough to
-- plan routes, and nothing that names anybody. The labels with names are
-- printed in the shop, not sent in the feed.
CREATE ROLE rota_certa NOLOGIN;
SET ROLE ipe_owner;
CREATE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT sum(i.quantity) FROM sales.order_items i WHERE i.order_id = o.order_id) AS items
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
GRANT USAGE ON SCHEMA share TO rota_certa;
GRANT SELECT ON share.delivery_feed TO rota_certa;
EOF
put delivery-feed.v1.json <<'EOF'
{
  "contract": "delivery-feed",
  "version": "1.0.0",
  "owner": "head of sales",
  "consumer": "Rota Certa Logística, a processor (LGPD art. 39)",
  "purpose": "planning the next day's delivery routes",
  "basis": "LGPD art. 7, V: delivering what the customer bought",
  "kept_by_consumer": "30 days",
  "stays_in": "Brazil",
  "fresh_by": "06:00 every day, with the orders of the day before",
  "relation": "share.delivery_feed",
  "fields": [
    {"name": "order_id",   "type": "integer",   "class": "personal", "source": "sales.orders.order_id"},
    {"name": "ordered_on", "type": "date",      "class": "personal", "source": "sales.orders.ordered_at"},
    {"name": "cep",        "type": "text",      "class": "personal", "source": "sales.customers.cep"},
    {"name": "city",       "type": "text",      "class": "personal", "source": "sales.customers.city"},
    {"name": "state",      "type": "character", "class": "personal", "source": "sales.customers.state"},
    {"name": "items",      "type": "bigint",    "class": "none",     "source": "a count of sales.order_items"}
  ],
  "quality": [
    {"rule": "every cep has the shape 00000-000",
     "sql": "SELECT count(*) FROM share.delivery_feed WHERE cep !~ '^[0-9]{5}-[0-9]{3}$'"},
    {"rule": "every order has at least one item",
     "sql": "SELECT count(*) FROM share.delivery_feed WHERE items IS NULL OR items < 1"}
  ]
}
EOF
put check_contract.py <<'EOF'
"""Compare a data contract with what the database actually serves: the same
columns, in the same types, with the classes gov.column_class gives their
sources, and the quality rules holding. Exit 1 on any difference."""
import json, subprocess, sys

def sql(q):
    out = subprocess.run(["psql", "-X", "-q", "-At", "-c", "SET ROLE ipe_owner", "-c", q],
                         capture_output=True, text=True, check=True).stdout
    return [line.split("|") for line in out.splitlines() if line]

contract = json.load(open(sys.argv[1]))
schema, rel = contract["relation"].split(".")
served = {n: t for n, t in sql(
    "SELECT column_name, data_type FROM information_schema.columns "
    f"WHERE table_schema = '{schema}' AND table_name = '{rel}' ORDER BY ordinal_position")}
promised = {f["name"]: f for f in contract["fields"]}
problems = []

for name in served.keys() - promised.keys():
    problems.append(f"{name}: served, and not in the contract")
for name in promised.keys() - served.keys():
    problems.append(f"{name}: in the contract, and not served")
for name in served.keys() & promised.keys():
    if served[name] != promised[name]["type"]:
        problems.append(f"{name}: contract says {promised[name]['type']}, served as {served[name]}")
    src = promised[name]["source"].split(".")
    if len(src) == 3:
        row = sql("SELECT class FROM gov.column_class "
                  f"WHERE (table_schema, table_name, column_name) = ('{src[0]}', '{src[1]}', '{src[2]}')")
        actual = row[0][0] if row else "unclassified"
        if actual != promised[name]["class"]:
            problems.append(f"{name}: contract says {promised[name]['class']}, "
                            f"gov.column_class says {actual}")
for q in contract["quality"]:
    n = int(sql(q["sql"])[0][0])
    if n:
        problems.append(f"quality: {q['rule']}: {n} rows break it")

name = f"{contract['contract']} {contract['version']}"
if problems:
    print(f"{name}: {len(problems)} problem(s)")
    for p in sorted(problems):
        print("  " + p)
    sys.exit(1)
print(f"{name}: {len(served)} fields and {len(contract['quality'])} rules, as promised")
EOF
code feed-sql feed.sql
code contract-json delivery-feed.v1.json
code check-py check_contract.py
block feed
on 'sudo -u postgres psql -c "CREATE SCHEMA share AUTHORIZATION ipe_owner"'
on 'psql -f feed.sql'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders, sum(items) AS items FROM share.delivery_feed"'
on 'python3 check_contract.py delivery-feed.v1.json; echo "exit $?"'

block csv
on 'psql -c "SET ROLE ipe_owner" -c "\copy (SELECT * FROM share.delivery_feed ORDER BY order_id LIMIT 3) TO STDOUT WITH (FORMAT csv, HEADER)"'

block breaking
put labels.sql <<'EOF'
-- "The driver needs the name for the label", says a ticket. Nobody asks the
-- owner, nobody changes the contract.
SET ROLE ipe_owner;
CREATE OR REPLACE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT sum(i.quantity) FROM sales.order_items i WHERE i.order_id = o.order_id) AS items,
       c.full_name
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
EOF
on 'cat labels.sql'
on 'psql -f labels.sql'
on 'python3 check_contract.py delivery-feed.v1.json; echo "exit $?"'

put typechange.sql <<'EOF'
-- Back to the contract's columns, and one "harmless" change: items counted
-- as lines rather than summed as units, and cast to integer on the way.
SET ROLE ipe_owner;
DROP VIEW share.delivery_feed;
CREATE VIEW share.delivery_feed AS
SELECT o.order_id,
       o.ordered_at::date AS ordered_on,
       c.cep,
       c.city,
       c.state,
       (SELECT count(*) FROM sales.order_items i WHERE i.order_id = o.order_id)::integer AS items
FROM sales.orders o
JOIN sales.customers c USING (customer_id)
WHERE o.status <> 'cancelled'
  AND o.ordered_at::date = DATE '2026-06-30';
GRANT SELECT ON share.delivery_feed TO rota_certa;
EOF
code typechange-sql typechange.sql
block typechange
on 'psql -f typechange.sql'
on 'python3 check_contract.py delivery-feed.v1.json; echo "exit $?"'

