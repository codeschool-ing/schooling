#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of gcp-data (Cloud SQL), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THERE IS NO CLOUD SQL HERE. No emulator exists, and nothing in this script
# creates, patches or connects to an instance. Two kinds of block are run:
# `gcloud ... --help`, which reads the command line's own reference and needs no
# network, and PostgreSQL 16 itself, the engine under Cloud SQL for PostgreSQL,
# run on the laptop as the lesson's "database-flags" section has the student run
# it. sqlcost.py is read out of what-it-costs.md.
#
# STAGED:
#   - postgresql-16 (16.15) is installed from Ubuntu on the recording machine;
#     the lesson's `apt-get install` and `systemctl disable` lines are shown to
#     the student and not run here.
#   - initdb refuses to run as root, and the recording machine runs everything as
#     root. Inside this run's private mount namespace, a user `ana` is added to a
#     copy of /etc/passwd and /etc/group bind-mounted over the real ones, ~/gcp is
#     given to that user on the run's throwaway overlay, and every PostgreSQL
#     command is run as `ana` with runuser. The prompt and the transcripts are
#     what the student's own terminal shows; no uid appears in them.
#   - the second ```sh fence of database-flags.md (the PATH and PG* variables)
#     is read out of the lesson and exported, as the student types it.
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

# ---- an-instance --------------------------------------------------------------
block help-version
run "gcloud sql instances create --help | sed -n '/^     --database-version=/,/^\$/p'"
block help-edition
run "gcloud sql instances create --help | sed -n '/^     --edition=/,/^\$/p'"
run "gcloud sql instances create --help | sed -n '/^        Enterprise Edition: Use --tier/,/C4A series/p'"

# ---- database-flags -----------------------------------------------------------
as_ana || exit 1
eval "$(fence "$HERE/database-flags.md" 2)"
export PATH PGHOST PGPORT PGUSER
block pg-init
runa 'initdb -D ~/gcp/pg/orders -U postgres --auth=trust'
runa 'pg_ctl -D ~/gcp/pg/orders -o "-p 5433 -k $HOME/gcp/pg" -l ~/gcp/pg/orders.log start'
runa "psql -Atc 'SELECT version()'"
block pg-show
runa "psql -c \"SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('max_connections', 'shared_buffers', 'work_mem', 'log_min_duration_statement') ORDER BY name\""
block pg-reload
runa "psql -c \"ALTER SYSTEM SET log_min_duration_statement = '500ms'\" -c 'SELECT pg_reload_conf()' -c 'SHOW log_min_duration_statement'"
block pg-restart
runa "psql -c 'ALTER SYSTEM SET max_connections = 400' -c 'SELECT pg_reload_conf()' -c 'SHOW max_connections'"
runa "psql -c \"SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'max_connections'\""
runa 'cat ~/gcp/pg/orders/postgresql.auto.conf'
runa 'pg_ctl -D ~/gcp/pg/orders -l ~/gcp/pg/orders.log restart -m fast'
runa "psql -Atc 'SHOW max_connections'"
block pg-typo
runa "psql -c 'ALTER SYSTEM SET max_conections = 400'"
runa "psql -c \"ALTER SYSTEM SET work_mem = '64 potatoes'\""
block pg-role
runa "psql -c 'CREATE ROLE quitanda_app LOGIN'"
runa "psql -U quitanda_app -d postgres -c \"ALTER SYSTEM SET work_mem = '64MB'\""
runa "psql -U quitanda_app -d postgres -c \"SET work_mem = '64MB'\" -c 'SHOW work_mem'"
runa 'pg_ctl -D ~/gcp/pg/orders stop'

# ---- what-it-costs ------------------------------------------------------------
file_fence "$HERE/what-it-costs.md" sqlcost.py > ~/gcp/sqlcost.py || exit 1
block cost
run 'python3 sqlcost.py'
run "python3 -c 'print(round(2 * 0.105 * 730, 2))'"
