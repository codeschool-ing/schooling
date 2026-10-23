#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. knobs is taken out
# of flags.md; boxoffice is assembled from lessons 1 to 14 by
# ../../lab/project.py.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - DATABASE_URL is exported before every boxoffice command (PRELUDE), as
#     lesson 6 has ana put it in ~/.profile; the database is dropped and made
#     again, and boxoffice's generators run, as lessons 9 and 10 leave the
#     project, with goose bringing the database to version 3 first, so that
#     boxoffice applies nothing when it starts.
#   - in section 05, knobs runs in the background while the next three
#     commands look at it; the lesson has the student use a second terminal.
#   - boxoffice runs in the background, its output kept in .server.log; the
#     command that starts it is printed as the student types it.
# Timestamps, sizes and request ids are whatever the run produced.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'

lab db
lab fresh knobs
show flags.md '// knobs/main.go' knobs/main.go
quiet knobs 'go mod init example.com/knobs'

block flags
on knobs 'go build -o knobs . && ./knobs'
on knobs './knobs -addr :9000 -max-conns=20 -v'
on knobs './knobs -max-conns ten; echo "exit $?"'
on knobs './knobs -h; echo "exit $?"'
on knobs './knobs report.csv -v'
on knobs './knobs -v false -addr :9000'
on knobs './knobs --addr=:9000 -v=false'

block env
on knobs 'BOXOFFICE_REGION= ./knobs | tail -1'
on knobs 'BOXOFFICE_REGION=sao-paulo ./knobs | tail -1'
on knobs 'export BOXOFFICE_REGION=sao-paulo; ./knobs | tail -1; bash -c '"'"'echo "a child sees $BOXOFFICE_REGION"'"'"

block secrets
lab exec knobs 'cd ~/knobs
p() { printf "ana@vm:~/knobs\$ %s\n" "$1"; eval "$1" 2>&1; }
BOXOFFICE_MANAGER_TOKEN=3f9c1e7a2b8d4f60 ./knobs -wait 3s -addr localhost:8080 hunter2 > /dev/null &
sleep 0.5
p "sudo -u nobody ps -o user=,args= -C knobs"
p "sudo -u nobody cat /proc/\$(pgrep -x knobs)/environ"
p "tr '"'"'\\0'"'"' '"'"'\\n'"'"' < /proc/\$(pgrep -x knobs)/environ | grep TOKEN"
wait'

block viper
lab fresh vipertry
put vipertry/main.go <<'GO'
package main

import _ "github.com/spf13/viper"

func main() {}
GO
on vipertry 'go mod init example.com/vipertry 2>/dev/null; go get github.com/spf13/viper@v1.21.0 2>&1 | grep -c "^go: added"'
on vipertry 'go list -m all | wc -l; go build -o vipertry . && ls -l vipertry ~/knobs/knobs'

block boxoffice
PRELUDE="export DATABASE_URL='$URL'"
project 14 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up && sqlc generate && protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto && go mod tidy'
on boxoffice 'go vet ./... && go build -o boxoffice . && ./boxoffice -h; echo "exit $?"'

block refused
on boxoffice 'env -u DATABASE_URL BOXOFFICE_MAX_CONNS=1 BOXOFFICE_WRITE_TIMEOUT=ten BOXOFFICE_ORIGIN=tickets.example.com ./boxoffice; echo "exit $?"'
on boxoffice 'BOXOFFICE_MANAGER_TOKEN_FILE=/nowhere ./boxoffice; echo "exit $?"'
on boxoffice './boxoffice -htp localhost:8080 2>&1 | tail -1'

block started
on boxoffice 'mkdir -p ~/.config/boxoffice && (umask 077; openssl rand -hex 16 > ~/.config/boxoffice/manager-token) && ls -l ~/.config/boxoffice'
printf 'ana@vm:~/boxoffice$ %s\n' 'BOXOFFICE_MANAGER_TOKEN_FILE=~/.config/boxoffice/manager-token BOXOFFICE_MAX_CONNS=4 ./boxoffice -max-conns 6'
serve boxoffice "env DATABASE_URL='$URL' BOXOFFICE_MANAGER_TOKEN_FILE=/home/ana/.config/boxoffice/manager-token BOXOFFICE_MAX_CONNS=4 ./boxoffice -max-conns 6"
on boxoffice 'head -2 .server.log'
on boxoffice 'curl -s -H "Authorization: Bearer $(cat ~/.config/boxoffice/manager-token)" localhost:8080/admin/report'
stop
