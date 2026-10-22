#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of go-concurrency, as a script that
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
# the student reads.
# What is STAGED rather than typed: those files, written into ~/jsondemo, and a
# `go mod init` there. Nothing in this lesson depends on timing, so every run
# of this script prints the same.
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

lab fresh jsondemo
show marshal.md jsondemo order.go
show unmarshal.md jsondemo decode.go
show optional-fields.md jsondemo optional.go
show optional-fields.md jsondemo versions.go
quiet jsondemo 'go mod init example.com/jsondemo'

block order
on jsondemo 'go run order.go'

block decode
on jsondemo 'go run decode.go'

block optional
on jsondemo 'go run optional.go'

block versions
on jsondemo 'go run versions.go'

# The `output` the annotated example prints must be what the program printed.
want=$(python3 -c 'import json,re,sys; t=open(sys.argv[1]).read(); print(json.loads(re.search(r"```schooling-example\n(.*?)\n```", t, re.S).group(1))["output"])' "$HERE/marshal.md")
got=$(lab exec jsondemo 'go run order.go')
[ "$want" = "$got" ] || { echo "captures.sh: order.go's output differs from the example's" >&2; exit 1; }
