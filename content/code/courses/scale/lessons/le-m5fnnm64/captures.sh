#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 2` from the blocks of lessons 1
#     and 2, so the files are the ones the lessons show;
#   - every block that needs the stack starts it itself, from nothing, so
#     blocks can be re-run one at a time;
#   - "lag" recreates the replica with DELAY=2s, as the section tells the
#     student to; the LSN in "lsn" is whatever the primary printed, carried
#     into the next command by the script rather than typed.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 2 || exit 1
cd "$HOME/tickets"
fresh() { docker compose down >/dev/null 2>&1; docker compose build -q >/dev/null 2>&1; DELAY=${1:-0} docker compose up -d >/dev/null 2>&1; sleep 2; }

cap_rep_up() {
  run 'docker compose build -q'
  run 'docker compose up -d'
  run 'docker compose ps --format "table {{.Service}}\t{{.Status}}"'
}

cap_rep_status() {
  run "docker compose exec db psql -U tickets -c 'SELECT client_addr, state, sync_state, replay_lag FROM pg_stat_replication'"
}

cap_rep_readonly() {
  run "docker compose exec replica psql -U tickets -c 'SELECT pg_is_in_recovery()'"
  run "docker compose exec replica psql -U tickets -c \"UPDATE events SET name = 'Show One' WHERE id = 1\""
}

cap_route() {
  fresh
  run "docker compose exec replica psql -U tickets -Atc \"SELECT xact_commit FROM pg_stat_database WHERE datname = 'tickets'\""
  run 'python3 load.py -c 4 -d 5 http://localhost:8080/events/1'
  run "docker compose exec replica psql -U tickets -Atc \"SELECT xact_commit FROM pg_stat_database WHERE datname = 'tickets'\""
}

cap_lag() {
  fresh
  run 'DELAY=2s docker compose up -d replica'
  sleep 3
  run 'curl -s -X POST localhost:8080/events/7/tickets; echo'
  run 'curl -s localhost:8080/events/7; echo'
  run 'sleep 2'
  run 'curl -s localhost:8080/events/7; echo'
}

cap_lsn() {
  fresh 2s
  sleep 1
  run 'curl -s -X POST localhost:8080/events/8/tickets; echo'
  LSN=$(docker compose exec db psql -U tickets -Atc 'SELECT pg_current_wal_lsn()' | tr -d '\r')
  printf 'ana@lab:~/tickets$ %s\n%s\n' "docker compose exec db psql -U tickets -Atc 'SELECT pg_current_wal_lsn()'" "$LSN"
  run "docker compose exec replica psql -U tickets -Atc \"SELECT pg_last_wal_replay_lsn() >= '$LSN'\""
  run 'sleep 2'
  run "docker compose exec replica psql -U tickets -Atc \"SELECT pg_last_wal_replay_lsn() >= '$LSN'\""
}

cap_failover() {
  fresh
  run 'docker compose stop db'
  run 'curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8080/events/1/tickets'
  run 'curl -s localhost:8080/events/1; echo'
  run "docker compose exec replica psql -U tickets -c 'SELECT pg_promote()'"
  run "docker compose exec replica psql -U tickets -c \"UPDATE events SET sold = sold + 1 WHERE id = 1 RETURNING sold\""
}

cap_partitions() {
  fresh
  run 'docker compose cp partitions.sql db:/tmp/partitions.sql'
  run 'docker compose exec db psql -U tickets -f /tmp/partitions.sql'
  run "docker compose exec db psql -U tickets -c 'SELECT tableoid::regclass AS partition, count(*) FROM sales GROUP BY 1 ORDER BY 1'"
  run "docker compose exec db psql -U tickets -c \"EXPLAIN (COSTS OFF) SELECT count(*) FROM sales WHERE sold_at >= '2026-06-01'\""
}

cap_retention() {
  run 'docker compose cp retention.sql db:/tmp/retention.sql'
  run 'docker compose exec db psql -U tickets -f /tmp/retention.sql'
}

cap_sharding() {
  docker compose down >/dev/null 2>&1
  run 'docker compose -f shards.yaml up -d'
  run 'docker compose -f shards.yaml run --rm router 2>/dev/null'
  run 'docker compose -f shards.yaml down' >/dev/null
}

cap_keys() {
  run 'python3 keys.py'
}

captures "$@"
docker compose down >/dev/null 2>&1
docker compose -f shards.yaml down >/dev/null 2>&1
