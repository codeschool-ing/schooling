#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of analytics-bi, as a script that
# produces them.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# It starts from the shop as lesson 1 leaves it. semantic.sql, the role
# metabase and the `docker run` line are taken out of this lesson's .md files
# and run as printed. Docker itself was installed in the lab from Docker's own
# packages rather than with `apt install docker.io`, so that line is not
# recorded; everything after it is. Metabase v0.64.1.5 is the official image.
#
# STAGED: the browser half. Metabase's first-run screens are answered through
# its API with the answers the lesson gives (lab/metabase.sh), and the SQL in
# the block `metabase-sql` is what Metabase's API returned for the question the
# lesson builds in the editor — the same text its View SQL button shows. That
# SQL is then run by psql, as the role metabase, which is the transcript.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16.15, machine clock UTC.
set -uo pipefail
cd "$(dirname "$0")"
export TZ=UTC LC_ALL=C.UTF-8
LAB_SH=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB_SH" "$@" 9>&-; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/abi-capture.lock; flock 9
. ../../lab/views.sh
. ../../lab/metabase.sh
docker rm -f metabase metabase2 >/dev/null 2>&1; docker volume rm metabase-data >/dev/null 2>&1
views_up_to 0 >/dev/null 2>&1
lab exec "psql -qX lantern -c 'DROP ROLE IF EXISTS metabase'" >/dev/null 2>&1
python3 "$FENCE" building-the-layer.md '-- semantic.sql' | lab exec 'cat > semantic.sql'

block load
on 'psql -q lantern -f semantic.sql'

block dv
session lantern <<'SQL'
\dv semantic.*
SQL

block fanout
session lantern <<'SQL'
SELECT sum(o.discount) AS discount_joined
FROM semantic.orders o JOIN semantic.order_lines l USING (order_id)
WHERE o.order_date BETWEEN '2026-01-01' AND '2026-03-31';
SELECT sum(discount) AS discount_alone
FROM semantic.orders
WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
SQL

block one-number
session lantern <<'SQL'
SELECT sum(net_revenue) FROM semantic.orders
WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
SET timezone = 'UTC';
SELECT sum(net_revenue) FROM semantic.orders
WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
SQL

block role
{ python3 "$FENCE" a-role-for-tools.md 'CREATE ROLE metabase'
  python3 "$FENCE" a-role-for-tools.md 'GRANT USAGE ON SCHEMA semantic'; } | session lantern

block role-check
on "PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM semantic.orders'"
on "PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM shop.orders'"

# the docker run line, exactly as the lesson prints it, backslashes and all
python3 "$FENCE" metabase-on-your-machine.md 'sudo docker run' | lab exec 'bash' >/dev/null
mb_wait
block ps
on 'sudo docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
block health
on "curl -s -w '\\n' http://localhost:3000/api/health"
block images
on 'sudo docker images metabase/metabase'
sleep 20
block stats
on 'sudo docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"'

mb_setup
MB_TOKEN=$(mb_login)
TABLE=$(mb_get /api/database/2/metadata | python3 -c 'import json,sys; print([t["id"] for t in json.load(sys.stdin)["tables"] if t["name"]=="orders"][0])')
FIELDS=$(mb_get /api/database/2/metadata | python3 -c 'import json,sys; t=[t for t in json.load(sys.stdin)["tables"] if t["name"]=="orders"][0]; f={x["name"]:x["id"] for x in t["fields"]}; print(f["net_revenue"], f["order_date"])')
set -- $FIELDS
Q="{\"database\":2,\"type\":\"query\",\"query\":{\"source-table\":$TABLE,\"aggregation\":[[\"sum\",[\"field\",$1,null]]],\"breakout\":[[\"field\",$2,{\"temporal-unit\":\"month\"}]]}}"
mb_post /api/dataset/native "$Q" | python3 -c 'import json,sys; print(json.load(sys.stdin)["query"])' > /tmp/abi-mb.sql
chmod 644 /tmp/abi-mb.sql

block metabase-sql
cat /tmp/abi-mb.sql

block metabase-sql-run
printf 'ana@vm:~$ PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f metabase.sql\n'
lab exec 'PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -f /tmp/abi-mb.sql' 2>&1

block described
mb_get /api/database/2/metadata | python3 -c '
import json,sys
for t in json.load(sys.stdin)["tables"]:
    if t["name"] == "orders":
        print(t["display_name"], "|", t["description"])
        for f in t["fields"]:
            if f.get("description"): print("  ", f["display_name"], "|", f["description"])'

# ---- when it fails
block bad-password
on "PGPASSWORD=wrong-password psql -h localhost -U metabase lantern -c 'SELECT 1'"

block no-grants
on 'psql -q lantern -f semantic.sql 2>/dev/null'
on "PGPASSWORD=pick-your-own-password psql -h localhost -U metabase lantern -c 'SELECT count(*) FROM semantic.orders'"
python3 "$FENCE" a-role-for-tools.md 'GRANT USAGE ON SCHEMA semantic' | lab exec 'psql -qX lantern'

block port-taken
on "sudo docker run -d --name metabase2 --network host $MB_IMAGE"
sleep 50
on 'sudo docker ps -a --format "table {{.Names}}\t{{.Status}}"'
on 'sudo docker logs metabase2 2>&1 | grep FAILED'
docker rm -f metabase2 >/dev/null 2>&1
