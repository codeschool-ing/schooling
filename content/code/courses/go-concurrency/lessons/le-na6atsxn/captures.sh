#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of go-concurrency, as a script that
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
# section that shows it, by `lab.sh fence`, so the program that ran is the one
# the student reads. What is STAGED rather than typed: those files, written
# into ~/promise, and a `go mod init` there. In "no-compiler" the machine
# without a C compiler is a PATH with only Go's own directory in it: the lab
# machine has gcc, and hiding it is the honest way to show what a machine
# without one says. The timings differ on every run, and so does the order
# of the lines in "order" and the totals in "count"; the lesson quotes one run
# of this script.
#
# Recorded on Ubuntu 24.04, four processors, with go1.27.1 linux/amd64 and
# gcc 13.3.0, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
lab() { bash "$LAB" "$@"; }
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
show() { lab fence "$HERE/$1" "$3" ${4:-} | lab put "$2/$3" || exit 1; }
block() { printf '##### %s\n' "$1"; }

lab fresh promise
show two-words.md promise spin.go
show two-words.md promise wait.go
show the-lab.md promise order.go
show what-go-promises.md promise count.go
quiet promise 'go mod init example.com/promise'

block check
on promise 'go version'
on promise 'command -v go gofmt gcc'
on promise 'gcc --version | head -1'
on promise 'go env CGO_ENABLED CC'

block race-works
on promise 'go run -race order.go'

block spin
on promise 'nproc'
on promise 'go build -o spin spin.go'
on promise './spin'
on promise 'GOMAXPROCS=1 ./spin'
on promise 'GOMAXPROCS=2 ./spin'

block wait
on promise 'go build -o wait wait.go'
on promise './wait'
on promise 'GOMAXPROCS=1 ./wait'

block order
on promise 'go build -o order order.go'
on promise 'for i in 1 2 3 4 5; do ./order | paste -sd " "; done'

block count
on promise 'go build -o count count.go'
on promise 'for i in 1 2 3 4 5; do ./count; done'
on promise 'go run -race count.go'

block no-compiler
on promise 'PATH=/usr/local/go/bin go env CGO_ENABLED'
on promise 'PATH=/usr/local/go/bin go run -race count.go; echo $?'
on promise 'PATH=/usr/local/go/bin CGO_ENABLED=1 go run -race count.go; echo $?'
on promise 'CGO_ENABLED=0 go run -race count.go; echo $?'
