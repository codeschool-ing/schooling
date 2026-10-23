#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. sqlc.yaml,
# queries.sql and both versions of pgstore.go are taken out of the lesson's
# .md files (../../lab/nth.py picks the first or the second pgstore.go), and
# the rest of boxoffice is assembled from lessons 1 to 6 by project.py.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - sqlc v1.31.1 was installed in ana's ~/go/bin by the same `go install`
#     before this script ran, which took 1m03s of compiling; here it is
#     already built, so the command prints nothing.
#   - the lab has gcc, so the failure without a C compiler is produced by
#     pointing CC at a compiler that does not exist. On a machine with no gcc
#     the message is the same with gcc in it.
#   - the database is lesson 6's: dropped and made again from schema.sql, so
#     ids start at 1.
#   - the server is started in the background and stopped by the script.
#   - DATABASE_URL is exported before every command (PRELUDE), as lesson 6
#     section 02 has ana do in ~/.profile.
# Timestamps, durations and tokens are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, sqlc v1.31.1,
# PostgreSQL 16.15, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'
NTH=../../lab/nth.py
PRELUDE="export DATABASE_URL='$URL'"

lab db
project 8 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
quiet boxoffice 'dropdb --if-exists boxoffice && createdb boxoffice && psql -q boxoffice -f schema.sql'
python3 "$NTH" using-it.md '// boxoffice/pgstore.go' 1 | lab put boxoffice/pgstore.go
python3 "$NTH" configuration.md '-- boxoffice/queries.sql' 1 | lab put boxoffice/queries.sql

block install
on . 'go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1'
on . 'sqlc version; command -v sqlc'
on . 'CC=gcc-missing go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1'
on . 'gcc --version | head -1'

block generate
on boxoffice 'sqlc generate'
on boxoffice 'ls internal/db'
on boxoffice 'wc -l internal/db/*.go'
on boxoffice 'cat internal/db/models.go'
on boxoffice 'sed -n "/^const sellSeats/,/^\`/p" internal/db/queries.sql.go; sed -n "/^type SellSeatsParams/,/^}/p" internal/db/queries.sql.go; sed -n "/^func (q \*Queries) SellSeats/,/^}/p" internal/db/queries.sql.go'
on boxoffice 'cat internal/db/db.go'

block run-bug
quiet boxoffice 'go mod tidy'
on boxoffice 'go vet ./...'
MGR=$(openssl rand -hex 16)
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
on boxoffice 'curl -s localhost:8080/events'
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets"
on boxoffice 'curl -s localhost:8080/events/9'
on boxoffice 'curl -s localhost:8080/events/4294967297'
stop

block run-fixed
python3 "$NTH" using-it.md '// boxoffice/pgstore.go' 2 | lab put boxoffice/pgstore.go
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
on boxoffice 'curl -s localhost:8080/events/4294967297'
on boxoffice 'curl -s localhost:8080/events/1'
stop
on boxoffice 'cat .server.log'

block catches
python3 "$NTH" configuration.md '# boxoffice/sqlc.yaml' 1 | lab put boxoffice/sqlc.yaml
on boxoffice "sed -i 's/seats - sold >= sqlc.arg(quantity)/seats - sould >= sqlc.arg(quantity)/' queries.sql && sqlc generate && go build ./... && echo built"
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets"
stop
on boxoffice 'tail -2 .server.log'
python3 "$NTH" what-it-catches.md '# boxoffice/sqlc.yaml' 1 | lab put boxoffice/sqlc.yaml
on boxoffice "sqlc generate"
on boxoffice "sed -i 's/seats - sould/seats - sold/' queries.sql && sqlc generate && echo clean"
on boxoffice "sed -i 's/VALUES (\$1, \$2)/VALUES (\$1)/' queries.sql && sqlc generate"
on boxoffice "sed -i 's/VALUES (\$1)/VALUES (\$1, \$2)/' queries.sql && sqlc generate && echo clean"
on boxoffice 'env -u DATABASE_URL sqlc generate 2>&1 | head -2'

block dynamic
python3 "$NTH" dynamic-queries.md '-- boxoffice/queries.sql' 1 | lab put boxoffice/queries.sql
on boxoffice "sqlc generate"
on boxoffice 'sed -n "/^type SearchEventsParams/,/^}/p;/^func (q \*Queries) SearchEvents/,+1p" internal/db/queries.sql.go'
on boxoffice 'go build ./... && echo builds'
