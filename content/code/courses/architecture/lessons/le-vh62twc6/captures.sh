#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of architecture, as a script that
# produces them. Its output is not committed: every transcript in the lesson was
# copied from a run of it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo bash captures.sh
#
# replication.sh and compose.yaml are EXTRACTED from the section "Two copies of
# the stock" (two-copies.md), as the copy button hands them over, and so are
# the two shell variables P and S that section defines: every command below runs
# with them set, as in the student's shell. The servers get 15 seconds to start.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"
L=le-vh62twc6
lab reset
at '~/lab/cap'
for f in replication.sh compose.yaml; do save $L/two-copies.md $f "~/lab/cap/$f"; done
VARS=$(python3 - "$COURSE/lessons/$L/two-copies.md" <<'PY'
import re, sys
md = open(sys.argv[1]).read()
print(re.search(r"```sh\n(P=.*?\nS=.*?)\n```", md, re.S).group(1).replace("\n", " && "))
PY
)
prun() { printf 'ana@vm:%s$ %s\n' "$HERE" "$1"; lab as "cd $(dir) && $VARS && { $1 ; }" 2>&1 || true; }
block up
run 'docker compose up -d'
sleep 15
run 'docker compose exec primary psql -U postgres -c "SELECT client_addr, state, sync_state FROM pg_stat_replication"'
block table
prun "\$P -c \"CREATE TABLE stock (sku text PRIMARY KEY, units int); INSERT INTO stock VALUES ('coffee', 12)\""
prun '$S -c "SELECT * FROM stock"'
prun "\$S -c \"UPDATE stock SET units = 0 WHERE sku = 'coffee'\""
block sync-on
prun "\$P -c \"ALTER SYSTEM SET synchronous_standby_names = '*'\" -c \"SELECT pg_reload_conf()\""
sleep 1
prun '$P -c "SELECT client_addr, state, sync_state FROM pg_stat_replication"'
block sync-cut
run 'docker network disconnect cap_default cap-standby-1'
prun "timeout 5 \$P -c \"UPDATE stock SET units = 11 WHERE sku = 'coffee'\"; echo \"exit code \$?\""
prun "\$P -c \"SELECT pid, wait_event, query FROM pg_stat_activity WHERE wait_event = 'SyncRep'\""
prun '$P -c "SELECT * FROM stock"'
prun '$S -c "SELECT * FROM stock"'
block sync-heal
run 'docker network connect cap_default cap-standby-1'
sleep 5
prun '$P -c "SELECT * FROM stock"'
prun '$S -c "SELECT * FROM stock"'
block async-cut
prun '$P -c "ALTER SYSTEM RESET synchronous_standby_names" -c "SELECT pg_reload_conf()"'
sleep 1
run 'docker network disconnect cap_default cap-standby-1'
prun "time \$P -c \"UPDATE stock SET units = 10 WHERE sku = 'coffee'\""
prun '$P -c "SELECT * FROM stock"'
prun '$S -c "SELECT * FROM stock"'
block async-heal
run 'docker network connect cap_default cap-standby-1'
sleep 5
prun '$S -c "SELECT * FROM stock"'
block timing
prun "\$P -c \"ALTER SYSTEM SET synchronous_standby_names = '*'\" -c \"SELECT pg_reload_conf()\" > /dev/null"
sleep 1
prun "time (for i in \$(seq 500); do echo \"UPDATE stock SET units = units WHERE sku = 'coffee';\"; done | \$P -q)"
prun '$P -c "ALTER SYSTEM RESET synchronous_standby_names" -c "SELECT pg_reload_conf()" > /dev/null'
sleep 1
prun "time (for i in \$(seq 500); do echo \"UPDATE stock SET units = units WHERE sku = 'coffee';\"; done | \$P -q)"
quiet 'docker compose down -v'
