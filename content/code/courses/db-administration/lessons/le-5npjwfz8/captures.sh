#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where every lesson from 5 on starts: shop loaded. STAGED, as the
# lesson itself tells the student to do before the worked runbook: a physical
# replication slot, standby1, that no replica reads, and a table, filler, of
# 600,000 rows loaded into the database ana, so that pg_wal has grown and a
# slot is holding it. The lesson prints both commands and removes both at the
# end. The disk df reports is the recording computer's own, shared with other
# work; the lesson says so.
#
# The `note` lines are run without being shown, between the checks, as the
# lesson tells the student to; each one quotes what the check before it
# printed, read from the server at that moment, so the incident log at the end
# carries this run's own numbers and times.
set -uo pipefail
export LAB_NAME=${LAB_NAME:-db}
cd "$(dirname "$0")"
. ../../lab/capture.sh
L=le-5npjwfz8
D=/var/lib/postgresql/16/main

lab reset 5
lab as 'mkdir -p bin'
fence $L/the-log-of-the-night.md '#!/usr/bin/env bash' | lab as 'cat > bin/note && chmod +x bin/note'
note() { lab as "note $(printf '%q' "$*")"; }
q() { lab as "psql -XAtc $(printf '%q' "$1") ${2:-ana}"; }

# the staging the lesson prints
lab as "psql -qc \"SELECT pg_create_physical_replication_slot('standby1', true);\" >/dev/null"
lab as "psql -qc \"CREATE TABLE filler AS SELECT g AS id, repeat('x', 500) AS pad FROM generate_series(1, 600000) AS g;\""
sleep 2

note "Alert: disk under PostgreSQL filling on db. Opened runbook disk-filling."

block df
on 'df -h /var/lib/postgresql'
U=$(lab as "df --output=pcent /var/lib/postgresql | tail -1 | tr -d ' '")
note "df: $U used. Not 100%, writes still working."

block du
on "sudo du -h -d1 $D | sort -h | tail -4"
W=$(lab as "sudo du -sh $D/pg_wal | cut -f1")
B=$(lab as "sudo du -sh $D/base | cut -f1")
note "pg_wal $W, base $B. Looking at slots."

block slots
on "psql -c \"SELECT slot_name, slot_type, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots;\""
R=$(q "SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) FROM pg_replication_slots")
note "slot standby1: inactive, retaining $R. Asked its owner whether a replica still uses it."

block log
on 'sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log'
note "log: no errors, checkpoints started by WAL volume."

block sizes
on "psql -c \"SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;\""
on "psql -d ana -c \"SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC LIMIT 3;\""
F=$(q "SELECT pg_size_pretty(pg_total_relation_size('filler'))")
note "table filler in db ana, $F, created tonight. Not ours to delete: ticket for its owner."

note "standby1: owner confirms no replica uses it. Dropping it."
block act
on "psql -c \"SELECT pg_drop_replication_slot('standby1');\""
on 'psql -c "CHECKPOINT;"'
note "dropped standby1, ran CHECKPOINT."

block verify
on "psql -c \"SELECT count(*) AS slots FROM pg_replication_slots;\""
on "sudo du -sh $D/pg_wal"
on 'sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log'
W2=$(lab as "sudo du -sh $D/pg_wal | cut -f1")
U2=$(lab as "df --output=pcent /var/lib/postgresql | tail -1 | tr -d ' '")
note "verify: no slots. pg_wal $W2, recycled for reuse rather than removed, as expected. df $U2. Watching 15 min."
note "Closed. Follow-up: max_slot_wal_keep_size, and a check on slots in monitoring."

block incident-log
on 'cat incidents/$(date +%F).log'

block put-back
on 'psql -c "DROP TABLE filler;"'
lab as 'rm -rf bin incidents'

lab down
