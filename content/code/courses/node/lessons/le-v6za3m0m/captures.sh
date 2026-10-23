#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l8.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l8.txt; done
#
# The demos run in ~/server/files; the store and the streaming demo in the
# links project as lesson 7 left it. Every program is taken out of the
# lesson's .md by lab/shown.py. Memory and time are this computer's, measured
# by the programs themselves, and move from run to run.
#
# STAGED: the folders ~/server/files and its package.json (as lesson 5's
# native folder was made); access.log copied into links/demo for the
# streaming demo; servers run "in a second terminal" and are stopped after.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
F='~/server/files'
L='~/server/links'
quiet '~/server' "rm -rf files && mkdir files && echo '{ \"name\": \"files\", \"private\": true, \"type\": \"module\" }' > files/package.json"
for f in bytes.js:buffers three.js:three-apis paths.js:paths inside.js:paths files.js:reading-and-writing \
         codes.js:error-codes load.js:error-codes torn.js:atomic-writes makelog.js:why-streams whole.js:why-streams \
         streamed.js:why-streams chunks.js:readable-and-writable iterate.js:readable-and-writable write.js:readable-and-writable \
         gzip.js:pipeline pressure.js:backpressure report.js:transforms; do
  shown ${f#*:}.md ${f%%:*} $F/${f%%:*}
done

block bytes
session $F 'node bytes.js'
block three
session $F 'node three.js'
block paths
session $F 'node paths.js'
block inside
session $F 'node inside.js'
block files
session $F 'node files.js'
block codes
session $F 'node codes.js'
block torn
session $F "node torn.js; ls -l store.json; node -e 'JSON.parse(require(\"fs\").readFileSync(\"store.json\", \"utf8\"))' 2>&1 | grep -E '^SyntaxError'"
block makelog
session $F 'node makelog.js && ls -lh access.log' 'node whole.js' 'node streamed.js'
block chunks
session $F 'node chunks.js'
block iterate
session $F 'node iterate.js'
block write
session $F 'node write.js && cat numbers.txt'
block gzip
session $F 'node gzip.js access.log access.log.gz' 'ls -lh access.log access.log.gz'
block gzip-missing
session $F 'node gzip.js missing.log missing.log.gz; echo "exit code $?"; ls -l missing.log.gz'
block pressure
session $F 'node pressure.js'
block report
session $F 'node report.js'

# The store in a file, in the links project.
shown atomic-writes.md src/store.js $L/src/store.js
quiet $L "rm -rf data && grep -qx 'data/' .gitignore || echo data/ >> .gitignore"
bg links $L 'node server.js'; wait_port 3000
block store-add
session $L "curl -s -o /dev/null -w '%{http_code}\n' -H 'content-type: application/json' -d '{\"url\": \"https://nodejs.org/\"}' http://127.0.0.1:3000/links" \
  'cat data/links.json' 'cat .gitignore'
bg_stop links INT
bg links2 $L 'node server.js'; wait_port 3000
block store-again
session $L "curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links"
bg_stop links2 INT
quiet $L 'rm -rf data'

# Streaming over HTTP.
shown streaming-http.md transfer.js $L/demo/transfer.js
quiet $L 'cp ~/server/files/access.log demo/access.log'
bg transfer $L 'node demo/transfer.js'; wait_port 3000
block transfer
session $L "curl -s -o /dev/null -w '%{size_download} bytes in %{time_total} s\n' http://127.0.0.1:3000/log" \
  'head -c 5000000 /dev/zero | curl -s -T - http://127.0.0.1:3000/upload' \
  'head -c 12000000 /dev/zero | curl -s -T - http://127.0.0.1:3000/upload' \
  'ls demo/upload.bin' \
  'curl -s -o /dev/null --limit-rate 1M -m 1 http://127.0.0.1:3000/log; echo "curl exit code $?"'
sleep 0.5
bg_stop transfer INT
block transfer-server
bg_show transfer; printf '^C\n'
quiet $L 'rm -f demo/access.log demo/upload.bin'
