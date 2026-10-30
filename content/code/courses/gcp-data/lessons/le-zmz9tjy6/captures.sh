#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of gcp-data (Datastream, Database
# Migration Service, BigQuery Data Transfer Service, and change data capture),
# as a script that produces them. Every transcript in the lesson was copied
# from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S, and this script starts where a student is after "Every
# time you open a terminal". There is no emulator and no control plane for
# Datastream, Database Migration Service or the Data Transfer Service, and the
# lesson marks every command that would need one as not run; what is read from
# the installed command line is its own help, which needs no network.
#
# THE CDC SECTION RUNS A REAL POSTGRESQL 16, Ubuntu's postgresql-16 package
# (16.15), which the student installs with apt-get as the section says (STAGED:
# already installed on the recording machine). The student runs the throwaway
# server as themselves. The recording machine runs everything as root, and
# initdb refuses to run as root, so the first sh fence of cdc-for-real.md is run
# as the unprivileged system user `postgres` with HOME=/home/ana, and ~/gcp/cdc
# is created and handed to that user first (STAGED). No transcript shows an
# owner, a uid or a user name of the system: the psql commands connect over the
# socket in ~/gcp/cdc as the database user `postgres`, exactly as the
# student's do, with the PG* variables of that fence's last line.
#
# The program the student saves, datastream_bill.py, is read out of its example
# in cutover-and-cost.md.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-zmz9tjy6"

# ---- streams-and-profiles: what the command line accepts -------------------------
block help-sources
run "gcloud datastream streams create --help | grep -oE -- '--[a-z-]+-source-config' | sort -u"
block help-pgconfig
run "gcloud datastream streams create --help | grep -E '\"(replicationSlot|publication)\"'"

# ---- cdc-for-real: a real PostgreSQL 16, as the student starts it -------------
mkdir -p ~/gcp/cdc && chown postgres: ~/gcp/cdc
runuser -u postgres -- env HOME=/home/ana bash -e -c "$(fence "$L/cdc-for-real.md" 2)" > /dev/null || exit 1
eval "$(fence "$L/cdc-for-real.md" 2 | grep '^export PG')"
block cdc-setup
run 'psql -c "SHOW wal_level"'
run "psql -c \"CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text NOT NULL, total_cents integer NOT NULL)\" -c \"INSERT INTO orders VALUES ('ord-1', 'c-17', 4590)\""
run 'psql -c "CREATE PUBLICATION datastream_pub FOR TABLE orders"'
run "psql -c \"SELECT slot_name, lsn FROM pg_create_logical_replication_slot('datastream_orders', 'pgoutput')\" -c \"SELECT slot_name, lsn FROM pg_create_logical_replication_slot('look', 'test_decoding')\""
block cdc-peek
run "psql -c \"INSERT INTO orders VALUES ('ord-2', 'c-03', 12800)\" -c \"UPDATE orders SET total_cents = 4990 WHERE order_id = 'ord-1'\" -c \"DELETE FROM orders WHERE order_id = 'ord-2'\""
run "psql -Atc \"SELECT lsn, xid, data FROM pg_logical_slot_peek_changes('look', NULL, NULL)\""
block cdc-pgoutput
run "psql -c \"SELECT lsn, xid, chr(get_byte(data, 0)) AS kind, length(data) AS bytes FROM pg_logical_slot_peek_binary_changes('datastream_orders', NULL, NULL, 'proto_version', '1', 'publication_names', 'datastream_pub')\""
block cdc-get
run "psql -Atc \"SELECT data FROM pg_logical_slot_get_changes('look', NULL, NULL)\""
run "psql -Atc \"SELECT count(*) FROM pg_logical_slot_get_changes('look', NULL, NULL)\""
block cdc-identity
run "psql -c \"ALTER TABLE orders REPLICA IDENTITY FULL\" -c \"UPDATE orders SET total_cents = 5190 WHERE order_id = 'ord-1'\""
run "psql -Atc \"SELECT xid, data FROM pg_logical_slot_get_changes('look', NULL, NULL)\""
block cdc-retained
run "psql -c \"INSERT INTO orders SELECT 'bulk-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 20000) g\""
run "psql -c \"SELECT slot_name, plugin, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots\""
run "psql -Atc \"SELECT pg_drop_replication_slot('look')\""
block cdc-cap
run "psql -c \"ALTER SYSTEM SET max_slot_wal_keep_size = '32MB'\" -c \"SELECT pg_reload_conf()\""
run "psql -c \"INSERT INTO orders SELECT 'more-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 400000) g\""
run "psql -c \"SELECT slot_name, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained, pg_size_pretty(safe_wal_size) AS safe FROM pg_replication_slots\""
run 'psql -c "CHECKPOINT" -c "SELECT slot_name, wal_status FROM pg_replication_slots"'
run "psql -c \"SELECT count(*) FROM pg_logical_slot_peek_binary_changes('datastream_orders', NULL, NULL, 'proto_version', '1', 'publication_names', 'datastream_pub')\""
run "psql -Atc \"SELECT pg_drop_replication_slot('datastream_orders')\" -c \"SELECT count(*) FROM pg_replication_slots\""
runuser -u postgres -- env HOME=/home/ana PG=/usr/lib/postgresql/16/bin bash -c "$(fence "$L/cdc-for-real.md" 3)" > /dev/null 2>&1
# the second line of that fence cannot remove ~/gcp/cdc itself here, whose
# parent belongs to root; the throwaway layer over ~ana goes with the run anyway

# ---- cutover-and-cost: the program, read out of the lesson ------------------------
example "$L/cutover-and-cost.md" datastream_bill.py datastream_bill.py || exit 1
block bill
run 'python3 datastream_bill.py'
