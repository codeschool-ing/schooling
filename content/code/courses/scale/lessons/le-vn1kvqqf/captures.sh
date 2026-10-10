#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 6`; the stack is started and the
#     two million tickets are inserted with the command the lesson shows,
#     once, in "big-table";
#   - where a section says "in a second terminal" or "a third", the script
#     starts that command in the background, waits a fixed time before the
#     next one so that they overlap as the section describes, and prints each
#     terminal's command and output as its own block once it has finished.
#     The waits are 2 s between the long transaction and the ALTER, and 1 s
#     before the load generator starts;
#   - "lockq" and "lock-timeout" each start their own long transaction, a
#     SELECT followed by pg_sleep(20) inside BEGIN … COMMIT, standing in for
#     a slow report or a session left idle in a transaction.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 6 || exit 1
cd "$HOME/tickets"
T=$(mktemp -d)
bg() { local n=$1; shift; printf '%s' "$*" > "$T/$n.cmd"; bash -c "$*" > "$T/$n.out" 2>&1 & }
show() { printf 'ana@lab:%s$ %s\n' "$(here)" "$(cat "$T/$1.cmd")"; cat "$T/$1.out"; }
SALES="python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'"
LONG="docker compose exec db psql -U tickets -c 'BEGIN' -c 'SELECT count(*) FROM tickets' -c 'SELECT pg_sleep(20)' -c 'COMMIT'"
WHO="docker compose exec db psql -U tickets -c \"SELECT pid, wait_event_type, wait_event, left(query, 40) AS query FROM pg_stat_activity WHERE datname = 'tickets' AND state = 'active' AND pid <> pg_backend_pid() ORDER BY backend_start\""

cap_big_table() {
  docker compose build -q >/dev/null 2>&1; docker compose up -d >/dev/null 2>&1; sleep 3
  run "docker compose exec db psql -U tickets -c 'INSERT INTO tickets (event_id, seat, code) SELECT 1 + n % 100, 1000000 + n, md5(n::text) FROM generate_series(1, 2000000) AS n'"
  run "docker compose exec db psql -U tickets -c \"SELECT pg_size_pretty(pg_total_relation_size('tickets'))\""
}

cap_lockq() {
  bg t1 "$LONG"; sleep 2
  bg t2 "docker compose exec db psql -U tickets -c '\\timing on' -c 'ALTER TABLE tickets ADD COLUMN gate text'"; sleep 1
  bg t3 "$SALES"; sleep 3
  run "$WHO"
  wait
  printf '##### lockq-t1\n'; show t1
  printf '##### lockq-t2\n'; show t2
  printf '##### lockq-t3\n'; show t3
}

cap_lock_timeout() {
  bg t1 "$LONG"; sleep 2
  bg t2 "docker compose exec db psql -U tickets -c \"SET lock_timeout = '2s'\" -c 'ALTER TABLE tickets ADD COLUMN scanned_at timestamptz'"; sleep 1
  bg t3 "$SALES"
  wait
  show t2
  printf '##### lock-timeout-t3\n'; show t3
}

cap_rewrites() {
  run "docker compose exec db psql -U tickets -c \"SELECT pg_relation_filenode('tickets')\""
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'ALTER TABLE tickets ADD COLUMN printed boolean NOT NULL DEFAULT false'"
  run "docker compose exec db psql -U tickets -c \"SELECT pg_relation_filenode('tickets')\""
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'ALTER TABLE tickets ADD COLUMN printed_at timestamptz DEFAULT clock_timestamp()'"
  run "docker compose exec db psql -U tickets -c \"SELECT pg_relation_filenode('tickets')\""
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'ALTER TABLE tickets ALTER COLUMN seat TYPE bigint'"
}

cap_index_plain() {
  bg t3 "$SALES"; sleep 1
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'CREATE INDEX tickets_code ON tickets (code)'"
  wait
  show t3
  docker compose exec -T db psql -U tickets -c 'DROP INDEX tickets_code' >/dev/null
}

cap_index_concurrently() {
  bg t3 "$SALES"; sleep 1
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'CREATE INDEX CONCURRENTLY tickets_code ON tickets (code)'"
  wait
  show t3
}

cap_backfill() {
  run "docker compose exec db psql -U tickets -c \"ALTER TABLE tickets ALTER COLUMN gate SET DEFAULT 'A'\""
  run 'docker compose cp backfill.sql db:/tmp/backfill.sql'
  run 'docker compose exec db psql -U tickets -f /tmp/backfill.sql'
  bg t3 "python3 load.py -m POST -c 4 -d 15 --events 100 'http://localhost:8080/events/{event}/tickets'"; sleep 1
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'CALL backfill_gate(50000)'"
  wait
  show t3
  run "docker compose exec db psql -U tickets -c 'SELECT gate, count(*) FROM tickets GROUP BY gate ORDER BY gate'"
}

cap_constraint() {
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'ALTER TABLE tickets ADD CONSTRAINT gate_set CHECK (gate IS NOT NULL) NOT VALID'"
  bg t3 "$SALES"; sleep 1
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'ALTER TABLE tickets VALIDATE CONSTRAINT gate_set'"
  wait
  show t3
  run "docker compose exec db psql -U tickets -c '\\timing on' -c 'ALTER TABLE tickets ALTER COLUMN gate SET NOT NULL'"
  run "docker compose logs db | grep 'canceling autovacuum'"
}

captures "$@"
docker compose down >/dev/null 2>&1
rm -rf "$T"
