#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of nosql-operations, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   bash captures.sh
#
# What is staged: the network `nosql`, which lesson 1 creates, and the file
# seed.js, written from the fence in mongodump.md whose first line names it.
# The writes that run while the dump is taken are started by the
# `docker exec -d` line the lesson shows. Times and sizes are this run's.
#
# Recorded on Ubuntu 24.04, Docker Engine 29.8, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../capture.sh"

quiet 'docker network create nosql'
from mongodump.md '// seed.js: the shop'"'"'s customers, products and 100,000 orders, the same on every run.' > seed.js
CHECK="for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(\" \"))"

block start
run 'docker volume create mongo-data'
run 'docker run -d --name mongo --hostname mongo --network nosql -v mongo-data:/data/db mongo:8.0 mongod --replSet rs0 --bind_ip_all'
quiet 'ready_mongo mongo'
run "docker exec mongo mongosh --quiet --eval 'rs.initiate().ok'"
quiet "until docker exec mongo mongosh --quiet --eval 'db.hello().isWritablePrimary' | grep -q true; do sleep 1; done"

block seed
run 'docker cp seed.js mongo:/tmp/seed.js'
run 'docker exec mongo mongosh --quiet shop /tmp/seed.js'
run "docker exec mongo mongosh --quiet shop --eval '$CHECK'"

block dump-dir
run 'docker exec mongo mongodump --db shop --out /tmp/dump'
run 'docker exec mongo ls -l /tmp/dump/shop'

block dump
run "docker exec -d mongo mongosh --quiet shop --eval 'for (let i = 1; i <= 500; i++) { db.payments.insertOne({ _id: i, at: new Date() }); sleep(10) }'"
quiet 'sleep 2'
run 'time docker exec mongo mongodump --oplog --gzip --archive=/tmp/shop.archive.gz'
run 'docker cp mongo:/tmp/shop.archive.gz .'
run 'ls -l shop.archive.gz'

block snapshot
quiet 'sleep 10'
run "docker exec mongo mongosh --quiet --eval 'db.fsyncLock().lockCount'"
run 'time docker run --rm -v mongo-data:/data/db -v "$PWD":/backup mongo:8.0 tar -czf /backup/mongo-data.tar.gz -C /data/db .'
run "docker exec mongo mongosh --quiet --eval 'db.fsyncUnlock().lockCount'"
run 'ls -l mongo-data.tar.gz'

block snapshot-restore
run 'docker volume create mongo-copy'
run 'docker run --rm -v mongo-copy:/data/db -v "$PWD":/backup mongo:8.0 tar -xzf /backup/mongo-data.tar.gz -C /data/db'
run 'docker run -d --name mongo-copy --network nosql -v mongo-copy:/data/db mongo:8.0'
run "time sh -c 'until docker exec mongo-copy mongosh --quiet --eval \"db.runCommand({ ping: 1 })\" >/dev/null 2>&1; do sleep 1; done'"
run "docker exec mongo-copy mongosh --quiet shop --eval '$CHECK'"
run "docker logs mongo-copy 2>&1 | grep -o 'Document(s) exist in .system.replset., but started without --replSet'"

block restore
run 'docker run -d --name mongo-restore --network nosql mongo:8.0'
quiet 'ready_mongo mongo-restore'
run 'docker cp shop.archive.gz mongo-restore:/tmp/shop.archive.gz'
run 'time docker exec mongo-restore mongorestore --oplogReplay --gzip --archive=/tmp/shop.archive.gz'
run "docker exec mongo-restore mongosh --quiet shop --eval '$CHECK'"
run "docker exec mongo mongosh --quiet shop --eval '$CHECK'"
