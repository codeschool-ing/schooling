#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# The lab machine already had Docker Engine and the three images before the
# course began, so the install commands in building-the-lab.md are marked as
# not run, and the pull it shows is of an image already present. The failures
# in when-setup-fails.md are each caused on purpose, by the command shown.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

block docker-version
run 'docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"'
run 'id -nG'

block pull
run 'docker pull mongo:8.0'

block images
run 'docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "REPOSITORY|mongo|redis|cassandra"'

block network
run 'docker network create nosql'

block start
run "$(from building-the-lab.md 'docker run -d --name mongo --network nosql mongo:8.0' | sed -n 1p)"
run "$(from building-the-lab.md 'docker run -d --name mongo --network nosql mongo:8.0' | sed -n 2p)"
run "$(from building-the-lab.md 'docker run -d --name mongo --network nosql mongo:8.0' | sed -n 3p)"

block cqlsh-too-early
run 'docker exec cassandra cqlsh'
quiet 'ready_mongo mongo'; quiet 'ready_redis redis'
block wait
run "$(from building-the-lab.md 'until docker exec cassandra cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done')"

block ps
run 'docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'

block mongo
session 'docker exec -it mongo mongosh --quiet' <<'S'
db.version()
db.lab.insertOne({ greeting: "hello from the lab" })
db.lab.find()
exit
S

block redis
session 'docker exec -it redis redis-cli' <<'S'
PING
SET greeting "hello from the lab"
GET greeting
exit
S
run 'docker exec redis redis-server --version'

block cassandra
session 'docker exec -it cassandra cqlsh' <<'S'
SELECT cluster_name, release_version FROM system.local;
exit
S

block stats
run 'docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"'

block heap
run 'docker exec cassandra nodetool info | grep -E "^Heap Memory"'

block stop-start
run 'docker stop mongo redis cassandra'
run 'docker ps -a --format "table {{.Names}}\t{{.Status}}"'
run 'docker start mongo redis cassandra'
quiet 'ready_mongo mongo'
run "docker exec mongo mongosh --quiet --eval 'db.lab.countDocuments()'"

block remove
run 'docker rm -f mongo'
run 'docker run -d --name mongo --network nosql mongo:8.0'
quiet 'ready_mongo mongo'
run "docker exec mongo mongosh --quiet --eval 'db.lab.countDocuments()'"

block name-conflict
run 'docker run -d --name mongo --network nosql mongo:8.0'

block no-network
quiet 'docker rm -f redis'
run 'docker run -d --name redis --network nosql-lab redis:7.4'
run 'docker ps -a --filter name=redis --format "table {{.Names}}\t{{.Status}}"'
run 'docker rm redis'

block bad-tag
run 'docker pull mongo:8.0.99'

block oom
quiet 'docker rm -f cassandra'
run 'docker run -d --name cassandra --network nosql --memory 400m cassandra:5.0'
quiet 'sleep 60'
run 'docker ps -a --filter name=cassandra --format "table {{.Names}}\t{{.Status}}"'
run 'docker inspect --format "{{.State.OOMKilled}}" cassandra'
