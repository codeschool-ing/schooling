#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of go-concurrency, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, gcc and the student, ana
#   sudo bash captures.sh
#
# THE PROGRAMS ARE THE LESSON'S OWN. Each file below is taken out of the
# section that shows it, by `lab.sh fence`, in the order the lesson shows them,
# so the code that ran is the code the student reads. What is STAGED rather
# than typed: those files, written into ~/wordcount, and the
# `go mod init example.com/wordcount` the first section names. The timings and
# the name of the temporary directory differ on every run; the lesson quotes
# one run of this script.
#
# Recorded on Ubuntu 24.04, four processors, with go1.27.1 linux/amd64,
# TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
lab() { bash "$LAB" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
show() { lab fence "$HERE/$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }
block() { printf '##### %s\n' "$1"; }

lab fresh wordcount
quiet wordcount 'go mod init example.com/wordcount'

show first-test.md wordcount wordcount.go 1
show first-test.md wordcount wordcount_test.go
block first-fail
on wordcount 'go test'

show first-test.md wordcount wordcount.go 2
block first-pass
on wordcount 'go test'
on wordcount 'go test -v'

show subtests.md wordcount wordcount_test.go
block subtests
on wordcount 'go test -v'
block run-one
on wordcount "go test -v -run 'TestCount/possessive'"
on wordcount "go test -run 'Count/^(case|accents)\$'"

show helpers.md wordcount demo_test.go 1
block helper-without
on wordcount 'go test -run TestDemo'
show helpers.md wordcount demo_test.go 2
block helper-with
on wordcount 'go test -run TestDemo'
on wordcount 'rm demo_test.go'

show helpers.md wordcount file.go
show helpers.md wordcount wordcount_test.go
block final
out=$(lab exec wordcount 'go test -v' 2>&1)
printf 'ana@vm:~/wordcount$ go test -v\n%s\n' "$out"
dir=$(printf '%s\n' "$out" | sed -n 's|.*working in \(/tmp/[^/]*\)/.*|\1|p')
on wordcount "ls $dir"
