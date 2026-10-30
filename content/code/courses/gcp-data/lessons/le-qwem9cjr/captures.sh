#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of gcp-data (Memorystore), as a
# script that produces them. Every transcript in the lesson was copied from its
# output.
#
#   sudo WHEELS=/var/tmp/gcplab/wheels-le-qwem9cjr bash ../../lab.sh run captures.sh
#
# THERE IS NO EMULATOR FOR MEMORYSTORE. What runs is the Redis that Ubuntu
# 24.04 packages (redis-server 7.0.15): the engine, not the service. The
# programs are read out of the lesson's own .md files, so the two cannot drift.
#
# STAGED, and why:
#   - redis-server was installed on the recording machine with the apt-get line
#     of a-local-redis.md. The student runs the server, and later its replica,
#     in terminals of their own, in the foreground; here the same commands, read
#     out of the lesson's fences, run with --daemonize yes inside the run's own
#     network namespace, and are shut down at the end.
#   - redis-cli prints `(integer) 1` and `(nil)` only to a terminal, and the
#     bare value to a pipe. Its blocks run under `script`, so the transcript
#     shows what the student's terminal shows.
#   - the run has no network, so `pip install -q redis==8.1.0` reads the wheel
#     fetched beforehand with `pip download redis==8.1.0` into WHEELS. The
#     command and what it prints are the student's.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$HERE"

runtty() {
  printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"
  script -qec "$*" /dev/null < /dev/null | sed 's/\r*$//; s/.*\r//' || true
}
wait_port() { for _ in $(seq 40); do redis-cli -p "$1" PING > /dev/null 2>&1 && return 0; sleep 0.25; done; return 1; }

# ---- engines-and-prices -------------------------------------------------------
block bill
run "python3 -c 'print(round(5 * 0.054 * 730, 2), round(5 * 0.103 * 730, 2), round(4 * 0.087 * 730, 2), round(4 * 0.146 * 730, 2))'"
run "python3 -c 'print(round(2 * 0.3054 * 730, 2), round(6 * 0.3054 * 730, 2), round((0.0795 + 4 * 0.007) * 730, 2))'"
run "python3 -c 'print(round(13 * 0.00087008 * 730, 2))'"

# ---- a-local-redis --------------------------------------------------------------
eval "$(fence "$L/a-local-redis.md" 2) --daemonize yes" > /dev/null || exit 1
wait_port 6379 || { echo "redis did not start"; exit 1; }

block redis-basics
runtty 'redis-cli PING'
runtty 'redis-cli INFO server | grep redis_version'
runtty "redis-cli SET product:p-101 '{\"name\":\"banana prata 1kg\",\"price_cents\":1290}' EX 300"
runtty 'redis-cli GET product:p-101'
runtty 'redis-cli TTL product:p-101'
runtty 'redis-cli EXPIRE product:p-101 5'
runtty 'sleep 6; redis-cli GET product:p-101'
runtty 'redis-cli TTL product:p-101'
runtty 'redis-cli SET visits 1'
runtty 'redis-cli TTL visits'

block redis-pip
run 'pip install -q redis==8.1.0'
run 'python3 -c "import redis; print(redis.__version__)"'

# ---- cache-aside ------------------------------------------------------------------
bash -e <(fence "$L/cache-aside.md" 1) || exit 1
example "$L/cache-aside.md" catalog.py catalog.py || exit 1
block cache-aside-read
run 'python3 catalog.py p-101 p-102 p-101'
runtty 'redis-cli TTL product:p-101'

block cache-aside-stale
run "python3 -c \"import sqlite3; db = sqlite3.connect('quitanda.db'); db.execute('UPDATE products SET price_cents = 1390 WHERE id = ?', ('p-101',)); db.commit()\""
run "python3 -c \"import sqlite3; print(sqlite3.connect('quitanda.db').execute('SELECT price_cents FROM products WHERE id = ?', ('p-101',)).fetchone())\""
run 'python3 catalog.py p-101'

block cache-aside-fixed
run 'python3 catalog.py price p-101 1390'
run 'python3 catalog.py p-101'

# ---- eviction-and-herds -------------------------------------------------------------
file_fence "$L/eviction-and-herds.md" fill.py > fill.py || exit 1
block evict-limit
runtty 'redis-cli CONFIG GET maxmemory-policy'
runtty 'redis-cli CONFIG SET maxmemory 2mb'

block evict-noeviction
run 'python3 fill.py 1 3000'
runtty 'redis-cli DBSIZE'
runtty 'redis-cli SET product:p-102 990'

block evict-volatile
runtty 'redis-cli CONFIG SET maxmemory-policy volatile-lru'
run 'python3 fill.py 3001 1000'

block evict-lru
runtty 'redis-cli CONFIG SET maxmemory-policy allkeys-lru'
run 'python3 fill.py 3001 3000'
runtty 'redis-cli DBSIZE'
runtty 'redis-cli INFO stats | grep evicted_keys'
runtty 'redis-cli EXISTS filler:1'

example "$L/eviction-and-herds.md" herd.py herd.py || exit 1
runtty 'redis-cli CONFIG SET maxmemory 0' > /dev/null
block herd
run 'python3 herd.py'
run 'python3 herd.py lock'

# ---- replicas-and-failover ---------------------------------------------------------
eval "$(fence "$L/replicas-and-failover.md" 2) --daemonize yes" > /dev/null || exit 1
wait_port 6380 || { echo "replica did not start"; exit 1; }
sleep 8
block repl-copy
runtty "redis-cli -p 6380 INFO replication | grep -E '^(role|master_link_status)'"
runtty "redis-cli SET product:p-103 '{\"name\":\"cafe torrado 500g\",\"price_cents\":3450}' EX 600"
runtty 'redis-cli -p 6380 GET product:p-103'
runtty 'redis-cli -p 6380 SET product:p-103 0'

block repl-failover
runtty 'redis-cli SHUTDOWN NOSAVE'
runtty "redis-cli -p 6380 INFO replication | grep -E '^(role|master_link_status)'"
runtty 'redis-cli -p 6380 SET product:p-104 2790'
runtty 'redis-cli -p 6380 REPLICAOF NO ONE'
runtty 'redis-cli -p 6380 SET product:p-104 2790'
runtty 'redis-cli -p 6380 GET product:p-103'

block end
redis-cli -p 6380 SHUTDOWN NOSAVE > /dev/null 2>&1
redis-cli SHUTDOWN NOSAVE > /dev/null 2>&1
true
