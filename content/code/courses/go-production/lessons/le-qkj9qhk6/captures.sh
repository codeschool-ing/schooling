#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# a lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the four files of lesson 1 (tools/genlog/main.go, internal/tally/tally.go,
#     main.go, main_test.go), placed from lesson 1's sections into ~/race-hits;
#     the lesson says it starts from them.
#   - `go mod init example.com/hits` and the 20,000-line access.log, which
#     lesson 1 shows.
#   - the files this lesson prints, placed from its sections.
#   - in block cache, a private, empty GOCACHE for the two `go test -race`
#     runs, so that the first is a run and the second a hit however often
#     this script has run before. Ana's own cache is shared and never cleared.
#   - the two VmHWM lines run inside { ...; } (ongroup below), because lab.sh
#     puts a `cd &&` in front of every command and a bare `&` would background
#     the cd too. Ana types them at her prompt as printed.
#   - .github/workflows/race.yml is printed and NOT run: the lab has no GitHub.
#     Its two go commands are run here as they stand.
# Timings and memory figures are real and vary from run to run; the lesson
# quotes the run it pasted and the ratios.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, 4 CPUs,
# TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
D=race-hits
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }
# The same as on, with the command grouped in braces so that a `&` in it
# backgrounds that one command and not the `cd` lab.sh puts in front of it.
ongroup() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "{ $*; }" 2>&1 || true; }

block setup
lab fresh $D
lab place le-03nqvqms arguments tools/genlog/main.go $D
lab place le-03nqvqms subcommands internal/tally/tally.go $D
lab place le-03nqvqms subcommands main.go $D
lab place le-03nqvqms output-and-exit-codes main_test.go $D
quiet $D 'go mod init example.com/hits'
quiet $D 'go run ./tools/genlog -n 20000 > access.log'
place the-race-in-hits internal/tally/parallel.go $D
place the-race-in-hits internal/tally/parallel_test.go $D
place the-race-in-hits tools/pcount/main.go $D

block plain
on $D 'go vet ./... && go test -count=1 ./...'
on $D 'go build -o pcount ./tools/pcount && for i in 1 2 3 4 5 6; do ./pcount < access.log; done'

block race
on $D 'GORACE=halt_on_error=1 go test -race -count=1 ./internal/tally'
on $D 'go test -race -count=1 ./internal/tally 2>&1 | grep -c "WARNING: DATA RACE"'
on $D 'go build -race -o pcount-race ./tools/pcount && ./pcount-race < access.log 2>/dev/null; echo $?'

block unseen
place only-what-runs internal/tally/quiet_test.go $D
on $D 'go test -race -count=1 -run OneWorker -v ./internal/tally'
on $D 'nproc; taskset -c 0 nproc'
on $D 'taskset -c 0 go test -race -count=1 -run Default ./internal/tally'
on $D 'taskset -c 0 go test -race -count=1 -v ./internal/tally 2>&1 | grep -E "^(---|ok|FAIL)"'
on $D 'go test -race -count=1 -run Default ./internal/tally 2>&1 | tail -4'
on $D 'taskset -c 0 go test -race -count=1 -cpu 1,4 -run Default -v ./internal/tally 2>&1 | grep -E "^(=== RUN|---|ok|FAIL)"'

block fixed
place only-what-runs internal/tally/parallel.go $D
on $D 'go test -race -count=3 -cpu 1,2,4 ./...'
on $D 'go build -o pcount ./tools/pcount && for i in 1 2 3 4 5 6; do ./pcount < access.log; done'

block cost
on $D 'go test -run "^$" -bench . -benchmem ./internal/tally'
on $D 'go test -race -run "^$" -bench . -benchmem ./internal/tally'
on $D 'go test -c -o tally.test ./internal/tally && go test -race -c -o tally-race.test ./internal/tally'
on $D 'stat -c "%s bytes  %n" tally.test tally-race.test'
ongroup $D './tally.test -test.run "^$" -test.bench . > /dev/null & p=$!; while m=$(grep VmHWM /proc/$p/status 2>/dev/null); do h=$m; sleep 0.1; done; echo "$h"'
ongroup $D './tally-race.test -test.run "^$" -test.bench . > /dev/null & p=$!; while m=$(grep VmHWM /proc/$p/status 2>/dev/null); do h=$m; sleep 0.1; done; echo "$h"'

block exit-sleep
on $D 'go test -count=1 ./internal/tally; go test -race -count=1 ./internal/tally'
on $D 'GORACE=atexit_sleep_ms=0 go test -race -count=1 ./internal/tally'

block platforms
on $D 'go help build | grep -A4 "enable data race"'
on $D 'GOARCH=386 go test -race ./...; echo $?'
on $D 'CGO_ENABLED=0 go test -race ./...; echo $?'

block options
on $D 'GORACE=help=1 ./pcount-race < /dev/null 2>&1 | grep -A1 -E "^\s(halt_on_error|history_size|log_path|exitcode)$"'
on $D 'GORACE=exitcode=3 ./pcount-race < access.log > /dev/null 2>&1; echo $?'
on $D 'mkdir -p racelogs && GORACE=log_path=racelogs/race ./pcount-race < access.log; echo $?'
on $D 'ls racelogs && grep -c "WARNING: DATA RACE" racelogs/race.*'

block cache
quiet $D 'rm -rf .gocache'
printf 'ana@vm:~/%s$ %s\n' $D 'go test -race ./...; go test -race ./...'
lab exec $D 'export GOCACHE=$HOME/race-hits/.gocache; go test -race ./...; go test -race ./...' 2>&1
quiet $D 'rm -rf .gocache'

block staging
quiet $D 'rm -rf racelogs'
on $D 'CGO_ENABLED=1 go test -race -count=1 -cpu 1,4 ./...'
on $D 'CGO_ENABLED=1 go build -race -o pcount-race ./tools/pcount'
on $D 'mkdir -p racelogs && GORACE=log_path=racelogs/race ./pcount-race < access.log; echo $?; ls racelogs | wc -l'

quiet $D 'rm -f tally.test tally-race.test'
