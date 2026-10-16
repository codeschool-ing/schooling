#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged: the network `nosql` and a `redis` container as lesson 1 leaves them.
# fill.sh is the file the lesson shows whole, written here by `put` so the
# transcript carries it, and run by the commands shown. Eviction samples keys
# at random, so the counts change a little from run to run; the lesson quotes
# this run.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
quiet 'docker run -d --name redis --network nosql redis:7.4'
quiet 'ready_redis redis'

block start
run 'docker rm -f redis'
run 'docker run -d --name redis --network nosql redis:7.4'
quiet 'ready_redis redis'

block limit
session 'docker exec -it redis redis-cli' <<'S'
CONFIG GET maxmemory
CONFIG GET maxmemory-policy
CONFIG SET maxmemory 4mb
S

block fill-noeviction
run "seq 1 20000 | awk '{ printf \"SET page:%d %0100d\\n\", \$1, 0 }' | docker exec -i redis redis-cli | grep . | sort | uniq -c"

block oom
session 'docker exec -it redis redis-cli' <<'S'
SET product:KB-101 34990
GET page:1
DEL page:1
S
run 'docker exec redis redis-cli INFO memory | grep -E "^(used_memory_human|maxmemory_human|maxmemory_policy):"'

block fill-file
put fill.sh <<'F'
# fill.sh POLICY [TTL]: an empty Redis with that eviction policy, four products,
# then 40,000 pages of 100 bytes, reading the four products every 100 pages.
# With TTL, every page is written with that lifetime in seconds.
policy=$1
r() { docker exec redis redis-cli "$@"; }
r FLUSHALL > /dev/null
r CONFIG RESETSTAT > /dev/null
r CONFIG SET maxmemory-policy "$policy" > /dev/null
r MSET product:KB-101 34990 product:MS-204 18900 product:MN-330 149900 product:CB-012 3990 > /dev/null
refused=$(seq 1 40000 |
  awk -v ttl="$2" '{ printf "SET page:%d %0100d%s\n", $1, 0, (ttl ? " EX " ttl : "") }
    $1 % 100 == 0 { print "MGET product:KB-101 product:MS-204 product:MN-330 product:CB-012" }' |
  docker exec -i redis redis-cli | grep -c OOM)
echo "$policy${2:+ (pages with TTL)}: refused $refused, $(r INFO stats | grep ^evicted_keys | tr -d '\r'), keys left $(r DBSIZE), products left $(r EXISTS product:KB-101 product:MS-204 product:MN-330 product:CB-012) of 4"
F

block policies
run 'sh fill.sh allkeys-lru'
run 'docker exec redis redis-cli EXISTS page:1'
run 'docker exec redis redis-cli EXISTS page:40000'
run 'sh fill.sh allkeys-lfu'
run 'sh fill.sh allkeys-random'

block lfu
run 'sh fill.sh allkeys-lfu'
run 'docker exec redis redis-cli OBJECT FREQ product:KB-101'
run 'docker exec redis redis-cli OBJECT FREQ page:39999'

block volatile
run 'sh fill.sh volatile-lru'
run 'sh fill.sh volatile-lru 3600'
run 'sh fill.sh volatile-ttl 3600'

block mixed
run 'sh fill.sh allkeys-lru 3600'
run 'sh fill.sh noeviction'

block ttl
session 'docker exec -it redis redis-cli' <<'S'
CONFIG SET maxmemory 0
FLUSHALL
SET cart:ana KB-101 EX 600
TTL cart:ana
SET product:KB-101 34990
TTL product:KB-101
TTL cart:nobody
EXPIRE cart:nobody 600
PERSIST cart:ana
TTL cart:ana
S

block expiry
run 'docker exec redis redis-cli CONFIG RESETSTAT'
run "docker exec redis redis-cli EVAL \"for i = 1, 200000 do redis.call('SET', 'session:' .. i, 'x', 'EX', 1) end return redis.call('DBSIZE')\" 0"
run 'for i in 1 2 3 4 5; do sleep 0.5; echo "$(docker exec redis redis-cli DBSIZE) keys, $(docker exec redis redis-cli INFO stats | grep ^expired_keys | tr -d "\r")"; done'
