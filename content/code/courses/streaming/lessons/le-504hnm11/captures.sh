#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of streaming (change data capture
# with Debezium), as a script that produces them. Its output is not committed.
#
#   sudo bash ../../lab.sh install le-504hnm11 installing-debezium.md   (once)
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-504hnm11.out 2>&1
#
# STAGED, not typed, and said here:
# - This machine has no systemd. The student's `sudo systemctl restart
#   postgresql` was NOT run; PostgreSQL 16's cluster `main` is (re)started
#   here with `pg_ctlcluster 16 main restart`, which is what that unit runs.
#   On a VM, apt starts the cluster at install and systemd at every boot.
# - postgresql-16 was already present in this container, so the install
#   section's `apt-get install postgresql` only added the metapackage; on a
#   fresh VM it downloads the server as well.
# - Before the first block the lab is emptied: a new one-node Kafka cluster,
#   any Connect process stopped, and the database `pontofinal`, its slot and
#   the roles `ubuntu` and `cdc` dropped, with connect.offsets removed, so the
#   lesson's commands run as on a machine that never had them.
# - Kafka Connect runs in a second terminal; its log (hundreds of lines) is
#   not quoted. How many lines it printed goes to /tmp/le-504hnm11.meta.
# - Waits between commands (for Connect to answer, for events to arrive) are
#   the script's, not typed.
. "$(dirname "$0")/../../lab/capture-lib.sh"
META=/tmp/le-504hnm11.meta; : > "$META"

# The programs this lesson tells the student to save, extracted from its own .md
# exactly as `lab.sh files` does (same pattern), so the capture runs the lesson's text
# even while another lesson's draft stops `lab.sh files`.
myfiles() {
  python3 - "$(cd "$(dirname "$0")" && pwd)" <<'PY'
import glob, json, os, re, sys
pat = re.compile(r"^[^\n]*`~/work/([\w.-]+)`[^\n]*:\n\n```([\w-]*)\n(.*?)^```$", re.S | re.M)
for md in sorted(glob.glob(sys.argv[1] + "/*.md")):
    if md.endswith(".pt.md"): continue
    for name, lang, body in pat.findall(open(md, encoding="utf-8").read()):
        if lang == "schooling-example":
            body = "\n".join(p["code"] for p in json.loads(body)["parts"]) + "\n"
        open("/home/ubuntu/work/" + name, "w", encoding="utf-8").write(body)
        os.chown("/home/ubuntu/work/" + name, 1000, 1000)
        print(name, file=sys.stderr)
PY
}
myfiles

pkill -u ubuntu -f '^[^ ]*java .*ConnectStandalone' || true; sleep 2
lab reset 1
pg_ctlcluster 16 main stop 9>&- 2>/dev/null; pg_ctlcluster 16 main start 9>&-   # stands in for: sudo systemctl restart postgresql
sudo -u postgres psql -q -c "SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots" >/dev/null
sudo -u postgres psql -q -c "DROP DATABASE IF EXISTS pontofinal" -c "DROP ROLE IF EXISTS cdc" -c "DROP ROLE IF EXISTS ubuntu" 2>&1 | grep -v NOTICE
run 'rm -f ~/work/connect.offsets' >/dev/null

connect_up() {   # wait until the connector and its task report RUNNING, and the snapshot is written
  run 'for i in $(seq 1 90); do curl -s localhost:8083/connectors/stock/status | grep -q "\"tasks\":\[{\"id\":0,\"state\":\"RUNNING\"" && break; sleep 1; done' >/dev/null
  sleep 6
}

# installing-debezium
block wal
home 'sudo -u postgres psql -c "SHOW wal_level"'
block sha
home 'sha512sum debezium-connector-postgres-3.7.0.Final-plugin.tar.gz | cut -d" " -f1'
home 'cat debezium-connector-postgres-3.7.0.Final-plugin.tar.gz.sha512; echo'
block jars
home 'ls ~/connect-plugins/debezium-connector-postgres/*.jar | xargs -n1 basename'

# a-connector
block roles
vm 'sudo -u postgres createuser --createdb ubuntu'
vm "sudo -u postgres psql -c \"CREATE ROLE cdc WITH LOGIN REPLICATION PASSWORD 'lab-only-password'\""
block db
vm 'createdb pontofinal'
vm 'psql -q pontofinal -f stock.sql'
vm 'psql pontofinal -c "SELECT count(*) AS rows, sum(qty) AS copies FROM stock"'
block connect-start
shown 'connect-standalone.sh connect.properties stock-connector.properties'
term2 connect 'connect-standalone.sh connect.properties stock-connector.properties' 3
connect_up
block status
vm 'curl -s localhost:8083/connectors/stock/status | jq .'
block topics
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --list'
block slot
vm 'psql pontofinal -c "SELECT slot_name, plugin, active FROM pg_replication_slots"'

# a-change-event
block snapshot
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --from-beginning --max-messages 1 | jq .'
block keys
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --from-beginning --max-messages 3 --formatter-property print.key=true --formatter-property print.value=false'
block insert
vm "psql pontofinal -c \"INSERT INTO books VALUES ('bk-09', 'Iracema', 3290)\""
sleep 3
block insert-read
vm "kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.books --partition 0 --offset 8 --max-messages 1 | jq -c '{op, before, after}'"

# updates-and-deletes
block update-delete
vm "psql pontofinal -c \"UPDATE stock SET qty = qty - 1 WHERE shop = 'recife' AND book = 'bk-02'\""
vm "psql pontofinal -c \"DELETE FROM stock WHERE shop = 'natal' AND book = 'bk-08'\""
sleep 3
block update-delete-read
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --partition 0 --offset 40 --max-messages 3 --formatter-property print.key=true'
block full
vm 'psql pontofinal -c "ALTER TABLE stock REPLICA IDENTITY FULL"'
block full-update
vm "psql pontofinal -c \"UPDATE stock SET qty = qty - 1 WHERE shop = 'recife' AND book = 'bk-02'\""
sleep 3
vm "kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pf.public.stock --partition 0 --offset 43 --max-messages 1 | jq -c '{op, before, after}'"

# the-slot-holds-wal
stop2 connect > /tmp/le-504hnm11.connect1
echo "connect, first run: $(wc -l < /tmp/le-504hnm11.connect1) lines" >> "$META"
SLOTQ='psql pontofinal -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"'
block slot-stopped
vm "$SLOTQ"
block slot-grows
vm 'psql pontofinal -c "CREATE TABLE notes AS SELECT g AS id, md5(g::text) AS body FROM generate_series(1, 200000) g"'
vm 'psql pontofinal -c "UPDATE stock SET qty = qty + 1"'
vm "$SLOTQ"
term2 connect2 'connect-standalone.sh connect.properties stock-connector.properties' 3
connect_up
block caught-up
vm 'kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic pf.public.stock'
block slot-back
vm "$SLOTQ"
block fuse
vm 'psql pontofinal -c "SHOW max_slot_wal_keep_size"'
echo "RSS MB, kafka+connect (java) / postgres: $(ps -u ubuntu -o rss=,cmd= | awk '/java/{s+=$1} END{print int(s/1024)}') / $(ps -u postgres -o rss= | awk '{s+=$1} END{print int(s/1024)}')" >> "$META"
stop2 connect2 > /tmp/le-504hnm11.connect2
echo "connect, second run: $(wc -l < /tmp/le-504hnm11.connect2) lines; snapshot lines: $(grep -c -i 'snapshot' /tmp/le-504hnm11.connect2)" >> "$META"
pg_ctlcluster 16 main stop 9>&-
