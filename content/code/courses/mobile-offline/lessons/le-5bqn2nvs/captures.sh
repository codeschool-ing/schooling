#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of mobile-offline (secrets).
#
#   sudo bash captures.sh > out.txt
#
# Needs lab.sh's machine and lesson 1's ~/planner. Works in ~/planner/secrets
# only. Every file is taken from the lesson by lab/extract.py; config.json
# and log.ts each appear twice, and the second listing is taken for the
# "fixed" blocks.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - server.ts runs in the background with TIPS_API_KEY set and ACCESS_TTL=1,
#     as the lesson says; "tokens-log" is what it printed, shown under the
#     command that started it, as in its own terminal.
#   - Before "signout", an empty planner.db and cache/ are made with touch
#     and mkdir, standing in for lesson 3's database and lesson 17's cache.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=/home/ana/planner/secrets
LAB as 'rm -rf ~/planner/secrets && mkdir -p ~/planner/secrets'
put secrets-in-the-app.md config.json $D/config.json
put secrets-in-the-app.md app.ts $D/app.ts
put secrets-in-the-app.md bundle.ts $D/bundle.ts
put tokens.md server.ts $D/server.ts
put tokens.md client.ts $D/client.ts
put keep-less.md log.ts $D/log.ts

block bundle
run $D 'node bundle.ts'
run $D "grep -o 'tips_live_[0-9a-f]*' dist/app.js"

block bundle-fixed
python3 "$MO_LAB/extract.py" "$LESSON/secrets-in-the-app.md" config.json 2 > $D/config.json; chown ana $D/config.json
run $D 'node bundle.ts'
run $D "grep -c 'tips_live_' dist/app.js"

block tokens
LAB as "cd $D && { TIPS_API_KEY=tips_live_4f9c2a7e1b6d83a0 ACCESS_TTL=1 setsid bash -c 'echo \$\$ > $PIDF; exec node server.ts' </dev/null >$LOGF 2>&1 & }"
SERVER=1; sleep 0.8
run $D 'node client.ts signin'
run $D 'node client.ts tip statistics'
run $D 'sleep 2'
run $D 'node client.ts tip guitar'
LAB as "cd $D && touch planner.db && mkdir -p cache"
run $D 'node client.ts signout'
run $D 'node client.ts tip statistics'

block tokens-log
printf 'ana@dev:~/planner/secrets$ TIPS_API_KEY=tips_live_4f9c2a7e1b6d83a0 ACCESS_TTL=1 node server.ts\n'
cat "$LOGF"
unserve

block leak
run $D 'node log.ts'
run $D "grep -E -o '[a-z.]+@[a-z.]+' app.log"
run $D 'cat app.log'

block leak-fixed
python3 "$MO_LAB/extract.py" "$LESSON/keep-less.md" log.ts 2 > $D/log.ts; chown ana $D/log.ts
LAB as "rm -f $D/app.log"
run $D 'node log.ts'
run $D "grep -E -c '[a-z.]+@[a-z.]+' app.log"
run $D 'cat app.log'
