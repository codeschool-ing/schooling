#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice is
# assembled from lessons 1 to 17 by ../../lab/project.py.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - DATABASE_URL is exported before every command (PRELUDE), as lesson 6
#     has ana put it in ~/.profile; the database is dropped and made again,
#     migrated, and boxoffice's generators run, as lessons 9 and 10 leave the
#     project. The manager's token file of lesson 14 is made again.
#   - boxoffice runs in the background with its output in .server.log; the
#     lesson has the student run it in a terminal of its own. In section 06
#     the stream, the slow purchase and the signal are each typed in another
#     terminal; the script runs them in the background, in that order, and
#     prints what each terminal showed.
#   - the Docker daemon is started as lesson 16's script starts it, and the
#     container and image this script makes are removed at its start.
# Times, sizes, process ids and request ids are whatever the run produced.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# Docker Engine 29.8.2, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"
START="env DATABASE_URL='$URL' BOXOFFICE_MANAGER_TOKEN_FILE=/home/ana/.config/boxoffice/manager-token ./boxoffice"

lab db
if ! docker info >/dev/null 2>&1; then
  setsid dockerd >/var/log/dockerd.log 2>&1 </dev/null &
  for i in $(seq 1 50); do docker info >/dev/null 2>&1 && break; sleep 0.2; done
fi
docker rm -f boxoffice >/dev/null 2>&1 || true
docker rmi -f boxoffice:v0.17.0 >/dev/null 2>&1 || true

project 17 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up && sqlc generate && protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto && go mod tidy && rm -rf dist'
quiet . 'mkdir -p ~/.config/boxoffice && (umask 077; openssl rand -hex 16 > ~/.config/boxoffice/manager-token)'

block build
on boxoffice 'go vet ./... && go test -count=1 ./... | head -1 && go build -o boxoffice . && echo built'
serve boxoffice "$START"
on boxoffice 'head -1 .server.log'

block health
on boxoffice 'curl -si localhost:9100/healthz; curl -si localhost:9100/readyz'
on boxoffice 'sudo pg_ctlcluster 16 main stop'
on boxoffice 'curl -s localhost:9100/healthz; curl -s localhost:9100/readyz; curl -s localhost:8080/events/1'
on boxoffice 'sudo pg_ctlcluster 16 main start; sleep 1; curl -s localhost:9100/readyz'
on boxoffice 'grep -e "not ready" -e "listening for" -e "unexpected" .server.log'

block metrics
lab exec boxoffice "cd ~/boxoffice; (timeout 3 curl -sN localhost:8080/events/1/live > /dev/null &); sleep 0.3"
on boxoffice 'for i in 1 2 3; do curl -s -o /dev/null localhost:8080/events/1; done; curl -s -o /dev/null localhost:8080/events/9; curl -s -o /dev/null localhost:8080/nowhere'
on boxoffice 'curl -s localhost:9100/metrics | grep "^boxoffice_http_requests_total"'
on boxoffice 'curl -s localhost:9100/metrics | grep -e "^boxoffice_live" -e "^boxoffice_db" -e "^go_goroutines" -e "^process_resident"'
on boxoffice 'curl -s localhost:9100/metrics | grep "duration_seconds.*GET /events/{id}\""'
on boxoffice 'curl -s localhost:9100/metrics | wc -l'
stop

block shutdown
lab exec boxoffice "cd ~/boxoffice
export DATABASE_URL='$URL'
(BOXOFFICE_MANAGER_TOKEN_FILE=~/.config/boxoffice/manager-token ./boxoffice 2>&1 | cut -c1-200 > t1.out; echo \"exit \${PIPESTATUS[0]}\" >> t1.out) &
sleep 0.2
pid=\$(pgrep -x boxoffice)
for i in \$(seq 1 50); do curl -s -o /dev/null localhost:9100/healthz && break; sleep 0.1; done
(curl -sN localhost:8080/events/1/live > t2.out 2>&1; echo \"exit \$?\" >> t2.out) &
sleep 0.3
(curl -s -w ' %{http_code} after %{time_total}s\n' --limit-rate 20 --json '{\"quantity\": 1, \"email\": \"slow@example.com\"}' localhost:8080/events/1/tickets > t3.out 2>&1) &
sleep 1
kill -TERM \$pid
sleep 0.2
curl -s localhost:9100/readyz > t4.out
while kill -0 \$pid 2>/dev/null; do sleep 0.1; done
sleep 0.5"
printf '##### t2\nana@vm:~/boxoffice$ curl -sN localhost:8080/events/1/live; echo "exit $?"\n'
lab exec boxoffice 'cat t2.out'
printf "##### t3\nana@vm:~/boxoffice\$ curl -s -w ' %%{http_code} after %%{time_total}s\\\\n' --limit-rate 20 --json '{\"quantity\": 1, \"email\": \"slow@example.com\"}' localhost:8080/events/1/tickets\n"
lab exec boxoffice 'cat t3.out'
printf '##### t4\nana@vm:~/boxoffice$ kill -TERM $(pgrep -x boxoffice); sleep 0.2; curl -s localhost:9100/readyz\n'
lab exec boxoffice 'cat t4.out'
printf '##### t1\nana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN_FILE=~/.config/boxoffice/manager-token ./boxoffice 2>&1 | cut -c1-200; echo "exit ${PIPESTATUS[0]}"\n'
lab exec boxoffice 'cat t1.out'

block container
on boxoffice 'CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=v0.17.0" -o dist/boxoffice-linux-amd64 . && docker build -q -t boxoffice:v0.17.0 .'
on . 'docker run -d --name boxoffice -p 8080:8080 -p 9100:9100 --user "$(id -u):$(id -g)" -v /var/run/postgresql:/var/run/postgresql -v ~/.config/boxoffice/manager-token:/run/secrets/manager-token:ro -e BOXOFFICE_MANAGER_TOKEN_FILE=/run/secrets/manager-token -e DATABASE_URL="postgres://$USER@/boxoffice?host=/var/run/postgresql" -e TZ=America/Sao_Paulo boxoffice:v0.17.0'
sleep 2
on . 'curl -s localhost:9100/readyz; curl -s localhost:9100/healthz'
on . 'time docker stop boxoffice'
on . 'docker logs boxoffice | tail -2'
quiet . 'docker rm boxoffice'
