#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# a lesson's own .md by `lab.sh place`, so nothing here is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# The lesson's directory is ~/cobra-hits rather than lesson 1's ~/hits, so that
# lesson 1's program stays as lesson 1 left it and both can be compared.
#
# What is STAGED rather than typed:
#   - tools/genlog/main.go and internal/tally/tally.go, placed from lesson 1
#     (le-03nqvqms), as the lesson tells the student to copy them.
#   - `go mod init example.com/hits` and the 20,000-line access.log, made the
#     way lesson 1 shows.
#   - main.go and main_test.go, placed from this lesson's sections.
#   - `go clean -testcache` before `go test`, so the run is a run.
#   - in block completion, an empty notes.txt and old/jan.log, so that the
#     .log filter has something to leave out and a directory to keep.
#   - the bash-completion package (Ubuntu 24.04's archive, installed with apt
#     on the lab machine), which the generated bash script needs and which
#     Ubuntu's default ~/.bashrc loads.
#   - the screen in completion.md is not a transcript: tools/term-capture ran
#     an interactive bash as ana and drew what it showed after the Tab
#     presses. The command is the last block below; it writes into $FIG.
# The module cache already held Cobra when this ran, so `go get` printed no
# `go: downloading` lines; the lesson says what a first run adds.
# Nothing here is a timing except the `ok` line of `go test`.
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
D=cobra-hits

block setup
lab fresh $D
lab place le-03nqvqms arguments tools/genlog/main.go $D
lab place le-03nqvqms subcommands internal/tally/tally.go $D
quiet $D 'go mod init example.com/hits'
quiet $D 'go run ./tools/genlog -n 20000 > access.log'
on $D 'go get github.com/spf13/cobra@v1.10.2'
place commands main.go $D
on $D 'go mod tidy'
on $D 'cat go.mod'
on $D 'find . -name "*.go" | sort'
on $D 'go build -o hits . && stat -c "%s bytes  %n" hits'
on $D './hits count access.log'
on $D './hits top -n 5 access.log'

block cost
on $D 'go list -m all'
on $D 'go version -m hits | grep dep'
on $D 'go list -deps . | grep template'
on $D 'wc -l main.go'
on $D 'cd $(go env GOMODCACHE)/github.com/spf13 && cat $(ls cobra@v1.10.2/*.go pflag@v1.0.9/*.go | grep -v _test) | wc -l'

block flags
on $D './hits top access.log -n 2'
on $D './hits top --number=2 access.log --json'
on $D './hits --json count access.log'
on $D './hits top -json access.log; echo $?'
on $D './hits count -n 2 access.log; echo $?'
on $D './hits top --help'

block help
on $D './hits --help'
on $D './hits help top | head -4'
on $D './hits cont access.log; echo $?'
on $D './hits; echo $?'
on $D './hits top -n five access.log; echo $?'
on $D './hits top a.log b.log; echo $?'
on $D './hits count nope.log; echo $?'
on $D './hits help cont 2>/dev/null | head -2; echo ${PIPESTATUS[0]}'

block test
place help-and-errors main_test.go $D
quiet $D 'go clean -testcache'
on $D 'go test -v .'

block completion
quiet $D 'mkdir -p old && touch notes.txt old/jan.log'
on $D './hits completion bash | wc -l'
on $D './hits completion bash | grep -n "requestComp=\|complete -o"'
on $D './hits __complete ""'
on $D './hits __complete t'
on $D './hits __complete t 2>/dev/null'
on $D './hits __complete top --'
on $D './hits __complete top ""'
on $D './hits __complete top access.log ""'
on $D 'ls -p'

block figure
printf '%s\n' 'source ~/.bashrc' "PS1='ana@vm:~/$D\$ '" > /tmp/cobra-tab.rc
chmod 644 /tmp/cobra-tab.rc
(cd "$REPO" && GOTOOLCHAIN=local go run ./tools/term-capture -cols 80 -rows 9 -warmup 2s \
  -repaint '' -quit '^C^D' -save "$FIG/tab.json" -out "$FIG/tab.svg" -label tab \
  -send 'source <(./hits completion bash)\r' -send './hits \t\t' -send 't\t' -send '\t\t' \
  -- runuser -u ana -- env -i HOME=/home/ana TERM=xterm LC_ALL=C.UTF-8 \
     PATH=/usr/local/go/bin:/usr/bin:/bin bash -c "cd ~/$D && exec bash --rcfile /tmp/cobra-tab.rc -i" \
  >/dev/null 2>&1)
python3 -c 'import json,sys; [print("".join(c["t"] or " " for c in r).rstrip()) for r in json.load(open(sys.argv[1]))]' "$FIG/tab.json"
rm -f /tmp/cobra-tab.rc
