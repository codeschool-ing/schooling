#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of scale. Each block of output
# starts with `##### <name>`; the prose quotes the blocks byte for byte.
#
#   bash captures.sh [block ...] > captures.out   (as root, after lab.sh prepare)
#
# STAGED rather than typed:
#   - ~/tickets is written by `lab.sh stage 3` from the blocks of lessons 1
#     to 3, so the files are the ones the lessons show;
#   - every block that needs the stack starts it itself, from nothing;
#   - the partition is `docker network disconnect` of the replica from the
#     `replication` network, exactly as the section tells the student to do,
#     and the reconnection waits ten seconds, shown as `sleep 10`, because
#     the replica retries its connection every five.
# Recorded 2026-10-10 on the machine lab.sh describes.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/lib.sh"
bash "$LAB" stage 3 || exit 1
cd "$HOME/tickets"
fresh() { docker compose down >/dev/null 2>&1; docker compose build -q >/dev/null 2>&1; docker compose up -d >/dev/null 2>&1; sleep 3; }
SYNC_ON="docker compose exec db psql -U tickets -c \"ALTER SYSTEM SET synchronous_standby_names = '*'\" -c 'SELECT pg_reload_conf()'"

cap_bench_async() {
  fresh
  run 'docker compose exec db pgbench -U tickets -i -s 4 -q tickets'
  run "docker compose exec db psql -U tickets -c 'SELECT sync_state FROM pg_stat_replication'"
  run 'docker compose exec db pgbench -U tickets -n -c 4 -T 10 tickets'
}

cap_bench_sync() {
  run "$SYNC_ON"
  run "docker compose exec db psql -U tickets -c 'SELECT sync_state FROM pg_stat_replication'"
  run 'docker compose exec db pgbench -U tickets -n -c 4 -T 10 tickets'
}

cap_partition_sync() {
  fresh
  bash -c "$SYNC_ON" >/dev/null 2>&1; sleep 1
  run 'docker network disconnect tickets_replication tickets-replica-1'
  run 'curl -s -m 5 -X POST localhost:8080/events/1/tickets; echo "curl exit: $?"'
  run 'curl -s localhost:8080/events/1; echo'
  run "docker compose exec db psql -U tickets -c \"SELECT wait_event, query FROM pg_stat_activity WHERE wait_event = 'SyncRep'\""
  run "docker compose exec db psql -U tickets -c 'SELECT sold FROM events WHERE id = 1'"
  run 'docker network connect tickets_replication tickets-replica-1'
  run 'sleep 10'
  run "docker compose exec db psql -U tickets -c 'SELECT sold FROM events WHERE id = 1'"
  run 'curl -s localhost:8080/events/1; echo'
}

cap_partition_async() {
  fresh
  run 'docker network disconnect tickets_replication tickets-replica-1'
  run 'curl -s -m 5 -X POST localhost:8080/events/1/tickets; echo'
  run 'curl -s localhost:8080/events/1; echo'
  run 'sleep 5'
  run 'curl -s localhost:8080/events/1; echo'
  run 'docker network connect tickets_replication tickets-replica-1'
  run 'sleep 10'
  run 'curl -s localhost:8080/events/1; echo'
}

cap_quorum() {
  run 'python3 quorum.py'
}

cap_merge() {
  run 'python3 merge.py'
}

captures "$@"
docker compose down >/dev/null 2>&1
