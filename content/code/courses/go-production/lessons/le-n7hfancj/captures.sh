#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of go-production, as a script that
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
#   - the files of ~/gen-try and ~/gen-hits, placed from this lesson's sections
#     and, for internal/tally/tally.go, main.go and tools/genlog/main.go, from
#     lesson 1 (le-03nqvqms).
#   - `go mod init` in both directories, which lesson 1 shows once.
#   - access.log in ~/gen-hits, written by lesson 1's genlog with -n 20000 and
#     the default seed, exactly as lesson 1 writes it.
#   - `git config user.name` and `user.email` in ~/gen-hits before the first
#     commit, which git asks for once per machine.
# Nothing here is a timing.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

block directives
lab fresh gen-try
place directives internal/demo/demo.go gen-try
quiet gen-try 'go mod init example.com/try'
on gen-try 'go build ./... && ls internal/demo'
on gen-try 'go generate ./...'
on gen-try 'ls internal/demo'
on gen-try 'go generate -n ./...'
on gen-try 'GOARCH=arm64 go generate -x -run echo ./...'
on gen-try 'go generate -v -skip "touch|printf" ./...'

block stringer
lab fresh gen-hits
lab place le-03nqvqms subcommands internal/tally/tally.go gen-hits
lab place le-03nqvqms subcommands main.go gen-hits
lab place le-03nqvqms arguments tools/genlog/main.go gen-hits
quiet gen-hits 'go mod init example.com/hits'
quiet gen-hits 'go run ./tools/genlog -n 20000 > access.log'
on gen-hits 'grep -r --include="*.go" "^//go:generate" $(go env GOROOT)/src | wc -l'
on gen-hits 'grep -r --include="*.go" "^//go:generate stringer" $(go env GOROOT)/src | wc -l'
place stringer internal/status/class.go gen-hits
on gen-hits 'go get -tool golang.org/x/tools/cmd/stringer@v0.52.0'
on gen-hits 'cat go.mod'
on gen-hits 'go generate -x ./...'
on gen-hits 'cat internal/status/class_string.go'
place stringer cmd/classes/main.go gen-hits
on gen-hits 'go run ./cmd/classes < access.log'

block guard
on gen-hits 'sed -i "s/iota + 1/iota/" internal/status/class.go && go build ./...; echo $?'
on gen-hits 'sed -i "s/= iota /= iota + 1 /" internal/status/class.go && go build ./... && echo built'

block generator
place writing-a-generator internal/owner/owners.txt gen-hits
place writing-a-generator tools/genowners/main.go gen-hits
place writing-a-generator internal/owner/owner.go gen-hits
on gen-hits 'go generate -x ./internal/owner'
on gen-hits 'cat internal/owner/owners_gen.go'
on gen-hits 'gofmt -l internal/owner; echo $?'
place writing-a-generator cmd/teams/main.go gen-hits
on gen-hits 'go run ./cmd/teams < access.log'
on gen-hits 'echo "/login  security" >> internal/owner/owners.txt && go generate ./internal/owner; echo $?'
on gen-hits 'sed -i "\$d" internal/owner/owners.txt && go generate ./internal/owner && echo regenerated'

block fix
on gen-try 'go doc go/ast IsGenerated | head -5'
place keeping-it-honest legacy/old.go gen-try
place keeping-it-honest legacy/old_gen.go gen-try
on gen-try 'go fix -diff ./legacy; echo $?'

block ci
place keeping-it-honest .gitignore gen-hits
quiet gen-hits 'git init -q && git config user.name Ana && git config user.email ana@example.com'
on gen-hits 'git add . && git commit -qm "hits, with generated code" && git ls-files "*_string.go" "*_gen.go"'
on gen-hits 'go generate ./... && git diff --exit-code; echo $?'
on gen-hits 'sed -i "s/-type=Class$/-type=Class -linecomment/" internal/status/class.go && go build ./... && git commit -qam "print 4xx, not ClientError" && echo committed'
on gen-hits 'go generate ./... && git diff --exit-code; echo $?'
on gen-hits 'go run ./cmd/classes < access.log'

block tool
on gen-hits 'go tool | tail -1'
