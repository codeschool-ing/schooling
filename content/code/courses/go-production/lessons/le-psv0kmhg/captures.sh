#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of go-production, as a script that
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
#   - lesson 1's tools/genlog/main.go, internal/tally/tally.go and
#     main_test.go, placed from le-03nqvqms into ~/tags, with
#     `go mod init example.com/hits` and access.log written by genlog -n 20000,
#     exactly as lesson 1 shows them.
#   - this lesson's main.go, progress.go, signals.go and the progress_*.go,
#     debug.go, integration_test.go and check.sh files, placed from the
#     constraints, custom-tags and every-platform sections. The second versions
#     of progress_*.go and debug.go replace the first, as the lesson says.
#   - `true; ` in front of the commands that start a background job, which the
#     transcript does not show. lab.sh runs a command as `cd DIR && COMMAND`,
#     and without a separate first command the `&` would put the cd in the
#     background too. The student types the command from inside the directory
#     and needs nothing in front of it.
# The timings are hits's own debug line and go test's own lines.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB_SH=${LAB_SH:-$HERE/../../lab.sh}
LESSON=$(basename "$HERE")
lab() { bash "$LAB_SH" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
# bg prints the command as typed and runs it behind `true; ` (see the header).
bg() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "true; $*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
place() { lab place "$LESSON" "$1" "$2" "$3"; }
block() { printf '##### %s\n' "$1"; }

block setup
lab fresh tags
lab place le-03nqvqms arguments tools/genlog/main.go tags
lab place le-03nqvqms subcommands internal/tally/tally.go tags
lab place le-03nqvqms output-and-exit-codes main_test.go tags
quiet tags 'go mod init example.com/hits'
quiet tags 'go run ./tools/genlog -n 20000 > access.log'

block draft
place constraints main.go tags
place constraints progress.go tags
place constraints signals.go tags
on tags 'go build -o hits . && go build -o genlog ./tools/genlog'
bg tags './genlog -n 20000000 | ./hits count > /dev/null & sleep 1; kill -USR1 $!; sleep 1; kill -USR1 $!; wait $!'
on tags 'GOOS=windows go build -o hits.exe .; echo $?'

block split
on tags 'rm signals.go'
place constraints progress_unix.go tags
place constraints progress_darwin.go tags
place constraints progress_other.go tags
on tags 'go build -o hits . && GOOS=darwin go build -o hits-mac . && GOOS=windows go build -o hits.exe . && echo built'
bg tags './genlog -n 20000000 | ./hits count > /dev/null & sleep 1; kill -USR1 $!; wait $!'
on tags 'file hits-mac hits.exe | cut -d, -f1,2'

block mistakes
on tags "sed -i 's#^//go:build !unix#// go:build !unix#' progress_other.go; go vet ."
on tags "sed -i 's#^// go:build#//go:build#' progress_other.go; go vet . && echo clean"
on tags "printf 'package main\n\n//go:build windows\n' > late.go; go build -o hits .; rm late.go"

block plusbuild
on tags "mkdir old && printf '// +build linux,amd64\n\npackage old\n' > old/old.go"
on tags 'gofmt -d old/old.go'
on tags 'gofmt -w old/old.go && go fix -diff ./old'
on tags 'rm -r old'

block names
on tags "go list -f '{{.GoFiles}}' ."
on tags "GOOS=darwin go list -f '{{.GoFiles}}' ."
on tags "GOOS=windows go list -f '{{.GoFiles}} {{.IgnoredGoFiles}}' ."
on tags 'cp progress_darwin.go progress_mac.go; go vet .; rm progress_mac.go'
on tags "go list -f '{{join .GoFiles \"\\n\"}}' syscall | grep _linux_"
on tags "GOARCH=arm64 go list -f '{{join .GoFiles \"\\n\"}}' syscall | grep _linux_"
on tags "for os in linux darwin windows; do echo \"\$os: \$(GOOS=\$os go list -f '{{len .GoFiles}} files, {{len .IgnoredGoFiles}} left out' os)\"; done"

block debug
place custom-tags debug.go tags
on tags 'go build -o hits . && ./hits top -n 1 access.log'
on tags 'go build -tags debug -o hits-debug . && ./hits-debug top -n 1 access.log'
on tags 'go version -m hits-debug | grep -- -tags'
on tags "go list -f '{{.GoFiles}}' .; go list -tags debug -f '{{.GoFiles}}' ."
on tags 'strings hits | grep -c "hits: debug: "; strings hits-debug | grep -c "hits: debug: "'

block integration
place custom-tags integration_test.go tags
on tags 'go test -count=1 .'
on tags 'go test -count=1 -tags integration -run TestBinary -v .'
on tags "go list -f '{{.TestGoFiles}} {{.IgnoredGoFiles}}' ."
on tags "gofmt -r 'usage -> usageText' -w main.go && go vet ./... && go test -count=1 ./... && echo green"
on tags 'go vet -tags integration .'
on tags "gofmt -r 'usageText -> usage' -w main.go && go vet -tags integration . && echo clean"

block matrix
on tags "for t in linux/amd64 darwin/arm64 windows/amd64 freebsd/amd64; do echo \"\$t: \$(GOOS=\${t%/*} GOARCH=\${t#*/} go list -f '{{.GoFiles}}' .)\"; done"
on tags "GOOS=windows go list -tags debug -f '{{.GoFiles}}' ."

block loop
on tags 'for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go vet ./... && echo "ok  $t"; done'

block hint
place every-platform progress_unix.go tags
place every-platform debug.go tags
on tags 'go build -tags debug -o hits-debug . && ./hits-debug top -n 1 access.log'
on tags 'for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64 freebsd/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go vet ./... && echo "ok  $t"; done'

block check
place every-platform check.sh tags
on tags 'sh check.sh; echo $?'
place every-platform progress_darwin.go tags
place every-platform progress_other.go tags
on tags 'sh check.sh > /dev/null && echo "all 15 passed"'
