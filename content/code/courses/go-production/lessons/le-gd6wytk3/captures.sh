#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of go-production, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it. Every program it runs is placed from
# the lesson's own .md (or from lesson 1's) by `lab.sh place`, so nothing here
# is a second copy.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the files of ~/lint taken from lesson 1 (le-03nqvqms): tools/genlog/main.go,
#     internal/tally/tally.go, main.go and main_test.go, and
#     `go mod init example.com/hits` there.
#   - internal/tally/report.go, staticcheck.conf, revive.toml, .golangci.yml,
#     internal/tally/share.go and .github/workflows/lint.yml, placed from this
#     lesson's sections.
#   - `git init` and the identity of the commits, which lesson 6 shows.
#   - the three `go install` lines run before the block that shows them, so a
#     first install's list of downloads does not depend on what an earlier
#     lesson left in the module cache. The lesson says what a first install
#     prints.
# The `time` lines are timings and vary between runs; nothing else is.
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
lab fresh lint
lab place le-03nqvqms arguments tools/genlog/main.go lint
lab place le-03nqvqms subcommands internal/tally/tally.go lint
lab place le-03nqvqms subcommands main.go lint
lab place le-03nqvqms output-and-exit-codes main_test.go lint
quiet lint 'go mod init example.com/hits'
quiet lint 'go install honnef.co/go/tools/cmd/staticcheck@v0.8.2'
quiet lint 'go install github.com/mgechev/revive@v1.17.1'
quiet lint 'go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0'

block staticcheck-clean
on lint 'go install honnef.co/go/tools/cmd/staticcheck@v0.8.2 && staticcheck -version'
on lint 'go vet ./... && staticcheck ./...; echo $?'

block staticcheck-report
place staticcheck internal/tally/report.go lint
on lint 'go vet ./...; echo $?'
on lint 'staticcheck ./...; echo $?'

block staticcheck-list
on lint 'staticcheck -list-checks | wc -l'
on lint 'staticcheck -list-checks | cut -c1-2 | sort | uniq -c'
on lint 'staticcheck -explain SA4003'

block staticcheck-conf
on lint 'staticcheck -checks=inherit,-ST1005 ./internal/tally; echo $?'
place staticcheck staticcheck.conf lint
on lint 'staticcheck ./... | grep -v SA1019'

block staticcheck-ignore
on lint "sed -i '/^func percent/i //lint:ignore U1000 kept for the -percent flag of the next release' internal/tally/report.go"
on lint "sed -i '/for path, n := range/i //lint:ignore S1003 a loop over paths' internal/tally/report.go"
on lint 'staticcheck ./... | grep -v SA1019'
quiet lint 'sed -i "/lint:ignore/d" internal/tally/report.go && rm staticcheck.conf'

block revive-default
on lint 'go install github.com/mgechev/revive@v1.17.1 && revive -version'
on lint 'revive ./... | sort -V'
on lint 'revive ./... > /dev/null; echo $?'
on lint 'revive -set_exit_status ./... > /dev/null; echo $?'

block revive-config
place revive revive.toml lint
on lint 'revive -config revive.toml ./... | sort -V'
on lint 'revive -config revive.toml ./... > /dev/null; echo $?'
on lint "revive -config revive.toml -formatter ndjson ./... | grep -o '\"Severity\":\"error\",\"Failure\":\"[^\"]*\"' | sort"

block revive-directive
on lint "sed -i '/^func NewReport/i //revive:disable-next-line:unexported-return the type stays private until the API settles' internal/tally/report.go"
on lint 'revive -config revive.toml ./internal/... | sort -V'
quiet lint 'sed -i "/revive:disable/d" internal/tally/report.go'

block golangci-install
on lint 'go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.14.0 && golangci-lint version'
on lint 'du -b $(command -v staticcheck revive golangci-lint)'
on lint 'golangci-lint linters --no-config | head -6'
on lint 'golangci-lint help linters | grep -c ": "'
on lint 'go version -m $(command -v golangci-lint) | grep -E "honnef|revive"'

block golangci-noconfig
on lint 'golangci-lint run --no-config --output.text.print-issued-lines=false; echo $?'

block golangci-config
place golangci-lint .golangci.yml lint
on lint 'golangci-lint config verify && golangci-lint run --output.text.print-issued-lines=false; echo $?'

block golangci-typo
on lint "printf 'version: \"2\"\\nlinters:\\n  enabel: [revive]\\n' > typo.yml"
on lint 'golangci-lint config verify -c typo.yml; echo $?'
quiet lint 'rm typo.yml'

block golangci-nolint
on lint "sed -i 's|0o644)\$|& //nolint|' internal/tally/report.go"
on lint 'golangci-lint run ./internal/... | head -6'
on lint "sed -i 's| //nolint\$||; s|^func percent.*{\$|& //nolint:unused // kept for the -percent flag of the next release|' internal/tally/report.go"
on lint 'golangci-lint run --output.text.print-issued-lines=false | tail -8'

block pipeline-baseline
on lint 'git init -q -b main && git config user.name Ana && git config user.email ana@example.com'
on lint 'git add -A && git commit -q -m "hits, with the warnings it has today" && git log --oneline | wc -l'
place in-the-pipeline internal/tally/share.go lint
on lint 'golangci-lint run --output.text.print-issued-lines=false | tail -9'
on lint 'golangci-lint run --new-from-rev=HEAD; echo $?'

block pipeline-branch
on lint 'git switch -q -c share && git add -A && git commit -q -m "tally: Share"'
on lint 'golangci-lint run --new-from-merge-base=main; echo $?'
on lint 'golangci-lint run --new-from-merge-base=main --issues-exit-code=0 > /dev/null; echo $?'
on lint 'golangci-lint run ./cmd/...; echo $?'

block pipeline-cache
on lint 'golangci-lint cache clean && time golangci-lint run > /dev/null'
on lint 'time golangci-lint run > /dev/null'
on lint 'golangci-lint cache status'

block workflow
place in-the-pipeline .github/workflows/lint.yml lint
on lint 'git add .github && git commit -q -m "ci: lint" && git log --oneline | head -1 | cut -c9-'
