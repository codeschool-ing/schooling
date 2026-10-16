#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged: the network `nosql` and a `redis` container as lesson 1 leaves them.
# Every container after that is started by the command the lesson shows, each
# on a named volume, and the data is written by the statements shown.
#
# The lesson kills Redis with `docker kill`, which ends the process with
# SIGKILL. It does not, and cannot, cut the power of the machine: what the
# lesson says about a machine that loses power (the difference between the
# three appendfsync settings) is stated from Redis's documentation, not run.
# The benchmark figures are whatever this machine gave on this run: a virtual
# machine with four processors and a virtual disk.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
quiet 'docker run -d --name redis --network nosql redis:7.4'
quiet 'ready_redis redis'

block rdb-start
run 'docker rm -f redis'
run 'docker run -d --name redis --network nosql -v redis-data:/data redis:7.4'
quiet 'ready_redis redis'

block rdb-config
session 'docker exec -it redis redis-cli' <<'S'
CONFIG GET save
CONFIG GET dir
EVAL "for i = 1, 100000 do redis.call('SET', 'order:' .. i, 'paid') end return redis.call('DBSIZE')" 0
BGSAVE
#sleep 2
LASTSAVE
SET order:100001 paid
SET order:100002 paid
S

block rdb-info
run 'docker exec redis redis-cli INFO persistence | grep -E "^rdb_(changes_since_last_save|last_bgsave_status|last_cow_size)"'
run 'docker exec redis ls -l /data'

block rdb-kill
run 'docker kill redis'
run 'docker start redis'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli DBSIZE'
run 'docker exec redis redis-cli EXISTS order:100001 order:100002'
run 'docker logs redis 2>&1 | grep -E "RDB|loaded"'

block rdb-stop
run 'docker exec redis redis-cli SET order:100001 paid'
run 'docker stop redis'
run 'docker start redis'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli DBSIZE'
run 'docker logs redis 2>&1 | grep -E "shutdown|final RDB"'

block aof-start
run 'docker rm -f redis'
run 'docker run -d --name redis --network nosql -v redis-aof:/data redis:7.4 redis-server --appendonly yes'
quiet 'ready_redis redis'

block aof-write
session 'docker exec -it redis redis-cli' <<'S'
CONFIG GET appendonly
CONFIG GET appendfsync
SET order:1001 paid
SET order:1002 paid
INCR stock:KB-101
S

block aof-kill
run 'docker kill redis'
run 'docker start redis'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli DBSIZE'
run 'docker logs redis 2>&1 | grep -E "loaded"'

block aof-files
run 'docker exec redis ls -l /data/appendonlydir'
run 'docker exec redis cat /data/appendonlydir/appendonly.aof.manifest'
run 'docker exec redis cat /data/appendonlydir/appendonly.aof.1.incr.aof'

block aof-grow
run "docker exec redis redis-cli EVAL \"for i = 1, 10000 do redis.call('INCR', 'stock:KB-101') end\" 0"
run 'docker exec redis ls -l /data/appendonlydir'
run 'docker exec redis redis-cli BGREWRITEAOF'
quiet 'sleep 2'
run 'docker exec redis ls -l /data/appendonlydir'
run 'docker exec redis cat /data/appendonlydir/appendonly.aof.manifest'
run 'docker exec redis redis-cli GET stock:KB-101'

block bench
run 'docker exec redis redis-cli CONFIG SET appendfsync everysec'
run 'docker exec redis redis-benchmark -t set -n 100000 --csv'
run 'docker exec redis redis-benchmark -t set -n 20000 -c 1 --csv'
run 'docker exec redis redis-cli CONFIG SET appendfsync always'
run 'docker exec redis redis-benchmark -t set -n 100000 --csv'
run 'docker exec redis redis-benchmark -t set -n 20000 -c 1 --csv'
run 'docker exec redis redis-cli CONFIG SET appendfsync everysec'

block trap-before
run 'docker rm -f redis'
run 'docker run -d --name redis --network nosql -v redis-both:/data redis:7.4'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli SET order:1001 paid'
run 'docker exec redis redis-cli SET order:1002 paid'
run 'docker stop redis'
run 'docker rm redis'

block trap
run 'docker run -d --name redis --network nosql -v redis-both:/data redis:7.4 redis-server --appendonly yes'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli DBSIZE'
run 'docker logs redis 2>&1 | grep -E "AOF|loaded"'
run 'docker exec redis ls -l /data'
run 'docker stop redis'
run 'docker run --rm -v redis-both:/data redis:7.4 ls -l /data'

block safe
run 'docker rm redis'
run 'docker run -d --name redis --network nosql -v redis-safe:/data redis:7.4'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli SET order:1001 paid'
run 'docker exec redis redis-cli SET order:1002 paid'
run 'docker exec redis redis-cli CONFIG SET appendonly yes'
quiet 'sleep 2'
run 'docker exec redis redis-cli INFO persistence | grep -E "^aof_(enabled|rewrite_in_progress|last_bgrewrite_status)"'
run 'docker rm -f redis'
run 'docker run -d --name redis --network nosql -v redis-safe:/data redis:7.4 redis-server --appendonly yes'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli DBSIZE'
run 'docker logs redis 2>&1 | grep -E "loaded"'

block cache
run 'docker rm -f redis'
run 'docker run -d --name redis --network nosql redis:7.4 redis-server --save "" --appendonly no'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli CONFIG GET save'
run 'docker exec redis redis-cli SET page:/product/KB-101 "<html>…</html>"'
run 'docker stop redis'
run 'docker start redis'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli DBSIZE'

block misconf
run 'docker rm -f redis'
run 'docker run -d --name redis --network nosql -v redis-data:/data:ro redis:7.4'
quiet 'ready_redis redis'
run 'docker exec redis redis-cli BGSAVE'
quiet 'sleep 1'
run 'docker exec redis redis-cli SET order:100003 paid'
run 'docker logs redis 2>&1 | grep -E "Failed opening"'

block info
run 'docker exec redis redis-cli INFO persistence | grep -E "^(loading|rdb_changes_since_last_save|rdb_bgsave_in_progress|rdb_last_bgsave_status|aof_enabled|aof_rewrite_in_progress|aof_last_bgrewrite_status|aof_last_write_status):"'
