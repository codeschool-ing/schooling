#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The migrations,
# sqlc.yaml, queries.sql and boxoffice's Go files are assembled from lessons 1
# to 9 by ../../lab/project.py; race, poolwait and rush are taken out of the
# lesson's .md files.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - DATABASE_URL is exported before every command (PRELUDE), as lesson 6
#     section 02 has ana do in ~/.profile.
#   - the boxoffice database is dropped and made again before the goose block
#     and again before boxoffice runs its own migrations, as the lesson tells
#     the student to do with the database lesson 6 built by hand, and once
#     more before the fixed version is rushed, so that both rushes start from
#     the same five seats.
#   - pgstore.go is the first version (transactions.md) until the block
#     `fixed`, which writes the second (the-pool.md); the Organ Recital is
#     created again for that block without printing it.
#   - the server is started in the background and stopped by the script; what
#     it printed is read from its log.
#   - goose v3.29.0 is installed by the go install the lesson shows; the
#     module cache already held it from a trial run.
# Timestamps, durations, the race's counts and the order of concurrent lines
# are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
PRELUDE="export DATABASE_URL='$URL'"

lab db
project 9 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
NTH=../../lab/nth.py
python3 "$NTH" transactions.md '// boxoffice/pgstore.go' 1 | lab put boxoffice/pgstore.go

block install
on . 'go install github.com/pressly/goose/v3/cmd/goose@v3.29.0'
on . 'goose --version'

block fresh
on boxoffice 'rm -f schema.sql && ls migrations'
on boxoffice 'dropdb boxoffice && createdb boxoffice'

block goose
on boxoffice 'goose -dir migrations postgres "$DATABASE_URL" status'
on boxoffice 'goose -dir migrations postgres "$DATABASE_URL" up'
on boxoffice 'goose -dir migrations postgres "$DATABASE_URL" status'
on boxoffice 'psql boxoffice -c "SELECT version_id, is_applied, tstamp FROM goose_db_version ORDER BY id"'
on boxoffice 'goose -dir migrations postgres "$DATABASE_URL" down'
on boxoffice 'psql boxoffice -c "\dt"'
on boxoffice 'goose -dir migrations postgres "$DATABASE_URL" up'

block sqlc
on boxoffice 'sqlc generate && ls internal/db'

block binary
quiet boxoffice 'go mod tidy'
on boxoffice 'go vet ./...'
on boxoffice 'dropdb boxoffice && createdb boxoffice'
MGR=$(openssl rand -hex 16)
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
stop
on boxoffice 'cat .server.log'
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
block restart
on boxoffice 'cat .server.log'

block transactions
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets"
on boxoffice 'psql boxoffice -c "SELECT * FROM tickets"'
on boxoffice "psql boxoffice <<'SQL'
BEGIN;
UPDATE events SET sold = sold + 2 WHERE id = 1;
INSERT INTO tickets (event_id, email, quantity) VALUES (1, 'rui@example.com', 20);
COMMIT;
SELECT sold FROM events WHERE id = 1;
SQL"

block race
lab fresh race
show concurrency.md '// race/main.go' race/main.go
quiet race 'go mod init example.com/race && go mod tidy'
on race 'createdb racelab'
on race "DATABASE_URL='postgres:///racelab?host=/var/run/postgresql' go run ."
on race "DATABASE_URL='postgres:///racelab?host=/var/run/postgresql' go run ."
quiet race 'dropdb racelab'

block pool
lab fresh poolwait
show the-pool.md '// poolwait/main.go' poolwait/main.go
quiet poolwait 'go mod init example.com/poolwait && go mod tidy'
on poolwait 'psql boxoffice -c "SHOW max_connections"'
on poolwait 'go run .'

block deadlock
printf 'ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json %s localhost:8080/admin/events\n' "'{\"name\": \"Organ Recital\", \"seats\": 5}'"
lab exec boxoffice "curl -s -H 'Authorization: Bearer $MGR' --json '{\"name\": \"Organ Recital\", \"seats\": 5}' localhost:8080/admin/events" 2>&1
lab fresh rush
show concurrency.md '// rush/main.go' rush/main.go
quiet rush 'go mod init example.com/rush && go build -o rush .'
on rush 'go run . 3'
on rush 'curl -s -m 3 localhost:8080/events; echo "exit $?"'
on rush 'psql boxoffice -c "SELECT count(*) FROM pg_stat_activity WHERE datname = '"'"'boxoffice'"'"' AND state = '"'"'idle in transaction'"'"'"'
stop
on boxoffice 'tail -3 .server.log'

block fixed
python3 "$NTH" the-pool.md '// boxoffice/pgstore.go' 1 | lab put boxoffice/pgstore.go
quiet boxoffice 'dropdb boxoffice && createdb boxoffice'
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
lab exec boxoffice "curl -s -H 'Authorization: Bearer $MGR' --json '{\"name\": \"Organ Recital\", \"seats\": 5}' localhost:8080/admin/events" >/dev/null 2>&1
on rush 'go run . 3'
on rush 'psql boxoffice -c "SELECT count(*), sum(quantity) FROM tickets WHERE event_id = 3" -c "SELECT sold, seats FROM events WHERE id = 3"'
on rush 'curl -s -m 3 localhost:8080/events/3'
stop
on boxoffice 'grep -c "tickets 201" .server.log; grep -c "tickets 409" .server.log'
