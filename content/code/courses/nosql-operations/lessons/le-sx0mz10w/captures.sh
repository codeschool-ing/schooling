#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged: the network `nosql` and a `redis` container as lesson 1 leaves them,
# so that the lesson's first command, removing that container, has one to
# remove. Everything after that is typed by the lesson.
#
# The stream ids in the second stream session are the ones the first session
# printed: they are read back with XRANGE, quietly, and typed into the second
# session, as a student copies them off the screen.
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

block lost-update
run 'docker exec redis redis-cli SET visits 0'
run "for w in 1 2; do docker exec redis sh -c 'for i in \$(seq 500); do v=\$(redis-cli GET visits); redis-cli SET visits \$((v+1)) >/dev/null; done' & done; wait"
run 'docker exec redis redis-cli GET visits'
run 'docker exec redis redis-cli SET visits 0'
run "for w in 1 2; do docker exec redis sh -c 'for i in \$(seq 500); do redis-cli INCR visits >/dev/null; done' & done; wait"
run 'docker exec redis redis-cli GET visits'

block counters
session 'docker exec -it redis redis-cli' <<'S'
SET stock:KB-101 12
DECR stock:KB-101
DECRBY stock:KB-101 3
GET stock:KB-101
OBJECT ENCODING stock:KB-101
SET greeting "hello from the lab"
INCR greeting
S

block lock
session 'docker exec -it redis redis-cli' <<'S'
SET lock:order:1001 worker-a NX EX 30
SET lock:order:1001 worker-b NX EX 30
GET lock:order:1001
TTL lock:order:1001
S

block unlock
session 'docker exec -it redis redis-cli' <<'S'
EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 lock:order:1001 worker-b
EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 lock:order:1001 worker-a
S

block idempotency
session 'docker exec -it redis redis-cli' <<'S'
SET done:payment:1001 charged NX EX 86400
SET done:payment:1001 charged NX EX 86400
S

block ttl
session 'docker exec -it redis redis-cli' <<'S'
SET cart:ana KB-101 EX 600
TTL cart:ana
SET cart:ana MS-204
TTL cart:ana
SET cart:ana KB-101 EX 600
SET cart:ana MS-204 KEEPTTL
TTL cart:ana
S

block hashes
session 'docker exec -it redis redis-cli' <<'S'
HSET product:KB-101 name "Mechanical keyboard" price_cents 34990 stock 12
HGETALL product:KB-101
HINCRBY product:KB-101 stock -1
HMGET product:KB-101 price_cents stock
S

block memory
session 'docker exec -it redis redis-cli' <<'S'
SET product:KB-101:json '{"name":"Mechanical keyboard","price_cents":34990,"stock":12}'
MEMORY USAGE product:KB-101
MEMORY USAGE product:KB-101:json
OBJECT ENCODING product:KB-101
S

block encoding
session 'docker exec -it redis redis-cli' <<'S'
CONFIG GET hash-max-listpack-*
HSET product:KB-101 description "Full-size mechanical keyboard with brown switches, ABNT2 layout and a detachable USB-C cable"
OBJECT ENCODING product:KB-101
MEMORY USAGE product:KB-101
S

block lists
session 'docker exec -it redis redis-cli' <<'S'
LPUSH viewed:ana MN-330
LPUSH viewed:ana KB-101 MS-204 CB-012 KB-101
LRANGE viewed:ana 0 -1
S

block dedupe
session 'docker exec -it redis redis-cli' <<'S'
LREM viewed:ana 0 KB-101
LPUSH viewed:ana KB-101
LTRIM viewed:ana 0 2
LRANGE viewed:ana 0 -1
S

block queue
session 'docker exec -it redis redis-cli' <<'S'
LPUSH jobs:email order-1001
RPOP jobs:email
LLEN jobs:email
S

block sets
session 'docker exec -it redis redis-cli' <<'S'
SADD tag:office KB-101 MS-204 MN-330 CB-012
SADD tag:usb-c CB-012 MN-330
SADD tag:wireless MS-204
SISMEMBER tag:wireless KB-101
SINTER tag:office tag:usb-c
SADD tag:usb-c CB-012
SCARD tag:usb-c
S

block zsets
session 'docker exec -it redis redis-cli' <<'S'
ZINCRBY bestsellers:2026-10 2 KB-101
ZINCRBY bestsellers:2026-10 5 CB-012
ZINCRBY bestsellers:2026-10 1 MN-330
ZINCRBY bestsellers:2026-10 3 MS-204
ZINCRBY bestsellers:2026-10 3 KB-101
S

block ranking
session 'docker exec -it redis redis-cli' <<'S'
ZREVRANGE bestsellers:2026-10 0 2 WITHSCORES
ZREVRANK bestsellers:2026-10 MS-204
ZRANGE bestsellers:2026-10 3 +inf BYSCORE WITHSCORES
S

block streams
session 'docker exec -it redis redis-cli' <<'S'
XADD orders * order 1001 customer ana total_cents 34990
XADD orders * order 1002 customer bruno total_cents 18900
XADD orders * order 1003 customer carla total_cents 149900
XLEN orders
XGROUP CREATE orders shipping 0
XREADGROUP GROUP shipping worker-1 COUNT 2 STREAMS orders >
XREADGROUP GROUP shipping worker-2 COUNT 2 STREAMS orders >
S
ids=$(docker exec redis redis-cli XRANGE orders - + | grep -E '^[0-9]+-[0-9]+$')
ID1=$(echo "$ids" | sed -n 1p); ID2=$(echo "$ids" | sed -n 2p); ID3=$(echo "$ids" | sed -n 3p)

block pending
session 'docker exec -it redis redis-cli' <<S
XACK orders shipping $ID3
XPENDING orders shipping
#sleep 6
XPENDING orders shipping - + 10
XAUTOCLAIM orders shipping worker-2 5000 0 COUNT 10
XPENDING orders shipping - + 10
XACK orders shipping $ID1 $ID2
XLEN orders
XGROUP CREATE orders billing 0
XINFO GROUPS orders
S
