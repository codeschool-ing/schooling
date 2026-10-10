#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# What is staged: the network `nosql`, which lesson 1 creates and this lesson
# only names. Everything else is typed: the three containers are started by the
# lines in three-members.md, taken out of the file, and the replica set is
# formed by the rs.initiate the lesson shows. Two secondaries that "fall
# behind" are frozen with db.fsyncLock(), which the lesson shows and explains.
# Which member wins each election is the server's choice, so the names in the
# election, read-preference and minority transcripts are whatever this run
# produced, found with rs.status() the way the lesson tells the student to.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

# the member in STATE, as rs.status() seen from container $1 reports it
member() {
  docker exec "$1" mongosh --quiet --eval \
    "rs.status().members.filter(m => m.stateStr == '$2').map(m => m.name.split(':')[0]).join(' ')"
}
STATUS='rs.status().members.map(m => ({ name: m.name, state: m.stateStr, health: m.health }))'

quiet 'docker network create nosql'

block start
while read -r line; do run "$line"; done < <(from three-members.md 'docker run -d --name mongo1 --hostname mongo1 --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all')
quiet 'ready_mongo mongo1'; quiet 'ready_mongo mongo2'; quiet 'ready_mongo mongo3'

block initiate
session 'docker exec -it mongo1 mongosh --quiet' <<S
rs.initiate({ _id: "rs0", members: [ { _id: 0, host: "mongo1:27017" }, { _id: 1, host: "mongo2:27017" }, { _id: 2, host: "mongo3:27017" } ] })
#sleep 15
$STATUS
exit
S

block oplog
session 'docker exec -it mongo1 mongosh --quiet shop' <<'S'
db.products.insertOne({ _id: "KB-101", name: "Mechanical keyboard", price: Decimal128("349.90") })
db.getSiblingDB("local").oplog.rs.find({ ns: "shop.products" }, { op: 1, ns: 1, o: 1, ts: 1, wall: 1 }).sort({ $natural: -1 }).limit(1)
db.adminCommand({ getDefaultRWConcern: 1 }).defaultWriteConcern
db.adminCommand({ getDefaultRWConcern: 1 }).defaultWriteConcernSource
exit
S

block lock
run "docker exec mongo2 mongosh --quiet --eval 'db.fsyncLock().lockCount'"
run "docker exec mongo3 mongosh --quiet --eval 'db.fsyncLock().lockCount'"

block write-concern
session 'docker exec -it mongo1 mongosh --quiet shop' <<'S'
db.products.insertOne({ _id: "MS-204", name: "Wireless mouse", price: Decimal128("189.00") }, { writeConcern: { w: 1 } })
db.products.insertOne({ _id: "MN-330", name: "27-inch monitor", price: Decimal128("1499.00") }, { writeConcern: { w: "majority", wtimeout: 3000 } })
db.products.countDocuments()
exit
S

block unlock
run "docker exec mongo2 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'"
run "docker exec mongo3 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'"

block stop
run 'docker stop -t 30 mongo1'
quiet 'sleep 8'
run "docker exec mongo2 mongosh --quiet --eval '$STATUS'"
A=$(member mongo2 PRIMARY)
run "docker inspect --format '{{.State.FinishedAt}}' mongo1"
run "docker exec $A mongosh --quiet --eval 'const m = rs.status().electionCandidateMetrics; ({ reason: m.lastElectionReason, electedAt: m.lastElectionDate, writableAt: m.wMajorityWriteAvailabilityDate })'"

block kill
run 'docker start mongo1'
quiet 'ready_mongo mongo1'; quiet 'sleep 5'
run "docker exec mongo1 mongosh --quiet --eval '$STATUS'"
run "docker kill $A"
quiet 'sleep 20'
run "docker inspect --format '{{.State.FinishedAt}}' $A"
B=$(member mongo1 PRIMARY)
run "docker exec $B mongosh --quiet --eval 'const m = rs.status().electionCandidateMetrics; ({ reason: m.lastElectionReason, electedAt: m.lastElectionDate, writableAt: m.wMajorityWriteAvailabilityDate })'"

block return
run "docker start $A"
quiet "ready_mongo $A"; quiet 'sleep 5'
run "docker exec $A mongosh --quiet --eval '$STATUS'"

block readpref
B=$(member mongo1 PRIMARY); S=$(member mongo1 SECONDARY)
session 'docker exec -it mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0"' <<'S'
for (const mode of ["primary", "primaryPreferred", "secondary", "secondaryPreferred", "nearest"]) print(mode.padEnd(20), db.products.find().readPref(mode).explain().serverInfo.host)
exit
S

block stale
for s in $S; do run "docker exec $s mongosh --quiet --eval 'db.fsyncLock().lockCount'"; done
session 'docker exec -it mongo1 mongosh --quiet "mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0"' <<'S'
db.products.updateOne({ _id: "KB-101" }, { $set: { price: Decimal128("329.90") } }, { writeConcern: { w: 1 } })
db.products.find({ _id: "KB-101" }, { price: 1 })
db.products.find({ _id: "KB-101" }, { price: 1 }).readPref("secondary")
db.products.find({ _id: "KB-101" }, { price: 1 }).readConcern("majority")
exit
S
for s in $S; do run "docker exec $s mongosh --quiet --eval 'db.fsyncUnlock().lockCount'"; done
run "docker exec mongo1 mongosh --quiet \"mongodb://mongo1,mongo2,mongo3/shop?replicaSet=rs0\" --eval 'db.products.find({ _id: \"KB-101\" }, { price: 1 }).readConcern(\"majority\")'"

block minority
P=$(member mongo1 PRIMARY); set -- $(member mongo1 SECONDARY); Q=$1
run "docker network disconnect nosql $P"
session "docker exec -it $P mongosh --quiet shop" <<S
db.orders.insertOne({ _id: 1001, customer: "ana@example.com", sku: "MN-330", qty: 1 }, { writeConcern: { w: 1 } })
#sleep 15
$STATUS
db.orders.insertOne({ _id: 1003, customer: "carla@example.com", sku: "CB-012", qty: 2 }, { writeConcern: { w: 1 } })
exit
S
run "docker exec $Q mongosh --quiet --eval '$STATUS'"
N=$(member $Q PRIMARY)
session "docker exec -it $N mongosh --quiet shop" <<'S'
db.orders.insertOne({ _id: 1002, customer: "bruno@example.com", sku: "MN-330", qty: 1 })
exit
S

block heal
run "docker network connect nosql $P"
quiet 'sleep 15'
run "docker exec $P mongosh --quiet --eval '$STATUS'"
run "docker exec $P mongosh --quiet shop --eval 'db.orders.find()'"
run "docker exec $P find /data/db/rollback -name '*.bson'"
run "docker exec $P sh -c 'bsondump /data/db/rollback/*/removed.*.bson'"
