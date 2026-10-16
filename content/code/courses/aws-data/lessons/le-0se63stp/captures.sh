#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of aws-data (ElastiCache), as a
# script that produces them. Every transcript in the lesson was copied from its
# output.
#
#   sudo REDIS_WHEELS=DIR bash ../../lab.sh run captures.sh
#
# Two servers: moto, empty, which records the clusters and runs no cache; and
# the Redis that Ubuntu 24.04 packages (redis-server 7.0.15), which is the real
# cache every later block talks to. The programs are read out of the lesson's
# own .md files, so the two cannot drift.
#
# STAGED, and why:
#   - the student runs `redis-server --port 6379 --save '' --appendonly no` in a
#     terminal of its own, in the foreground; here the same command runs with
#     --daemonize yes, inside the run's own network namespace, and is shut down
#     at the end. The package itself was installed on the recording machine
#     with the apt-get line of a-local-redis.md.
#   - redis-cli prints `(integer) 1` and `(nil)` only to a terminal, and the
#     bare value to a pipe. Its blocks run under `script`, so the transcript
#     shows what the student's terminal shows.
#   - the run has no network, so `pip install redis==8.1.0` is pointed, through
#     PIP_NO_INDEX and PIP_FIND_LINKS, at REDIS_WHEELS: a directory holding the
#     wheel fetched beforehand with `pip download redis==8.1.0`. The command and
#     what it prints are the student's.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$LESSONS/le-0se63stp"

# like run, through a pseudo-terminal, for redis-cli
runtty() {
  printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"
  script -qec "$*" /dev/null < /dev/null | sed 's/\r*$//; s/.*\r//' || true
}

block prices-elasticache
run 'python3 prices.py elasticache'

block ec-create
run 'aws elasticache create-cache-cluster --cache-cluster-id quitanda-pages --engine memcached --cache-node-type cache.t4g.micro --num-cache-nodes 2 --query "CacheCluster.[CacheClusterStatus,Engine,NumCacheNodes]" --output text'
run 'aws elasticache create-replication-group --replication-group-id quitanda-catalog --replication-group-description "product pages" --engine valkey --cache-node-type cache.r7g.large --cluster-mode enabled --num-node-groups 2 --replicas-per-node-group 1 --automatic-failover-enabled --multi-az-enabled --query "ReplicationGroup.[Status,ClusterMode,AutomaticFailover,MultiAZ,EngineVersion]" --output text'
run 'aws elasticache describe-replication-groups --replication-group-id quitanda-catalog --query "ReplicationGroups[0].NodeGroups[].NodeGroupMembers[].[CacheClusterId,CacheNodeId,CurrentRole,PreferredAvailabilityZone]" --output text'

block ec-unsupported
run 'aws elasticache test-failover --replication-group-id quitanda-catalog --node-group-id 0001'
run 'aws elasticache create-serverless-cache --serverless-cache-name quitanda-catalog-sl --engine valkey'

# ---- the real cache ---------------------------------------------------------
redis-server --port 6379 --save '' --appendonly no --daemonize yes > /dev/null
for _ in $(seq 40); do redis-cli PING > /dev/null 2>&1 && break; sleep 0.25; done

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
if [ -n "${REDIS_WHEELS:-}" ]; then export PIP_NO_INDEX=1 PIP_FIND_LINKS="$REDIS_WHEELS"; fi
run 'pip install -q redis==8.1.0'
run 'python3 -c "import redis; print(redis.__version__)"'
unset PIP_NO_INDEX PIP_FIND_LINKS

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

redis-cli SHUTDOWN NOSAVE > /dev/null 2>&1
