#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of gcp-data (high availability, read
# replicas and point-in-time recovery), as a script that produces them. Every
# transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THERE IS NO CLOUD SQL HERE, and nothing below fails over, replicates or
# restores a Cloud SQL instance. Two kinds of block are run: `gcloud ... --help`,
# the command line's own reference, which needs no network; and PostgreSQL 16,
# the engine under Cloud SQL for PostgreSQL, on the laptop: a primary on 5433,
# a streaming replica of it on 5434, WAL archiving, and a recovery to a moment
# on 5435. The lesson says beside each block that it is the engine.
#
# STAGED:
#   - postgresql-16 (16.15) is installed from Ubuntu on the recording machine.
#   - initdb refuses to run as root, and the recording machine runs everything
#     as root. Inside this run's private mount namespace a user `ana` is added
#     to copies of /etc/passwd and /etc/group bind-mounted over the real ones,
#     ~/gcp is given to that user on the run's throwaway overlay, and every
#     PostgreSQL command runs as `ana` with runuser. No uid appears in a
#     transcript.
#   - the cluster ~/gcp/pg/orders is in the state lesson 6 leaves it: made with
#     lesson 6's initdb line and the two ALTER SYSTEM settings of its
#     database-flags section, then stopped. That is done quietly before the
#     first block. The PATH and PG* variables are lesson 6's fence, exported.
#   - a pause of six seconds after the primary restarts in point-in-time, so the
#     replica has reconnected, as it has by the time a person types the next line.
#   - the moment the restore aims at is the one the transcript printed just
#     before the DELETE; the capture reads it into a variable, and the command
#     that writes it into the configuration shows it written out, as the
#     student types it.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1

as_ana() {
  local pw gr; pw=$(mktemp); gr=$(mktemp)
  chmod 644 "$pw" "$gr"; cp /etc/passwd "$pw"; echo 'ana:x:1500:1500::/home/ana:/bin/bash' >> "$pw"
  cp /etc/group "$gr"; echo 'ana:x:1500:' >> "$gr"
  mount --bind "$pw" /etc/passwd && mount --bind "$gr" /etc/group || return 1
  chown ana:ana /home/ana /home/ana/gcp
}
runa() {
  printf 'ana@laptop:~/gcp$ %s\n' "$*"
  runuser -p -u ana -- bash -c "cd ~/gcp && $*" 2>&1 | sed 's/.*\r//' || true
}
quiet() { runuser -p -u ana -- bash -c "cd ~/gcp && $*" > /dev/null 2>&1; }

# ---- regional-ha and backups: the reference ----------------------------------
block help-availability
run "gcloud sql instances create --help | sed -n '/^     --availability-type=/,/This is the default/p'"
block help-retention
run "gcloud sql instances create --help | sed -n '/^     --retained-backups-count=/,/^\$/p;/^     --retained-transaction-log-days=/,/^\$/p'"
run "gcloud sql instances create --help | sed -n '/^     --\\[no-\\]retain-backups-on-delete/,/^\$/p'"
block help-clone
run "gcloud sql instances clone --help | sed -n '/^       --point-in-time=/,/^\$/p'"

# ---- staged: lesson 6's cluster -------------------------------------------------
as_ana || exit 1
eval "$(fence "$LESSONS/le-sdqcdpfm/database-flags.md" 2)"
export PATH PGHOST PGPORT PGUSER
quiet 'initdb -D ~/gcp/pg/orders -U postgres --auth=trust' || { echo "initdb failed"; exit 1; }
quiet 'pg_ctl -D ~/gcp/pg/orders -o "-p 5433 -k $HOME/gcp/pg" -l ~/gcp/pg/orders.log start'
quiet "psql -c \"ALTER SYSTEM SET log_min_duration_statement = '500ms'\" -c 'ALTER SYSTEM SET max_connections = 400'"
quiet 'pg_ctl -D ~/gcp/pg/orders stop'

# ---- replica-lag --------------------------------------------------------------
block primary
runa 'pg_ctl -D ~/gcp/pg/orders -o "-p 5433 -k $HOME/gcp/pg" -l ~/gcp/pg/orders.log start'
runa "psql -c 'CREATE TABLE orders (id bigint PRIMARY KEY, customer text NOT NULL, total_cents integer NOT NULL, created timestamptz NOT NULL DEFAULT now())' -c \"INSERT INTO orders (id, customer, total_cents) SELECT g, 'c-' || g % 50, 1000 + g FROM generate_series(1, 1000) g\""
block replica
runa 'pg_basebackup -D ~/gcp/pg/reports -R -X stream -c fast'
runa 'ls ~/gcp/pg/reports | head -4 && ls ~/gcp/pg/reports/standby.signal && grep primary_conninfo ~/gcp/pg/reports/postgresql.auto.conf | cut -c1-80'
runa 'pg_ctl -D ~/gcp/pg/reports -o "-p 5434 -k $HOME/gcp/pg" -l ~/gcp/pg/reports.log start'
runa "psql -p 5434 -Atc 'SELECT pg_is_in_recovery(), count(*) FROM orders'"
runa "psql -c 'SELECT application_name, state, sync_state FROM pg_stat_replication'"
block readonly
runa "psql -p 5434 -c \"INSERT INTO orders (id, customer, total_cents) VALUES (5001, 'c-7', 4590)\""
block lag
runa "psql -p 5434 -c 'SELECT pg_wal_replay_pause()'"
runa "psql -c \"INSERT INTO orders (id, customer, total_cents) SELECT g, 'c-' || g % 50, 1000 + g FROM generate_series(1001, 1100) g\""
runa "psql -Atc 'SELECT count(*) FROM orders' && psql -p 5434 -Atc 'SELECT count(*) FROM orders'"
runa "psql -c 'SELECT pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind, replay_lag FROM pg_stat_replication'"
runa "psql -p 5434 -c 'SELECT pg_wal_replay_resume()' && sleep 1 && psql -p 5434 -Atc 'SELECT count(*) FROM orders'"
runa "psql -c 'SELECT pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication'"

# ---- point-in-time ------------------------------------------------------------
block archive
runa 'mkdir -p ~/gcp/pg/archive'
runa "psql -c 'ALTER SYSTEM SET archive_mode = on' -c \"ALTER SYSTEM SET archive_command = 'test ! -f ../archive/%f && cp %p ../archive/%f'\""
runa 'pg_ctl -D ~/gcp/pg/orders -l ~/gcp/pg/orders.log restart -m fast'
runa "psql -Atc 'SHOW archive_mode'"
sleep 6   # STAGED: the replica reconnects after the primary's restart within a few seconds
runa "psql -Atc 'SELECT state FROM pg_stat_replication'"
block base
runa 'pg_basebackup -D ~/gcp/pg/base -c fast && ls ~/gcp/pg/archive'
block mistake
T=$(runuser -p -u ana -- psql -Atc "SELECT now()")
printf 'ana@laptop:~/gcp$ %s\n' "psql -Atc 'SELECT now()'"; echo "$T"
sleep 1
runa "psql -c 'DELETE FROM orders' -c 'SELECT pg_switch_wal()' > /dev/null && sleep 1 && psql -Atc 'SELECT count(*) FROM orders' && psql -p 5434 -Atc 'SELECT count(*) FROM orders'"
runa 'ls ~/gcp/pg/archive'
block restore
runa 'cp -a ~/gcp/pg/base ~/gcp/pg/restored && touch ~/gcp/pg/restored/recovery.signal'
runa "printf \"restore_command = 'cp ../archive/%%f %%p'\\nrecovery_target_time = '$T'\\nrecovery_target_action = 'promote'\\n\" >> ~/gcp/pg/restored/postgresql.auto.conf && tail -3 ~/gcp/pg/restored/postgresql.auto.conf"
runa 'pg_ctl -D ~/gcp/pg/restored -o "-p 5435 -k $HOME/gcp/pg" -l ~/gcp/pg/restored.log start'
runa "sleep 2 && grep -E 'starting point-in-time|recovery stopping|selected new timeline' ~/gcp/pg/restored.log | cut -d' ' -f4-"
runa "psql -p 5435 -Atc 'SELECT count(*), max(id) FROM orders'"
runa "pg_ctl -D ~/gcp/pg/restored stop && pg_ctl -D ~/gcp/pg/reports stop && pg_ctl -D ~/gcp/pg/orders stop"

# ---- the bill ----------------------------------------------------------------
block cost
run "python3 -c 'h = 730; print(round((2 * 0.062 + 8 * 0.0105) * h + 100 * 0.255, 2), round((2 * 0.1239 + 8 * 0.021) * h + 100 * 0.51, 2), round(20 * 30 * 0.14, 2), round(130 * 0.12, 2))'"
