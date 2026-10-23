#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of go-production, as a script that
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
#   - tools/genlog/main.go and internal/tally/tally.go, placed from lesson 1
#     (le-03nqvqms) into ~/plugins, `go mod init example.com/hits`, and
#     access.log written by `genlog -n 20000`, as the a-plugin section says.
#   - every other file of ~/plugins, placed from this lesson's sections in the
#     order the sections print them; internal/tally/errors.go is placed at the
#     point where-it-breaks adds it.
#   - Go 1.27.2, used by one command in block flags through GOTOOLCHAIN. It is
#     already in ana's module cache on the lab machine; on a machine where it
#     is not, the go command downloads it first and prints a line saying so.
#   - gcr.io/distroless/static-debian12:nonroot, already pulled into ana's
#     podman storage by lesson 18. Containers run with --network=none because
#     this sandbox has no /dev/net/tun; nothing here needs a network.
# The timings are the ns/op of block bench; they vary between runs, and the
# lesson quotes them rounded, with their ratio.
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
lab fresh plugins
lab place le-03nqvqms arguments tools/genlog/main.go plugins
lab place le-03nqvqms subcommands internal/tally/tally.go plugins
quiet plugins 'go mod init example.com/hits'
quiet plugins 'go run ./tools/genlog -n 20000 > access.log'

block build-plugins
place a-plugin report/report.go plugins
place a-plugin reporters/csv/csv.go plugins
place a-plugin reporters/mean/mean.go plugins
place a-plugin plugins/csv/main.go plugins
place a-plugin plugins/mean/main.go plugins
on plugins 'go build -buildmode=plugin -o csv.so ./plugins/csv'
on plugins 'go build -buildmode=plugin -o mean.so ./plugins/mean'
on plugins 'stat -c "%s bytes  %n" csv.so mean.so'

block run
place a-plugin cmd/hits-plugin/main.go plugins
on plugins 'go build -o hits-plugin ./cmd/hits-plugin'
on plugins './hits-plugin access.log csv.so mean.so'

block once
on plugins './hits-plugin access.log csv.so csv.so | wc -l'

block linked
on plugins 'stat -c "%s bytes  %n" hits-plugin'
on plugins 'readelf -d hits-plugin | grep NEEDED'

block shared
on plugins 'go list -deps -buildmode=plugin ./plugins/csv | sort > plugin.deps'
on plugins 'go list -deps ./cmd/hits-plugin | sort > host.deps'
on plugins 'comm -12 plugin.deps host.deps | wc -l'
on plugins 'comm -23 plugin.deps host.deps'
on plugins 'wc -l < plugin.deps; wc -l < host.deps'
on plugins 'nm -D --defined-only hits-plugin | wc -l'

block changed
place where-it-breaks internal/tally/errors.go plugins
on plugins 'go build -o hits-plugin ./cmd/hits-plugin'
on plugins './hits-plugin access.log csv.so; echo $?'
on plugins 'go build -buildmode=plugin -o csv.so ./plugins/csv && go build -buildmode=plugin -o mean.so ./plugins/mean'
on plugins './hits-plugin access.log csv.so mean.so | tail -1'

block flags
on plugins 'go build -trimpath -o hits-trim ./cmd/hits-plugin && ./hits-trim access.log csv.so'
on plugins 'go build -race -o hits-race ./cmd/hits-plugin && ./hits-race access.log csv.so'
on plugins 'GOTOOLCHAIN=go1.27.2 go version'
on plugins 'GOTOOLCHAIN=go1.27.2 go build -buildmode=plugin -o csv-next.so ./plugins/csv'
on plugins './hits-plugin access.log csv-next.so'

block reload
on plugins 'go doc plugin.Plugin'
on plugins 'cp csv.so csv-copy.so && cmp csv.so csv-copy.so && echo identical'
on plugins './hits-plugin access.log csv.so csv-copy.so | wc -l'

block platforms
on plugins 'CGO_ENABLED=0 go build -buildmode=plugin -o x.so ./plugins/csv'
on plugins 'GOOS=windows go build -buildmode=plugin -o x.dll ./plugins/csv'
on plugins 'GOOS=darwin GOARCH=arm64 go build -buildmode=plugin -o x.so ./plugins/csv'
on plugins 'CGO_ENABLED=0 go build -o hits-nocgo ./cmd/hits-plugin && ./hits-nocgo access.log csv.so'
on plugins 'go tool dist list | wc -l'

block exec
place the-alternatives exec/mean/main.go plugins
place the-alternatives exec/top.py plugins
place the-alternatives cmd/hits-exec/main.go plugins
on plugins 'chmod +x exec/top.py'
on plugins 'go build -o mean-exec ./exec/mean && go build -o hits-exec ./cmd/hits-exec'
on plugins './hits-exec access.log ./mean-exec exec/top.py'

block protocol
on plugins "echo '{\"protocol\":2}' | ./mean-exec; echo \$?"

block crash
on plugins 'touch empty.log'
on plugins 'GOTRACEBACK=none ./hits-plugin empty.log csv.so mean.so; echo $?'
on plugins 'GOTRACEBACK=none ./hits-exec empty.log ./mean-exec exec/top.py; echo $?'

block static
place the-alternatives cmd/hits-static/main.go plugins
on plugins 'go build -o hits-static ./cmd/hits-static'
on plugins './hits-static -r mean < access.log'
on plugins './hits-static < access.log | head -3'
on plugins './hits-static -r xml < access.log; echo $?'

block bench
place choosing bench/bench_test.go plugins
on plugins 'go test -bench . -benchmem ./bench'

block sizes
on plugins 'stat -c "%s bytes  %n" hits-static hits-plugin csv.so mean.so hits-exec mean-exec'
on plugins 'readelf -d hits-static | grep -c NEEDED'

block image
on plugins 'podman run --rm --network=none -v "$PWD":/w -w /w gcr.io/distroless/static-debian12:nonroot ./hits-plugin access.log csv.so; echo $?'
on plugins 'readelf -l hits-plugin | grep interpreter'
on plugins 'podman run --rm -i --network=none -v "$PWD":/w -w /w gcr.io/distroless/static-debian12:nonroot ./hits-static -r mean < access.log'

block cleanup
quiet plugins 'rm -f hits-trim hits-race hits-nocgo csv-next.so csv-copy.so'
