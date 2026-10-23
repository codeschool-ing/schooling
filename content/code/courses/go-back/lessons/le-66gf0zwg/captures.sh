#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice and its
# watchws client are assembled from lessons 1 to 13 by ../../lab/project.py;
# room is taken out of melody.md.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - DATABASE_URL is exported before every command (PRELUDE); the database is
#     dropped and made again, and boxoffice's generators run, as lessons 9 and
#     10 leave the project. boxoffice is built once, and its own migrations
#     bring the database to version 3 when it starts.
#   - the purchase that wakes psql's LISTEN in section 03 is made in the
#     background while psql waits, its answer discarded; the lesson shows the
#     command.
#   - every server, and every watcher of sections 04 to 07, runs in the
#     background, its output kept in a file and printed after the commands made
#     while it ran; the lesson has the student use one terminal for each.
#   - the Centrifugo archive and its checksums are downloaded by the commands
#     the lesson shows. The token and the API key are whatever genconfig and
#     gentoken produced in the run, kept in shell variables for the commands
#     that use them.
# Timestamps, ids, tokens and durations are whatever the run produced.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# Centrifugo v6.9.7, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"

lab db
project 13 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up-to 2 && sqlc generate && protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto && go mod tidy && go build -o watchws ./cmd/watchws'

block notify
on boxoffice 'go vet ./... && go build -o boxoffice . && echo built'
MGR=$(openssl rand -hex 16)
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' ./boxoffice"
on boxoffice 'head -4 .server.log'
lab exec boxoffice "cd ~/boxoffice
(psql boxoffice -c 'LISTEN availability' -c 'SELECT pg_sleep(2)' > listen.out 2>&1 &)
sleep 0.5
curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets > /dev/null
sleep 2.5"
printf 'ana@vm:~/boxoffice$ psql boxoffice -c %s -c %s\n' "'LISTEN availability'" "'SELECT pg_sleep(2)'"
lab exec boxoffice 'cat listen.out'

block sse
lab exec boxoffice "cd ~/boxoffice
(timeout 14 curl -sN localhost:8080/events/1/live > sse.out 2>&1 &)
sleep 1
echo \"ana@vm:~/boxoffice\\\$ curl -s --json '{\\\"quantity\\\": 3, \\\"email\\\": \\\"rui@example.com\\\"}' localhost:8080/events/1/tickets\" > buy.out
curl -s --json '{\"quantity\": 3, \"email\": \"rui@example.com\"}' localhost:8080/events/1/tickets >> buy.out
sleep 11
echo \"ana@vm:~/boxoffice\\\$ curl -s --json '{\\\"quantity\\\": 1, \\\"email\\\": \\\"bea@example.com\\\"}' localhost:8080/events/1/tickets\" >> buy.out
curl -s --json '{\"quantity\": 1, \"email\": \"bea@example.com\"}' localhost:8080/events/1/tickets >> buy.out
sleep 3"
printf 'ana@vm:~/boxoffice$ curl -sN localhost:8080/events/1/live\n'
lab exec boxoffice 'cat sse.out'
block sse-buys
lab exec boxoffice 'cat buy.out'

block ws
on boxoffice 'curl -s -D - -o /dev/null -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -m 2 localhost:8080/events/1/ws'
on boxoffice 'curl -si -H "Origin: https://elsewhere.example.net" -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -m 2 localhost:8080/events/1/ws'
lab exec boxoffice "cd ~/boxoffice
(./watchws ws://localhost:8080/events/1/ws 3s > ws.out 2>&1 &)
sleep 1
curl -s --json '{\"quantity\": 2, \"email\": \"caio@example.com\"}' localhost:8080/events/1/tickets > /dev/null
sleep 3"
printf 'ana@vm:~/boxoffice$ ./watchws ws://localhost:8080/events/1/ws 3s\n'
lab exec boxoffice 'cat ws.out'
stop
block log
on boxoffice 'grep -e /live -e /ws .server.log'

block melody
lab fresh room
show melody.md '// room/main.go' room/main.go
on room 'go mod init example.com/room'
on room 'go mod tidy'
PORT=8081 serve room 'go run .'
lab exec room "cd ~/room
(~/boxoffice/watchws ws://localhost:8081/room 2s > a.out 2>&1 &)
sleep 0.5
~/boxoffice/watchws ws://localhost:8081/room 1s 'doors open at 19:00' > b.out 2>&1
sleep 1.5"
printf 'ana@vm:~/room$ ~/boxoffice/watchws ws://localhost:8081/room 2s\n'
lab exec room 'cat a.out'
printf "ana@vm:~/room\$ ~/boxoffice/watchws ws://localhost:8081/room 1s 'doors open at 19:00'\n"
lab exec room 'cat b.out'
stop
on room 'cat .server.log'

block centrifugo
lab fresh centrifugo
on centrifugo 'curl -sSLO https://github.com/centrifugal/centrifugo/releases/download/v6.9.7/centrifugo_6.9.7_linux_amd64.tar.gz'
on centrifugo 'curl -sSLO https://github.com/centrifugal/centrifugo/releases/download/v6.9.7/centrifugo_6.9.7_checksums.txt'
on centrifugo 'grep linux_amd64.tar.gz centrifugo_6.9.7_checksums.txt | sha256sum -c'
on centrifugo 'tar xzf centrifugo_6.9.7_linux_amd64.tar.gz centrifugo && ./centrifugo version'
on centrifugo './centrifugo genconfig && python3 -c "import json; print(sorted(json.load(open(\"config.json\"))))"'
on centrifugo 'python3 - <<'"'"'PY'"'"'
import json
c = json.load(open("config.json"))
c["http_server"] = {"address": "127.0.0.1", "port": 8000}
c["channel"] = {"without_namespace": {"allow_subscribe_for_client": True}}
json.dump(c, open("config.json", "w"), indent=2)
PY'
PORT=8000 serve centrifugo './centrifugo -c config.json'
on centrifugo './centrifugo gentoken -c config.json -u ana'
TOKEN=$(lab exec centrifugo './centrifugo gentoken -c config.json -u ana' | grep -o 'eyJ[^ ]*')
KEY=$(lab exec centrifugo 'python3 -c "import json; print(json.load(open(\"config.json\"))[\"http_api\"][\"key\"])"')
lab exec centrifugo "cd ~/centrifugo
(~/boxoffice/watchws ws://localhost:8000/connection/websocket 3s '{\"id\":1,\"connect\":{\"token\":\"$TOKEN\"}}' '{\"id\":2,\"subscribe\":{\"channel\":\"event-1\"}}' > w.out 2>&1 &)
sleep 1
curl -s -H 'X-API-Key: $KEY' --json '{\"channel\":\"event-1\",\"data\":{\"event_id\":1,\"available\":112}}' localhost:8000/api/publish > p.out
sleep 3"
printf "ana@vm:~/centrifugo\$ ~/boxoffice/watchws ws://localhost:8000/connection/websocket 3s '{\"id\":1,\"connect\":{\"token\":\"'\"\$TOKEN\"'\"}}' '{\"id\":2,\"subscribe\":{\"channel\":\"event-1\"}}'\n"
lab exec centrifugo 'cat w.out'
block publish
printf "ana@vm:~/centrifugo\$ curl -s -H \"X-API-Key: \$KEY\" --json '{\"channel\":\"event-1\",\"data\":{\"event_id\":1,\"available\":112}}' localhost:8000/api/publish\n"
lab exec centrifugo 'cat p.out; echo'
block clog
on centrifugo 'grep -e "starting Centrifugo" -e serving .server.log'
stop
