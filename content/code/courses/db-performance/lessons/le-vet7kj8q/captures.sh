#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of db-performance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # the machine lesson 1's captures built
#   sudo bash captures.sh
#
# It starts where every lesson from 3 on starts (lab.sh reset). lab.sh reset
# removes ~/workload, so lesson 2's six scripts are written again from lesson
# 2's a-workload.md, and this lesson's two files from its own your-workload.md,
# exactly as printed.
#
# STAGED: "drop the cache" in the-traps is run as root on the computer hosting
# the container, because a container cannot write to /proc/sys/vm/drop_caches.
# In a virtual machine the command printed does it. The runs of place-order.sql
# add orders; the lesson ends by telling the student to run ~/reset-market.sh.
# The repeat block starts from ~/reset-market.sh, so it does not depend on the
# blocks before it; it was recorded in a second run of this script from lab
# reset, with the blocks above it left out.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh
FENCE=../../lab/fence.py
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@vm:~$ %s\n' "$*"; lab as "$*" 2>&1 || true; }
onw() { printf 'ana@vm:~/workload$ %s\n' "$*"; lab as "cd ~/workload && $*" 2>&1 || true; }
session() { lab psql "$@"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/db-performance-capture.lock; flock 9

lab reset
python3 "$FENCE" ../le-9kwvr0x4/a-workload.md 'mkdir -p ~/workload' | lab as 'bash' >/dev/null
python3 "$FENCE" your-workload.md 'cat > ~/workload/weights.sql' | lab as 'bash'
python3 "$FENCE" your-workload.md 'cat > ~/workload/seller-dashboard-skewed.sql' | lab as 'bash'
W="-f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1"

block bench-init
on 'createdb bench'
on 'pgbench -i -s 10 bench'

block bench-script
on 'pgbench --show-script=tpcb-like'

block bench-run
on 'pgbench -c 8 -j 4 -T 30 bench'
on 'dropdb bench'

block weights
printf "SELECT pg_stat_statements_reset();\n" | session market
onw "pgbench -n -c 8 -j 4 -T 60 $W market > /dev/null"
on 'psql market -f ~/workload/weights.sql'

block skewed
onw 'pgbench -n -c 8 -j 4 -T 20 -f seller-dashboard.sql market | grep -E "^(tps|latency)"'
onw 'pgbench -n -c 8 -j 4 -T 20 -f seller-dashboard-skewed.sql market | grep -E "^(tps|latency)"'

block report
onw "pgbench -n -c 8 -j 4 -T 30 -P 10 -r $W market"

block cold
on 'sudo systemctl restart postgresql'
printf '%s\n' 'ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"'
sync; echo 3 > /proc/sys/vm/drop_caches
onw "pgbench -n -c 8 -j 4 -T 30 -P 5 $W market | grep -E '^(progress|tps)'"

block client-cpu
onw "time pgbench -n -c 8 -j 4 -T 30 $W market | grep -E '^tps'"
on 'nproc'

block sizes
printf "SELECT pg_size_pretty(pg_database_size('market'));\n" | session market
on 'free -h'

block rate
onw "pgbench -n -c 8 -j 4 -T 30 -R 900 $W market | grep -E '^(tps|latency|rate)'"

block repeat
on '~/reset-market.sh'
for i in 1 2 3; do
  onw "pgbench -n -c 8 -j 4 -T 30 $W market | grep -E '^(tps|latency average)'"
done
