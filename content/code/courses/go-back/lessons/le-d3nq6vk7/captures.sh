#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice and its
# tests are assembled from lessons 1 to 15 by ../../lab/project.py. Where a
# section shows a file before and after a change, the earlier version is put
# in place first: config.go as lesson 14 left it (../../lab/fence.py), and the
# first concurrency_test.go of races.md (../../lab/nth.py).
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - DATABASE_URL is exported before every command (PRELUDE), as lesson 6
#     has ana put it in ~/.profile; the database is dropped and made again,
#     migrated, and boxoffice's generators run, as lessons 9 and 10 leave the
#     project.
#   - BOXOFFICE_TEST_DATABASE_URL is exported for the commands of section 07
#     after the first, as the lesson tells the student to.
# Timings, addresses, goroutine numbers and database names are whatever the
# run produced.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
TEST_URL='postgres:///postgres?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"
NTH=../../lab/nth.py

lab db
project 15 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && goose -dir migrations postgres "$DATABASE_URL" up && sqlc generate && protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto && go mod tidy'

block httptest
on boxoffice 'go vet ./... && go test -run "TestGetEvent|TestBuyTickets" -v .'

block router
on boxoffice 'go test -run "TestStaffRoutes|TestPreflight|TestTheLogHoldsNoToken" -v .'

block config-before
show ../le-tas5a29t/failing-early.md '// boxoffice/config.go' boxoffice/config.go
on boxoffice 'go test -run TestLoad .'
block config-after
show configuration.md '// boxoffice/config.go' boxoffice/config.go
on boxoffice 'go test -run TestLoad .'

block race-before
python3 "$NTH" races.md '// boxoffice/concurrency_test.go' 1 | lab put boxoffice/concurrency_test.go
on boxoffice 'go test -run TestConcurrentPurchases .'
on boxoffice 'go test -race -run TestConcurrentPurchases .'
block race-after
python3 "$NTH" races.md '// boxoffice/concurrency_test.go' 2 | lab put boxoffice/concurrency_test.go
on boxoffice 'go test -race -run TestConcurrentPurchases .'

block integration
on boxoffice 'go test -run "TestPgStore|TestASale" -v .'
PRELUDE="export DATABASE_URL='$URL' BOXOFFICE_TEST_DATABASE_URL='$TEST_URL'"
on boxoffice 'go test -run "TestPgStore|TestASale" -v .'
on boxoffice 'go test -run "TestPgStore|TestASale" .'
on boxoffice 'go test -run "TestPgStore|TestASale" .'
on boxoffice 'go test -count=1 -run "TestPgStore|TestASale" .'
on boxoffice 'psql -Atc "SELECT count(*) FROM pg_database WHERE datname LIKE '"'"'boxoffice_test_%'"'"'" postgres'

block all
on boxoffice 'time go test -count=1 ./...'
on boxoffice 'time go test -race -count=1 ./...'
on boxoffice 'go test -count=1 -cover .'
on boxoffice 'go test -count=1 -coverprofile=cover.out . && go tool cover -func=cover.out | grep -w "0.0%"'
