#!/usr/bin/env bash
# The terminal sessions and screens quoted in lesson 4 of go-production, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# a lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# The lesson's directory is ~/tea-hits rather than lesson 1's ~/hits, so that
# lesson 1's program stays as lesson 1 left it.
#
# What is STAGED rather than typed:
#   - tools/genlog/main.go, internal/tally/tally.go and main_test.go, placed
#     from lesson 1 (le-03nqvqms), as the lesson tells the student to copy them.
#   - `go mod init example.com/hits` and the 20,000-line access.log, made the
#     way lesson 1 shows.
#   - every other .go file, placed from this lesson's sections.
#   - `go clean -testcache` before `go test`, so the run is a run.
#   - in block raw, hits-raw: browse.go with its terminal check (the first
#     `if` block of browse) deleted by sed and built under another name, which
#     is what section 05 tells the student to do by hand.
#   - THE SCREENS ARE NOT TRANSCRIPTS. tools/term-capture ran each one under a
#     pseudo-terminal as ana, typed the keys given with -send, and drew what
#     the terminal showed. Blocks list, open and fail; each writes into $FIG.
#     Block fail prints the rows of the screen it read, and that text is the
#     transcript of the three failing commands in section 04: they ran on a
#     terminal, where a pipe would have met the terminal check first.
#   - msgs.log is written by the run that block list photographs, and only
#     then shown with cat.
# The module cache already held Bubble Tea when this ran, so `go get` printed
# no `go: downloading` lines; the lesson says what a first run adds.
# Nothing here is a timing except the `ok` lines of `go test`.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
REPO=$(cd "$HERE/../../../../../.." && pwd)
FIG=${FIG:-/tmp}
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }
D=tea-hits

# A program run under a pseudo-terminal as ana, with ana's PATH and nothing
# else from whoever runs this. The first argument is a shell command run in
# ~/tea-hits; the rest are term-capture's flags.
tc() {
  local cmd=$1; shift
  (cd "$REPO" && GOTOOLCHAIN=local go run ./tools/term-capture "$@" \
    -- runuser -u ana -- env -i HOME=/home/ana TERM=xterm-256color LANG=C.UTF-8 LC_ALL=C.UTF-8 \
       TZ=America/Sao_Paulo PATH=/usr/local/go/bin:/home/ana/go/bin:/usr/bin:/bin \
       bash -c "cd ~/$D && $cmd" >/dev/null 2>&1)
}
rows() { python3 -c 'import json,sys; [print("".join(c["t"] or " " for c in r).rstrip()) for r in json.load(open(sys.argv[1]))]' "$1"; }

block setup
lab fresh $D
lab place le-03nqvqms arguments tools/genlog/main.go $D
lab place le-03nqvqms subcommands internal/tally/tally.go $D
lab place le-03nqvqms output-and-exit-codes main_test.go $D
quiet $D 'go mod init example.com/hits'
quiet $D 'go run ./tools/genlog -n 20000 > access.log'
on $D 'go get charm.land/bubbletea/v2@v2.1.0 golang.org/x/term@v0.47.0'
place the-model internal/tui/model.go $D
place update-and-messages internal/tui/update.go $D
place commands-and-io internal/tui/load.go $D
place commands-and-io browse.go $D
place commands-and-io main.go $D
on $D 'go mod tidy'
on $D 'find . -name "*.go" | sort'
on $D 'go build -o hits . && stat -c "%s bytes  %n" hits'
on $D 'go list -deps -f "{{if not .Standard}}{{.ImportPath}}{{end}}" . | grep -v ^example.com | grep -c .'
on $D './hits'

block list
tc 'HITS_DEBUG=msgs.log ./hits browse access.log' -cols 72 -rows 14 -warmup 2s -repaint '' \
  -send 'jj' -save "$FIG/tea-list.json" -out "$FIG/tea-list.svg" -label list
rows "$FIG/tea-list.json"
on $D 'cat msgs.log'

block open
tc './hits browse access.log' -cols 72 -rows 14 -warmup 2s -repaint '' \
  -send 'jj' -send '\r' -save "$FIG/tea-open.json" -out "$FIG/tea-open.svg" -label open
rows "$FIG/tea-open.json"

block fail
on $D "printf 'oops\n' > bad.log"
printf '%s\n' "PS1='ana@vm:~/$D\$ '" > /tmp/tea-fail.rc
chmod 644 /tmp/tea-fail.rc
tc 'exec bash --noprofile --rcfile /tmp/tea-fail.rc -i' -cols 72 -rows 10 -warmup 2s -repaint '' \
  -quit '^D' -send './hits browse; echo $?\r' \
  -send './hits browse nope.log; echo $?\r' -send './hits browse bad.log; echo $?\r' \
  -save "$FIG/tea-fail.json" -out "$FIG/tea-fail.svg" -label fail
rows "$FIG/tea-fail.json"
rm -f /tmp/tea-fail.rc

block test
quiet $D 'go clean -testcache'
place testing-and-limits internal/tui/tui_test.go $D
on $D 'go test -v ./internal/tui'
on $D 'go test ./...'

block plain
on $D './hits browse access.log | head -3; echo ${PIPESTATUS[@]}'
on $D './hits browse access.log > /dev/null; echo $?'
on $D 'stat -c "%F  %n" /dev/null'
on $D './hits top -n 3 access.log | cat'

block raw
quiet $D "sed -e '/if f, ok := stdout/,/^\t}/d' -e '/golang.org.x.term/d' browse.go > /tmp/browse-raw.go"
lab exec $D 'mkdir -p ../tea-raw && cp -r go.mod go.sum main.go internal access.log ../tea-raw/ && cp /tmp/browse-raw.go ../tea-raw/browse.go && cd ../tea-raw && go build -o ../tea-hits/hits-raw .' 2>&1
tc './hits-raw browse access.log > screen.out' -cols 72 -rows 14 -warmup 2s -repaint '' \
  -out "$FIG/tea-raw.svg" -label raw
on $D 'wc -c screen.out'
on $D 'grep -c login screen.out'
on $D 'od -c screen.out | head -4'
quiet $D 'rm -rf ../tea-raw hits-raw'
