#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of go-production, as a script that
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
#   - ~/fmt, a copy of hits: lesson 1's tally.go, main.go, main_test.go and
#     genlog, placed from lesson 1, and `go mod init example.com/hits`, which
#     lesson 1 shows.
#   - `go run ./tools/genlog -n 20000 > access.log`, as lesson 1 runs it.
#   - `go install golang.org/x/tools/cmd/goimports@v0.52.0` and
#     `go get golang.org/x/text@v0.43.0`, which the lesson prints as commands
#     rather than transcripts: the "go: downloading" lines they print depend on
#     what the module cache already holds, so no run of them is one anybody
#     else will see again. The lesson shows what they left behind instead.
#   - one `go run` of goimports@v0.52.0 before the hook, so its first build
#     is not inside a transcript.
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

block setup
lab fresh fmt
for f in tools/genlog/main.go; do lab place le-03nqvqms arguments "$f" fmt; done
for f in internal/tally/tally.go main.go; do lab place le-03nqvqms subcommands "$f" fmt; done
lab place le-03nqvqms output-and-exit-codes main_test.go fmt
quiet fmt 'go mod init example.com/hits'
quiet fmt 'go run ./tools/genlog -n 20000 > access.log'

block gofmt-stdout
place gofmt internal/tally/classes.go fmt
on fmt 'gofmt internal/tally/classes.go'

block gofmt-flags
on fmt 'gofmt -l .'
on fmt 'gofmt -d internal/tally/classes.go | head -20'
on fmt 'go fmt -n ./...'
on fmt 'go fmt ./...'
on fmt 'go fmt ./...'
on fmt 'gofmt -l .'

block options
on fmt 'gofmt -h'
on fmt 'printf "package p\n\nfunc f()\n{\n}\n" | gofmt'
on fmt "awk 'length > 100 {print NR \": \" length \" characters\"}' internal/tally/classes.go"

block simplify
place what-it-decides internal/tally/classes_test.go fmt
on fmt 'go test ./internal/tally'
on fmt 'gofmt -l .'
on fmt 'gofmt -s -l .'
on fmt 'gofmt -s -d internal/tally/classes_test.go'
on fmt 'gofmt -s -w internal/tally/classes_test.go && gofmt -s -l .'

block rewrite
on fmt "gofmt -r 'fmt.Fprintf(w, \"hits: %v\\n\", e) -> fmt.Fprintln(w, \"hits:\", e)' -l ."
on fmt "gofmt -r 'fmt.Fprintf(w, \"hits: %v\\n\", e) -> fmt.Fprintln(w, \"hits:\", e)' -d main.go | grep '^[-+]'"
on fmt "gofmt -r 'a.Duration -> a.Took' -d internal/tally/tally.go | grep '^[-+]'"

block goimports
quiet fmt 'go install golang.org/x/tools/cmd/goimports@v0.52.0'
on fmt 'go version -m $(command -v goimports) | head -3'
place goimports tools/classes/main.go fmt
on fmt 'go build ./tools/classes'
quiet fmt 'go get golang.org/x/text@v0.43.0'
on fmt 'cat go.mod'
on fmt 'goimports -l .'
on fmt 'goimports -w tools/classes/main.go && sed -n "/^import/,/^)/p" tools/classes/main.go'
on fmt 'goimports -local example.com/hits -w tools/classes/main.go && sed -n "/^import/,/^)/p" tools/classes/main.go'
on fmt 'go build -o classes ./tools/classes && ./classes < access.log'
on fmt 'go mod tidy && cat go.mod'

block trap
place gofmt internal/tally/classes.go fmt
on fmt 'gofmt -l .; echo $?'
on fmt 'test -z "$(gofmt -l .)"; echo $?'
on fmt 'gofmt -d . > /dev/null; echo $?'
on fmt 'goimports -d . > /dev/null; echo $?'

block hook
place in-the-pipeline scripts/check-fmt.sh fmt
on fmt 'git init -q -b main && git config user.name Ana && git config user.email ana@example.com'
place in-the-pipeline .git/hooks/pre-commit fmt
place in-the-pipeline .github/workflows/format.yml fmt
quiet fmt 'go run golang.org/x/tools/cmd/goimports@v0.52.0 -h'
on fmt 'chmod +x scripts/check-fmt.sh .git/hooks/pre-commit'
on fmt "git add go.mod go.sum '*.go' scripts .github && git commit -q -m 'hits, formatted'; echo \$?"
on fmt 'go fmt ./...'
on fmt "git add -u && git commit -q -m 'hits, formatted'; echo \$?"
on fmt 'git log --oneline | wc -l'

block broken
on fmt "echo 'package tally; func Broken(' > internal/tally/broken.go"
on fmt 'test -z "$(gofmt -l .)"; echo $?'
on fmt 'out=$(gofmt -l .) && test -z "$out"; echo $?'
on fmt 'sh scripts/check-fmt.sh; echo $?'
on fmt 'rm internal/tally/broken.go'
