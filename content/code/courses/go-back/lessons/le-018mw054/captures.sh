#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice and
# cmd/sizes are assembled from lessons 1 to 11 by ../../lab/project.py.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - DATABASE_URL is exported before every command (PRELUDE); the database is
#     dropped and made again, migrated, and sqlc and protoc run, as lessons 9
#     and 10 leave the project.
#   - the server is started in the background and stopped by the script.
#   - grpcurl v1.9.4 is installed by the go install the lesson shows.
# Sizes are deterministic; the encoding times are whatever the run measured.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"

lab db
project 11 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up && sqlc generate && protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto && go mod tidy'

block sizes
on boxoffice 'go run ./cmd/sizes'
on boxoffice 'go run ./cmd/sizes'

block debug
MGR=$(openssl rand -hex 16)
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
on boxoffice 'curl -s localhost:8080/events/1'
on boxoffice 'curl -s localhost:9090/boxoffice.v1.Seats/GetEvent; echo "exit $?"'
on boxoffice 'curl -si --http2-prior-knowledge -X POST -H "content-type: application/grpc" --data-binary @/dev/null localhost:9090/boxoffice.v1.Seats/GetEvent'
on . 'go install github.com/fullstorydev/grpcurl/cmd/grpcurl@v1.9.4'
on boxoffice "grpcurl -plaintext -proto proto/seats.proto -d '{\"id\": 1}' localhost:9090 boxoffice.v1.Seats/GetEvent"
on boxoffice "grpcurl -plaintext -proto proto/seats.proto -d '{\"id\": 9}' localhost:9090 boxoffice.v1.Seats/GetEvent"
on boxoffice 'grpcurl -plaintext localhost:9090 list'
on boxoffice 'grpcurl -plaintext -proto proto/seats.proto describe boxoffice.v1.Seats'
stop
