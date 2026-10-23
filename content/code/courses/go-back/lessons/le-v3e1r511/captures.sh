#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice is
# assembled from lessons 1 to 12 by ../../lab/project.py; logdemo and the
# programs under logothers are taken out of the lesson's .md files.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - DATABASE_URL is exported before every command (PRELUDE); the database is
#     dropped and made again, migrated, and sqlc and protoc run, as lessons 9
#     and 10 leave the project.
#   - the server is started in the background and stopped by the script; what
#     it wrote is read from its log afterwards.
# Timestamps, request ids, durations and the benchmark's numbers are whatever
# the run produced.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"

lab db
block slog
lab fresh logdemo
show slog.md '// logdemo/main.go' logdemo/main.go
quiet logdemo 'go mod init example.com/logdemo'
on logdemo 'go run .'

block others
lab fresh logothers
show zerolog.md '// logothers/zerolog/main.go' logothers/zerolog/main.go
show zap.md '// logothers/zap/main.go' logothers/zap/main.go
show comparing.md '// logothers/bench/main.go' logothers/bench/main.go
on logothers 'go mod init example.com/logothers'
on logothers 'go mod tidy'
on logothers 'go run ./zerolog'
on logothers 'go run ./zap'
block bench
on logothers 'go run ./bench'
on logothers 'go run ./bench'

block boxoffice
project 12 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up && sqlc generate && protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto && go mod tidy'
on boxoffice 'go vet ./...'
MGR=$(openssl rand -hex 16)
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
on boxoffice 'curl -si localhost:8080/events/1'
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/2/tickets"
on boxoffice 'curl -s localhost:8080/events/9'
on boxoffice 'go run ./cmd/seats get 1'
stop
block log
on boxoffice 'cat .server.log'
on boxoffice 'grep "\"status\":409" .server.log'
on boxoffice 'python3 -c "import json,sys; [print(json.loads(l)[\"path\"], json.loads(l)[\"status\"]) for l in open(\".server.log\") if \"\\\"msg\\\":\\\"request\\\"\" in l]"'
