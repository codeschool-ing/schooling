#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. schema.sql and the
# three small programs are taken out of the lesson's .md files, and boxoffice
# is assembled from lessons 1 to 6 by ../../lab/project.py.
#
#   sudo bash ../../lab.sh setup      # once: Go, ana, PostgreSQL 16
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - PostgreSQL 16 was installed by `lab.sh setup` with the same
#     `apt install postgresql` the lesson shows; the install itself is not
#     transcribed. Before the first block the script drops the database
#     boxoffice and the role ana, so that the lesson's createuser and createdb
#     meet a cluster as a fresh install leaves it.
#   - the cluster is stopped and started with pg_ctlcluster for the block on
#     a stopped server, as ana does with sudo.
#   - each Go server is started in the background and stopped by the script;
#     what it printed is read from its log afterwards.
# Timestamps, durations and tokens are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///boxoffice?host=/var/run/postgresql'

lab db
runuser -u postgres -- psql -qX -c 'DROP DATABASE IF EXISTS boxoffice' >/dev/null
runuser -u postgres -- psql -qX -c 'DROP DATABASE IF EXISTS ana' >/dev/null
runuser -u postgres -- psql -qX -c 'DROP ROLE IF EXISTS ana' >/dev/null
lab fresh boxoffice

block install
on boxoffice 'psql --version'
on boxoffice 'pg_lsclusters'
on boxoffice 'psql -c "SELECT 1"'
on boxoffice 'sudo -u postgres createuser --superuser $USER'
on boxoffice 'createdb boxoffice'
on boxoffice 'psql boxoffice -c "SELECT current_user, current_database()"'

block fails
on boxoffice 'psql -c "SELECT 1"'
on boxoffice 'sudo pg_ctlcluster 16 main stop'
on boxoffice 'psql boxoffice -c "SELECT 1"'
on boxoffice 'pg_lsclusters'
on boxoffice 'sudo pg_ctlcluster 16 main start'
on boxoffice 'psql -h localhost -w boxoffice -c "SELECT 1"'
on boxoffice 'psql nowhere -c "SELECT 1"'

block schema
show the-schema.md '-- boxoffice/schema.sql' boxoffice/schema.sql
on boxoffice 'psql boxoffice -f schema.sql'
on boxoffice 'psql boxoffice -c "\d events"'
on boxoffice 'psql boxoffice -c "SELECT * FROM events"'

block dbsql
lab fresh dbsql
show database-sql.md '// dbsql/main.go' dbsql/main.go
on dbsql "export DATABASE_URL='$URL'"
on dbsql 'go mod init example.com/dbsql'
on dbsql 'go mod tidy'
on dbsql "DATABASE_URL='$URL' go run ."

block quote
lab fresh quote
show placeholders.md '// quote/main.go' quote/main.go
quiet quote 'go mod init example.com/quote && go mod tidy'
on quote "DATABASE_URL='$URL' go run ."

block nulls
lab fresh nulls
show errors-and-null.md '// nulls/main.go' nulls/main.go
quiet nulls 'go mod init example.com/nulls && go mod tidy'
on nulls "DATABASE_URL='$URL' go run ."

block boxoffice
project 6 tmp-boxoffice
quiet tmp-boxoffice 'cp *.go ~/boxoffice/'
lab exec . 'rm -rf ~/tmp-boxoffice'
quiet boxoffice 'go mod init example.com/boxoffice'
on boxoffice 'go mod tidy'
on boxoffice 'go vet ./...'
MGR=$(openssl rand -hex 16); DOOR=$(openssl rand -hex 16)
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR BOXOFFICE_DOOR_TOKEN=$DOOR DATABASE_URL='$URL' go run ."
on boxoffice 'curl -s localhost:8080/events'
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/2/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/9/tickets"
printf 'ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json %s localhost:8080/admin/events\n' "'{\"name\": \"Chamber Choir\", \"seats\": 10}'"
lab exec boxoffice "curl -s -H 'Authorization: Bearer $MGR' --json '{\"name\": \"Chamber Choir\", \"seats\": 10}' localhost:8080/admin/events" 2>&1
printf 'ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json %s localhost:8080/admin/events\n' "'{\"name\": \"Organ Recital\", \"seats\": 60}'"
lab exec boxoffice "curl -s -H 'Authorization: Bearer $MGR' --json '{\"name\": \"Organ Recital\", \"seats\": 60}' localhost:8080/admin/events" 2>&1
stop
on boxoffice 'cat .server.log'
block restart
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR DATABASE_URL='$URL' go run ."
on boxoffice 'curl -s localhost:8080/events'
stop
on boxoffice 'psql boxoffice -c "SELECT * FROM events ORDER BY id"'
block nourl
on boxoffice 'BOXOFFICE_MANAGER_TOKEN=x go run .'
on boxoffice "BOXOFFICE_MANAGER_TOKEN=x DATABASE_URL='postgres:///nowhere?host=/var/run/postgresql' go run ."
