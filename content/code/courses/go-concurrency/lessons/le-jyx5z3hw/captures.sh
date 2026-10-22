#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of go-concurrency, as a script that
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
# the student reads. What is STAGED rather than typed: those Go files, written
# into ~/embedding/version, ~/embedding/noimport, ~/embedding/site and
# ~/embedding/serve, and a `go mod init` in ~/embedding. The small data files
# are typed in the transcripts, with printf, except the copy of version.txt that
# "noimport" embeds. In "serve" the server is started
# in the background with setsid, listening on 127.0.0.1:8024 only, and killed
# by its pid at the end; the transcript shows the curl requests made to it. The
# sizes in `ls -l` and the dates beside them are those of one run.
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

lab fresh embedding
show single-file.md embedding version/main.go
show single-file.md embedding noimport/main.go
show embed-fs.md embedding site/main.go
show serving.md embedding serve/main.go
quiet embedding 'go mod init example.com/embedding'

block version
on embedding 'printf "1.4.2\n" > version/version.txt'
on embedding 'go build -o bin/version ./version'
on embedding 'printf "[ go ]\n" > version/logo.txt'
on embedding 'go build -o bin/version ./version'
on embedding 'bin/version'
on embedding 'printf "1.5.0\n" > version/version.txt'
on embedding 'bin/version'
on embedding 'go build -o bin/version ./version'
on embedding 'bin/version'

block noimport
quiet embedding 'cp version/version.txt noimport/'
on embedding 'go build -o bin/noimport ./noimport'

block site
on embedding 'mkdir site/static'
on embedding 'printf "<h1>Orders</h1>\n" > site/static/index.html'
on embedding 'printf "h1 { color: teal }\n" > site/static/style.css'
on embedding 'printf "draft\n" > site/static/.draft.html'
on embedding 'printf "notes\n" > site/static/_notes.txt'
on embedding 'go run ./site'

block serve
on embedding 'cp -r site/static serve/'
on embedding 'go build -o bin/serve ./serve'
on embedding 'ls -l bin/serve'
lab exec embedding '{ setsid bin/serve </dev/null >/dev/null 2>&1 & echo $! > serve.pid; }'
PID=$(lab exec embedding 'cat serve.pid')
sleep 1
on embedding 'curl -s http://127.0.0.1:8024/'
on embedding 'curl -s -o /dev/null -w "%{http_code} %{content_type}\n" http://127.0.0.1:8024/style.css'
on embedding 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8024/_notes.txt'
on embedding 'rm -r serve/static'
on embedding 'curl -s http://127.0.0.1:8024/'
kill "$PID"
