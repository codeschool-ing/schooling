#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where lesson 3 starts (lab.sh reset). Lesson 2's workload is taken
# out of lesson 2's a-workload.md; curve.sh, the PgBouncer configuration, the
# userlist command and ~/.pgpass out of this lesson's own saturation.md and
# pgbouncer.md (the configuration is the code of the schooling-example block,
# joined), so the files shown are the files that ran.
#
# STAGED:
#   - PgBouncer is already installed in the lab machine, which has no network,
#     so `sudo apt install -y pgbouncer` is printed in the lesson and not run
#     here; `pgbouncer --version` shows what it installed. The lab keeps the
#     service stopped and disabled between lessons; the lesson's `systemctl
#     restart` starts it, as it would after apt.
#   - The idle connections in a-connection and the two sessions of pool-modes
#     are psql sessions typed at by lab/session.py in the background; they wait
#     for their next line by running a shell loop through psql's \! that is
#     typed and not printed (#quiet), until this script creates a file.
#   - Everything the lesson changes outside `market` is undone at the end, as
#     the lesson's last section tells the student to: the configuration file is
#     put back, the service stopped and disabled, the password and ~/.pgpass
#     removed.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, PgBouncer 1.22, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
L2=../le-9kwvr0x4
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
onw() { printf 'ana@vm:~/workload$ %s\n' "$*"; lab as "cd ~/workload && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
TMP=$(mktemp -d)
declare -A PID
start() { local n=$1; shift; lab as "rm -f /tmp/go-$n"; printf '%s\n' "$1" > "$TMP/$n.in"; shift
  session "$@" < "$TMP/$n.in" > "$TMP/$n" 2>&1 & PID[$n]=$!; }
go() { lab as "touch /tmp/go-$1"; wait "${PID[$1]}"; }
W() { printf '#quiet \\! while [ ! -f /tmp/go-%s ]; do sleep 0.2; done' "$1"; }
undo() {
  lab root 'systemctl disable --now pgbouncer >/dev/null 2>&1; [ -f /etc/pgbouncer/pgbouncer.ini.orig ] && mv /etc/pgbouncer/pgbouncer.ini.orig /etc/pgbouncer/pgbouncer.ini; : > /etc/pgbouncer/userlist.txt' || true
  lab as "rm -f ~/.pgpass; psql -qX market -c 'ALTER ROLE ana PASSWORD NULL'" >/dev/null 2>&1 || true
}
exec 9>/var/tmp/db-performance-capture.lock; flock 9
trap undo EXIT

lab reset
undo
python3 "$FENCE" "$L2/a-workload.md" 'mkdir -p ~/workload' | lab as 'bash' >/dev/null
python3 "$FENCE" saturation.md 'cat > ~/workload/curve.sh' | lab as 'bash'

# ---------------------------------------------------------------- a connection
block ps-0
on 'ps -u postgres -o pid,rss,cmd'
for i in 1 2 3; do start c$i "$(W c$i)" market; done
sleep 2
block ps-3
on 'ps -u postgres -o pid,rss,cmd'
block rss
on 'grep -E "^(VmRSS|RssAnon|RssShmem)" /proc/$(pgrep -f "ana market \[local\] idle" | head -1)/status'
block limits
printf "SHOW max_connections;\nSHOW superuser_reserved_connections;\nSELECT count(*) FROM pg_stat_activity;\n" | session market
go c1; go c2; go c3
block too-many
onw 'pgbench -n -c 110 -j 4 -T 10 -f customer-orders.sql market'

# ---------------------------------------------------------------- saturation
block curve
on '~/workload/curve.sh'

# ---------------------------------------------------------------- pgbouncer
block version
on 'pgbouncer --version'
python3 "$FENCE" pgbouncer.md 'sudo cp -p /etc/pgbouncer' | lab as 'bash'
python3 - pgbouncer.md <<'PY' > "$TMP/pgbouncer.ini"
import json, re, sys
s = open(sys.argv[1]).read()
b = re.search(r'```schooling-example\n(.*?)\n```', s, re.S).group(1)
sys.stdout.write(''.join(p['code'] for p in json.loads(b)['parts']) + '\n')
PY
lab root 'cat > /etc/pgbouncer/pgbouncer.ini' < "$TMP/pgbouncer.ini"
block password
printf "ALTER ROLE ana PASSWORD 'market-lab';\n" | session market
python3 "$FENCE" pgbouncer.md 'psql -XAt market -c' | lab as 'bash'
python3 "$FENCE" pgbouncer.md 'cat > ~/.pgpass' | lab as 'bash'
block userlist
on 'sudo cut -c1-40 /etc/pgbouncer/userlist.txt'
block start
on 'sudo systemctl restart pgbouncer'
on 'systemctl is-active pgbouncer'
block through
printf "SELECT current_user, inet_server_port(), pg_backend_pid();\n" | session market -h 127.0.0.1 -p 6432
block direct-200
onw 'pgbench -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market 2>&1 | head -4'
block pooled-200
start p1 "$(W p1)
SHOW POOLS;" pgbouncer -h 127.0.0.1 -p 6432
onw 'pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E "^(number of clients|number of transactions|latency average|tps)"' &
sleep 10; go p1; wait
block pools
cat "$TMP/p1"
block server-count
printf "SELECT count(*) FROM pg_stat_activity WHERE datname = 'market';\n" | session market

# ---------------------------------------------------------------- pool modes
start a "SET statement_timeout = '1s';
SELECT pg_backend_pid();
$(W a)
SHOW statement_timeout;
SELECT pg_backend_pid();" market -h 127.0.0.1 -p 6432
sleep 2
start b "BEGIN;
SELECT pg_backend_pid();
$(W b)
COMMIT;
SHOW statement_timeout;
SELECT pg_backend_pid();" market -h 127.0.0.1 -p 6432
sleep 2
go a
go b
block mode-a
cat "$TMP/a"
block mode-b
cat "$TMP/b"
block prepared
onw 'pgbench -h 127.0.0.1 -p 6432 -n -M prepared -c 4 -T 5 -f customer-orders.sql market 2>&1 | grep -E "error|processed" | head -3'
lab root "sed -i 's/^max_client_conn = 500$/max_client_conn = 500\nmax_prepared_statements = 100/' /etc/pgbouncer/pgbouncer.ini"
block prepared-on
on 'sudo systemctl reload pgbouncer'
onw 'pgbench -h 127.0.0.1 -p 6432 -n -M prepared -c 4 -T 5 -f customer-orders.sql market 2>&1 | grep -E "error|processed|^tps"'

# ---------------------------------------------------------------- sizing
block sizing
for n in 2 4 8 16 32; do
  printf 'ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = %s"\n' "$n"
  lab as "psql -X -h 127.0.0.1 -p 6432 pgbouncer -c 'SET default_pool_size = $n'" 2>&1
  lab as "psql -X -h 127.0.0.1 -p 6432 pgbouncer -c 'RECONNECT market'" >/dev/null 2>&1
  onw "pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'"
done

# ---------------------------------------------------------------- undo
block undo
on 'sudo systemctl disable --now pgbouncer'
on 'sudo mv /etc/pgbouncer/pgbouncer.ini.orig /etc/pgbouncer/pgbouncer.ini'
on 'sudo truncate -s 0 /etc/pgbouncer/userlist.txt'
on 'rm ~/.pgpass'
printf "ALTER ROLE ana PASSWORD NULL;\n" | session market
block reset
on '~/reset-market.sh'
rm -rf "$TMP"
