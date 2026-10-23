#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program it runs is taken
# out of the lesson's own .md by ../../lab/fence.py, so the file a student
# copies is the file that ran.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1, ana, PostgreSQL
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - each server is started in the background by the script and stopped by
#     it; the lesson has the student start it in one terminal and type curl in
#     a second one. What the server printed is read from its log afterwards.
#   - `go mod init` for the small programs of sections 03 to 08, which section
#     03 shows once.
# Timestamps in the logs are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

block machine
lab fresh boxoffice
on boxoffice 'go version'
on boxoffice 'go env GOROOT GOPATH GOTOOLCHAIN'
on boxoffice 'curl --version | head -1'
on boxoffice 'go mod init example.com/boxoffice'
on boxoffice 'cat go.mod'

block first-server
lab fresh hello
show first-server.md '// hello/main.go' hello/main.go
on hello 'go mod init example.com/hello'
serve hello 'go run .'
on hello 'curl -s localhost:8080/'
on hello 'curl -s localhost:8080/events/7'
on hello 'curl -s -X POST localhost:8080/anything'
on hello 'curl -si localhost:8080/'
on hello 'go run .'
stop

block handlers
lab fresh counter
show handlers.md counter/main.go counter/main.go
quiet counter 'go mod init example.com/counter'
serve counter 'go run .'
on counter 'curl -s localhost:8080/visits; curl -s localhost:8080/visits; curl -s localhost:8080/visits'
on counter 'curl -s localhost:8080/hello; curl -s localhost:8080/hi'
on counter 'curl -si localhost:8080/nothing'
stop

block patterns
lab fresh routes
show patterns.md '// routes/main.go' routes/main.go
quiet routes 'go mod init example.com/routes'
serve routes 'go run .'
on routes 'curl -s localhost:8080/'
on routes 'curl -si localhost:8080/about'
on routes 'curl -s localhost:8080/events'
on routes 'curl -s -X POST localhost:8080/events'
on routes 'curl -si -X DELETE localhost:8080/events'
on routes 'curl -s localhost:8080/events/42'
on routes 'curl -s localhost:8080/events/latest'
on routes 'curl -s localhost:8080/files/posters/2026/jazz.png'
on routes 'curl -sI localhost:8080/events'
on routes 'curl -si localhost:8080/static'
on routes 'curl -s localhost:8080/static/css/site.css'
on routes 'curl -s localhost:8080/events/42/tickets'
stop

block precedence
lab fresh conflict
show precedence.md '// conflict/main.go' conflict/main.go
quiet conflict 'go mod init example.com/conflict'
on conflict 'go run .'

block the-response
lab fresh reply
show the-response.md '// reply/main.go' reply/main.go
quiet reply 'go mod init example.com/reply'
serve reply 'go run .'
on reply 'curl -si localhost:8080/created'
on reply 'curl -si localhost:8080/late'
on reply 'curl -si localhost:8080/sniffed'
on reply 'curl -si localhost:8080/declared'
on reply 'curl -si localhost:8080/missing'
stop
on reply 'cat .server.log'

block no-timeout
serve hello 'go run .'
on hello 'exec 3<>/dev/tcp/localhost/8080; printf "GET / HTTP/1.1\r\nHost: localhost\r\n" >&3; timeout 5 cat <&3; echo "exit $?"'
stop

block timeout
lab fresh patient
show the-server.md '// patient/main.go' patient/main.go
quiet patient 'go mod init example.com/patient'
serve patient 'go run .'
on patient 'start=$SECONDS; exec 3<>/dev/tcp/localhost/8080; printf "GET / HTTP/1.1\r\nHost: localhost\r\n" >&3; timeout 5 cat <&3; echo "exit $? after $((SECONDS-start)) s"'
stop

block boxoffice
project 1 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
on boxoffice 'ls'
on boxoffice 'go vet ./...'
serve boxoffice 'go run .'
on boxoffice 'curl -s localhost:8080/events'
on boxoffice 'curl -s localhost:8080/events/2'
on boxoffice 'curl -si localhost:8080/events/9'
on boxoffice 'curl -si localhost:8080/events/nine'
on boxoffice 'curl -si -X POST localhost:8080/events'
stop
on boxoffice 'cat .server.log'
