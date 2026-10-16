#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of go-production, as a script that
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
#   - the four files of lesson 1's hits, placed from le-03nqvqms into ~/daily,
#     `go mod init example.com/hits` there, and access.log written by genlog
#     with the same 20,000 lines lesson 1 counts. The lesson names lesson 1 as
#     where they come from.
#   - /tmp/cold, the empty build cache section 02 points GOCACHE at, removed
#     before the block that uses it.
#   - in block install-tool, the module cache: that one `go install` runs with
#     GOMODCACHE pointing at an empty directory, so that it prints the
#     downloads a first install prints whatever earlier runs left in ana's
#     cache. The command shown is the command typed.
#   - `go clean -testcache` before the test block, so its first runs are runs
#     and not lines from the cache.
# Timings are real and vary between runs; the prose quotes the run it shows.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
# shown DIR 'what the prompt shows' 'what runs': for the one staged command
shown() { printf 'ana@vm:~/%s$ %s\n' "$1" "$2"; lab exec "$1" "$3" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
place1() { lab place le-03nqvqms "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

block setup
lab fresh daily
place1 arguments tools/genlog/main.go daily
place1 subcommands internal/tally/tally.go daily
place1 subcommands main.go daily
place1 output-and-exit-codes main_test.go daily
quiet daily 'go mod init example.com/hits'
quiet daily 'go run ./tools/genlog -n 20000 > access.log'
on daily 'find . -type f | sort'

block run
rm -rf /tmp/cold
on daily 'go env GOCACHE'
on daily 'GOCACHE=/tmp/cold go build -o hits . && echo built'
on daily 'GOCACHE=/tmp/cold go run -x . top -n 1 access.log 2>&1 | grep -E "link -o|exe/hits|-d/hits" | cut -c1-96'
on daily 'GOCACHE=/tmp/cold go run -x . top -n 1 access.log 2>&1 | grep -E "link -o|exe/hits|-d/hits" | cut -c1-96'
on daily 'go run .; echo $?'

block build
rm -rf /tmp/cold
quiet daily 'rm -f hits'
on daily 'time GOCACHE=/tmp/cold go build -o hits .'
on daily 'time GOCACHE=/tmp/cold go build -o hits .'
on daily 'du -sh /tmp/cold'
on daily 'touch main.go internal/tally/tally.go; GOCACHE=/tmp/cold go build -v -o hits .'
on daily "sed -i 's/want 5 fields/want five fields/' internal/tally/tally.go && GOCACHE=/tmp/cold go build -v -o hits ."
on daily "sed -i 's/want five fields/want 5 fields/' internal/tally/tally.go"
on daily 'GOCACHE=/tmp/cold go build -a -v -o hits . 2>&1 | wc -l'

block outputs
quiet daily 'rm -rf hits bin'
on daily 'go build ./... && ls'
on daily 'go build ./internal/tally && go build && ls'
on daily 'go build -o bin/ ./... && stat -c "%s bytes  %n" bin/*'

block install
on daily 'go env GOBIN GOPATH'
on daily 'go install . && command -v hits'
on daily 'cd /tmp && hits top -n 2 ~/daily/access.log'
on daily 'go version -m ~/go/bin/hits | head -3'

block install-tool
on daily 'go install golang.org/x/tools/cmd/stringer'
lab exec daily 'rm -rf /tmp/dailymod' >/dev/null 2>&1
shown daily 'go install golang.org/x/tools/cmd/stringer@v0.52.0' 'GOMODCACHE=/tmp/dailymod go install golang.org/x/tools/cmd/stringer@v0.52.0'
lab exec daily 'GOMODCACHE=/tmp/dailymod go clean -modcache' >/dev/null 2>&1
on daily 'cat go.mod'
on daily 'command -v stringer && go version -m $(command -v stringer) | head -5'

block clean-i
on daily 'go clean -i -n .'
on daily 'go clean -i . ; command -v hits; echo $?'

block test
quiet daily 'go clean -testcache'
place test internal/tally/tally_test.go daily
on daily 'go test ./...'
on daily 'go test ./...'
on daily 'go test -count=1 ./internal/tally'
on daily 'go test -short -v ./internal/tally'
on daily 'go test -list . ./internal/tally'

block run-flag
on daily 'go test -run TestParse/bad -v ./internal/tally'
on daily 'go test -run "TestParse/bad status" -v ./internal/tally'
on daily 'go test -run Top -v ./internal/tally'

block failfast
on daily "sed -i 's/115ms\", 404/115ms\", 403/' internal/tally/tally_test.go"
on daily 'go test ./internal/tally'
on daily 'go test -failfast -v ./internal/tally'
on daily "sed -i 's/115ms\", 403/115ms\", 404/' internal/tally/tally_test.go"

block json-cover
on daily 'go test -json -run TestTop ./internal/tally | cut -d, -f2-'
on daily 'go test -cover ./...'

block doc
on daily 'go doc'
on daily 'go doc ./internal/tally'
on daily 'go doc tally.Top'
on daily 'go doc tally.summary'
on daily 'go doc -short tally'
on daily 'go doc -src tally.Top'
on daily 'go doc -ex tally.Top'
on daily 'go doc -all tally | wc -l'

block doc-std
on daily 'go doc bufio.Scanner.Buffer'
on daily 'go doc bufio.MaxScanTokenSize'
on daily 'head -c 70000 /dev/zero | tr "\0" a | ./bin/hits count; echo $?'

block list
on daily 'go list ./...'
on daily 'go list -f "{{.Name}}  {{.ImportPath}}  {{.GoFiles}} {{.TestGoFiles}} {{.XTestGoFiles}}" ./...'
on daily 'go list -json=Dir,GoFiles,Imports ./internal/tally'
on daily 'go list -deps . | wc -l'
on daily 'go list -deps -f "{{if not .Standard}}{{.ImportPath}}{{end}}" .'
on daily 'go list -m all'
on daily 'go list -m -f "{{.Path}} {{.GoVersion}} {{.Dir}}"'
