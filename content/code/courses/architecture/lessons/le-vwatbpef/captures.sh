#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# Three labs, one after the other, each EXTRACTED from the section that shows
# it, as the copy button hands the files over: ~/lab/replication from
# measuring-lag.md, ~/lab/kafka-cluster from a-kafka-cluster.md and ~/lab/shards
# from sharding.md. The shell definitions those sections give (P and S, the
# kafka function, R) are extracted the same way and set in every command.
# Staged: the shards' tools image is built beforehand (lab.sh, "prebuild").
# Waits: 15 seconds for PostgreSQL, 30 for the Kafka nodes, 10 for the shards.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-vwatbpef
defs() { # defs SECTION.md: the shell definitions the section tells the student to type
  python3 - "$COURSE/lessons/$L/$1" <<'PY'
import re, sys
md = open(sys.argv[1]).read()
print(" && ".join(l for l in re.findall(r"^(?:[PSR]=\".*\"|kafka\(\) \{.*\})$", md, re.M)))
PY
}
drun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && export COLUMNS=100 NO_COLOR=1 && $DEFS && { $1 ; }" 2>&1 || true; }
lab reset

at '~/lab/replication'
for f in replication.sh compose.yaml; do save $L/measuring-lag.md $f "~/lab/replication/$f"; done
DEFS=$(defs measuring-lag.md)
quiet 'docker compose up -d'
sleep 15
block rep-up
drun '$P -x -c "SELECT state, sent_lsn, write_lsn, flush_lsn, replay_lsn, write_lag, flush_lag, replay_lag FROM pg_stat_replication"'
block rep-load
drun 'docker compose exec -T primary pgbench -i -q -U postgres postgres'
drun 'docker compose exec -d primary pgbench -T 20 -c 8 -U postgres postgres'
drun 'sleep 8; $P -c "SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication"'
sleep 15
block rep-pause
drun '$S -c "SELECT pg_wal_replay_pause()"'
drun '$P -c "INSERT INTO pgbench_history SELECT 1, 1, 1, 0, now() FROM generate_series(1, 200000)"'
drun '$P -c "SELECT replay_lag, pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS behind FROM pg_stat_replication"'
drun '$S -c "SELECT count(*) FROM pgbench_history" -c "SELECT now() - pg_last_xact_replay_timestamp() AS last_replayed"'
block rep-resume
drun '$S -c "SELECT pg_wal_replay_resume()"'
drun 'sleep 3; $P -c "SELECT replay_lag, pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS behind FROM pg_stat_replication"'
drun '$S -c "SELECT count(*) FROM pgbench_history"'
quiet 'docker compose down -v'

at '~/lab/kafka-cluster'
save $L/a-kafka-cluster.md compose.yaml '~/lab/kafka-cluster/compose.yaml'
DEFS=$(defs a-kafka-cluster.md)
quiet 'docker compose up -d'
sleep 30
block k-quorum
drun 'kafka metadata-quorum describe --status'
block k-create
drun 'kafka topics --create --topic orders --partitions 3 --replication-factor 3 --config min.insync.replicas=2'
drun 'kafka topics --describe --topic orders'
block k-stop-one
drun 'docker compose stop kafka-2'
drun 'kafka topics --describe --topic orders'
drun 'printf "o-1\no-2\no-3\n" | kafka console-producer --topic orders --producer-property acks=all'
block k-stop-two
drun 'docker compose stop kafka-3'
drun 'kafka topics --describe --topic orders'
drun 'printf "o-4\n" | kafka console-producer --topic orders --producer-property acks=all'
block k-acks-one
drun 'printf "o-5\n" | kafka console-producer --topic orders --producer-property acks=1'
block k-back
drun 'docker compose start kafka-2 kafka-3'
drun 'sleep 15; kafka topics --describe --topic orders'
drun 'kafka console-consumer --topic orders --from-beginning --timeout-ms 20000 2>/dev/null | sort'
quiet 'docker compose down -v'

at '~/lab/shards'
for f in schema.sql shard.py Dockerfile compose.yaml; do save $L/sharding.md $f "~/lab/shards/$f"; done
DEFS=$(defs sharding.md)
prebuild
quiet 'docker compose up -d'
sleep 10
block s-load
drun '$R load'
drun '$R customer c-7'
block s-order
drun '$R order 1234'
block s-top
drun '$R top --naive'
drun '$R top'
block s-moves
drun '$R moves 3'
quiet 'docker compose down -v'
