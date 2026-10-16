#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# Staged: the network `nosql` and a `redis` container as lesson 1 leaves them.
# sentinel.conf is the file the lesson shows whole, written by `put`.
#
# The waiting is the script's, never shown: after each start it waits for the
# replicas to be online, after a stop or a partition it waits for Sentinel or
# the cluster to finish the failover, as a student does by asking again a few
# seconds later. Which replica Sentinel promotes, the addresses Docker gives
# the cluster's nodes and every timestamp are whatever this run produced.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
quiet 'docker run -d --name redis --network nosql redis:7.4'
quiet 'ready_redis redis'

online() { # wait until $1 reports $2 replicas online
  local i
  for i in $(seq 60); do
    [ "$(docker exec "$1" redis-cli INFO replication 2>/dev/null | grep -c 'state=online')" -ge "$2" ] && return 0
    sleep 1
  done
}

block replication-start
run 'docker rm -f redis'
run 'docker run -d --name redis-1 --network nosql redis:7.4 redis-server --replica-announce-ip redis-1'
run 'docker run -d --name redis-2 --network nosql redis:7.4 redis-server --replica-announce-ip redis-2 --replicaof redis-1 6379'
run 'docker run -d --name redis-3 --network nosql redis:7.4 redis-server --replica-announce-ip redis-3 --replicaof redis-1 6379'
quiet 'ready_redis redis-1'
quiet 'online redis-1 2'

block replication-info
run 'docker exec redis-1 redis-cli INFO replication | grep -E "^(role|connected_slaves|slave[0-9]|master_repl_offset):"'
run 'docker exec redis-2 redis-cli INFO replication | grep -E "^(role|master_host|master_link_status|slave_repl_offset|slave_read_only):"'

block replication-write
run 'docker exec redis-1 redis-cli SET order:1001 paid'
run 'docker exec redis-2 redis-cli GET order:1001'
run 'docker exec redis-2 redis-cli SET order:1002 paid'

block async
run "docker exec redis-1 redis-cli EVAL \"for i = 1, 200000 do redis.call('SET', 'page:' .. i, 'x') end\" 0 > /dev/null; docker exec redis-1 redis-cli DBSIZE; docker exec redis-2 redis-cli DBSIZE"
run 'docker exec redis-2 redis-cli DBSIZE'

block sentinel-conf
put sentinel.conf <<'F'
port 26379
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
sentinel monitor shop redis-1 6379 2
sentinel down-after-milliseconds shop 5000
sentinel failover-timeout shop 30000
F

block sentinel-start
run 'for i in 1 2 3; do mkdir sentinel-$i && cp sentinel.conf sentinel-$i/; done'
run 'for i in 1 2 3; do docker run -d --name sentinel-$i --network nosql -v "$PWD/sentinel-$i:/conf" redis:7.4 redis-sentinel /conf/sentinel.conf; done'
quiet 'sleep 8'

block sentinel-ask
run 'docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop'
run 'docker exec sentinel-1 redis-cli -p 26379 SENTINEL master shop | paste - - | grep -E "^(flags|num-slaves|num-other-sentinels|quorum)\s"'

block failover
run 'docker stop redis-1'
quiet 'sleep 15'
run 'docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop'
run 'for s in sentinel-1 sentinel-2 sentinel-3; do echo "== $s"; docker logs $s 2>&1 | grep -E "[+](sdown|odown|vote-for-leader|selected-slave|promoted-slave|switch-master) "; done'

block failover-after
run 'primary=$(docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop | head -1); echo $primary'
run 'docker exec $primary redis-cli GET order:1001'
run 'docker start redis-1'
quiet 'sleep 12'
run 'docker exec redis-1 redis-cli INFO replication | grep -E "^(role|master_host|master_link_status):"'

block lose-write
quiet 'online $primary 2'
run 'docker exec $primary redis-cli SET order:2001 paid'
run 'docker network disconnect nosql $primary'
run 'docker exec $primary redis-cli SET order:2002 paid'
run 'docker exec $primary redis-cli GET order:2002'
quiet 'sleep 15'

block lose-after
run 'old=$primary; primary=$(docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop | head -1); echo "old $old, new $primary"'
run 'docker network connect nosql $old'
quiet 'sleep 20'
run 'docker exec $old redis-cli INFO replication | grep -E "^(role|master_host|master_link_status):"'
run 'docker exec $old redis-cli GET order:2002'
run 'docker exec $primary redis-cli GET order:2002'
run 'docker exec $old redis-cli GET order:2001'
run 'docker logs $old 2>&1 | grep -E "Full resync|Flushing old data"'

block wait
quiet 'online $primary 2'
session 'docker exec -it $primary redis-cli' <<'S'
CONFIG SET min-replicas-to-write 1
CONFIG SET min-replicas-max-lag 10
SET order:2003 paid
WAIT 2 1000
S
run 'docker network disconnect nosql $primary'

block wait-cut
session 'docker exec -it $primary redis-cli' <<'S'
SET order:2004 paid
WAIT 1 2000
GET order:2004
#sleep 12
SET order:2005 paid
S

block cluster-start
run 'docker rm -f redis-1 redis-2 redis-3 sentinel-1 sentinel-2 sentinel-3'
run 'for i in 1 2 3 4 5 6; do docker run -d --name node-$i --network nosql redis:7.4 redis-server --cluster-enabled yes --cluster-node-timeout 5000; done'
quiet 'for i in 1 2 3 4 5 6; do ready_redis node-$i; done'
run "ips=\$(for i in 1 2 3 4 5 6; do docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}:6379' node-\$i; done); echo \$ips"
run 'docker exec node-1 redis-cli --cluster create $ips --cluster-replicas 1 --cluster-yes'
quiet 'sleep 3'

block cluster-info
run 'docker exec node-1 redis-cli CLUSTER INFO | grep -E "^cluster_(state|slots_assigned|known_nodes|size):"'
run "docker exec node-1 redis-cli CLUSTER NODES | cut -d' ' -f2,3,9 | sort"

block slots
session 'docker exec -it node-1 redis-cli' <<'S'
CLUSTER KEYSLOT product:KB-101
SET product:KB-101 34990
S

block redirect
session 'docker exec -it node-1 redis-cli -c' <<'S'
SET product:KB-101 34990
GET product:KB-101
S

block crossslot
session 'docker exec -it node-1 redis-cli -c' <<'S'
MSET cart:ana:items KB-101 cart:ana:total 34990
CLUSTER KEYSLOT cart:ana:items
CLUSTER KEYSLOT cart:ana:total
CLUSTER KEYSLOT {cart:ana}:items
CLUSTER KEYSLOT {cart:ana}:total
MSET {cart:ana}:items KB-101 {cart:ana}:total 34990
S

block cluster-failover
run 'docker stop node-3'
quiet 'sleep 15'
run "docker exec node-1 redis-cli CLUSTER NODES | cut -d' ' -f2,3,9 | sort"
run 'docker exec node-1 redis-cli CLUSTER INFO | grep -E "^cluster_state:"'

block cluster-after
session 'docker exec -it node-1 redis-cli -c' <<'S'
GET product:KB-101
S
