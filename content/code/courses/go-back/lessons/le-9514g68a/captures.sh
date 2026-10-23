#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every file of
# gormlab is taken out of the lesson's .md files.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the database gormlab is dropped before the run, so that AutoMigrate
#     meets an empty one, as it does the first time a student runs it.
# Timings in GORM's log are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, PostgreSQL 16.15,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
URL='postgres:///gormlab?host=/var/run/postgresql'

lab db
quiet . 'dropdb --if-exists gormlab'
lab fresh gormlab
show models.md '// gormlab/models/models.go' gormlab/models/models.go
show models.md '// gormlab/cmd/migrate/main.go' gormlab/cmd/migrate/main.go
show crud.md '// gormlab/cmd/crud/main.go' gormlab/cmd/crud/main.go
show relationships.md '// gormlab/cmd/relations/main.go' gormlab/cmd/relations/main.go
show n-plus-one.md '// gormlab/cmd/nplus1/main.go' gormlab/cmd/nplus1/main.go
show pitfalls.md '// gormlab/cmd/pitfalls/main.go' gormlab/cmd/pitfalls/main.go

block setup
on gormlab 'createdb gormlab'
on gormlab "export DATABASE_URL='$URL'"
on gormlab 'go mod init example.com/gormlab'
on gormlab 'go mod tidy'
on gormlab 'sed -n 1,8p go.mod'

block migrate
on gormlab "DATABASE_URL='$URL' go run ./cmd/migrate"
on gormlab 'psql gormlab -c "\d tickets"'

block crud
on gormlab "DATABASE_URL='$URL' go run ./cmd/crud"

block relations
on gormlab "DATABASE_URL='$URL' go run ./cmd/relations"

block nplus1
on gormlab "DATABASE_URL='$URL' go run ./cmd/nplus1"

block pitfalls
on gormlab "DATABASE_URL='$URL' go run ./cmd/pitfalls"
on gormlab 'psql gormlab -c "SELECT id, email, deleted_at FROM tickets WHERE email = '"'"'rui@example.com'"'"'"'
