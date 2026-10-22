#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of go-concurrency, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# THE PROGRAMS ARE THE LESSON'S OWN. Each file below, demo.sh included, is
# taken out of the section that shows it, by `lab.sh fence`, so the program
# that ran is the one the student reads. What is STAGED rather than typed:
# those files, written into ~/cases, and a `go mod init` there. Every server
# listens on 127.0.0.1:8412 and nowhere else, and is gone when its block ends.
# There is NO database on this machine, on purpose: "nodb" shows what the
# standard library says when no driver is registered. The timings differ by a
# few milliseconds on every run; the lesson quotes one run of this script.
#
# Recorded on Ubuntu 24.04, four processors, with go1.27.1 linux/amd64,
# curl 8.5.0, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
lab() { bash "$LAB" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
show() { lab fence "$HERE/$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }
block() { printf '##### %s\n' "$1"; }

lab fresh cases
show http.md cases/abandon abandon.go
show database.md cases/nodb nodb.go
show shutdown.md cases/shutdown shutdown.go
show shutdown.md cases/shutdown demo.sh
quiet cases 'go mod init example.com/cases'

block abandon
on cases 'go run ./abandon'

block doc
on cases 'go doc database/sql.DB.Query'
on cases 'go doc database/sql.Open | sed -n 8,11p'

block nodb
on cases 'go vet ./nodb && go run ./nodb'

block shutdown
on cases 'go build -o shutdown/shutdown ./shutdown'
on cases/shutdown 'bash demo.sh'
