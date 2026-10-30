#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of mobile-offline (cache).
#
#   sudo bash captures.sh > out.txt
#
# Needs lab.sh's machine and lesson 1's ~/planner (package.json and
# better-sqlite3). Works in ~/planner/cache only. server.ts, fetch.ts,
# catalogue.json and lru.ts are taken from the lesson by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - server.ts runs in the background; "server-log" is what it printed,
#     shown under the command that started it, as in its own terminal.
#   - "cleared" deletes the two caches with rm, playing the system's part.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/cache
LAB as 'rm -rf ~/planner/cache && mkdir -p ~/planner/cache'
put expiry.md server.ts $D/server.ts
put expiry.md fetch.ts $D/fetch.ts
put expiry.md catalogue.json $D/catalogue.json
put size-limits.md lru.ts $D/lru.ts
serve $D 8017 'node server.ts'
sleep 0.3
# serve's own probe is a request; start the log from the client's first one.
SKIP=$(stat -c %s "$LOGF")

block expiry
run $D 'node fetch.ts 0'
run $D 'node fetch.ts 30'
run $D "echo '{\"courses\": [\"Spanish A2\", \"Statistics\", \"Guitar\", \"Chess\"]}' > catalogue.json"
run $D 'node fetch.ts 45'
run $D 'node fetch.ts 90'
run $D 'node fetch.ts 100'
run $D 'node fetch.ts 1000'

block server-log
printf 'ana@dev:~/planner/cache$ node server.ts\n'
tail -c +$((SKIP + 1)) "$LOGF"
unserve

block lru
run $D 'node lru.ts put spanish 4'
run $D 'node lru.ts put statistics 3'
run $D 'node lru.ts put guitar 2'
run $D 'node lru.ts get spanish'
run $D 'node lru.ts put chess 4'
run $D 'node lru.ts get statistics'

block cleared
serve $D 8017 'node server.ts'
run $D 'rm -rf cache.db covers covers.db'
run $D 'node fetch.ts 1100'
run $D 'node lru.ts get spanish'
unserve
