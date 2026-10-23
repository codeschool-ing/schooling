#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every program it
# runs is taken out of the lesson's own .md, and boxoffice is assembled from
# lessons 1 and 2 by ../../lab/project.py, so the files are the ones printed.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - each server is started in the background and stopped by the script; the
#     lesson has the student run it in one terminal and curl from another. What
#     a server printed is read from its log afterwards.
#   - `go mod init` for wrap, fragile and sturdy, which lesson 1 shows once.
#   - the transcripts of sections 03 to 06 come from boxoffice as section 07
#     leaves it, all four middlewares in place, because each section's output
#     is the same with or without the ones after it.
#   - the two tokens are printed by `openssl rand -hex 16` in the run, so they
#     differ every time; the script keeps them in variables for the curls.
# Timestamps and durations are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

block the-shape
lab fresh wrap
show the-shape.md '// wrap/main.go' wrap/main.go
quiet wrap 'go mod init example.com/wrap'
serve wrap 'go run .'
on wrap 'curl -s localhost:8080/hello'
on wrap 'curl -s localhost:8080/nothing'
stop
on wrap 'cat .server.log'

block fragile
lab fresh fragile
show recovery.md '// fragile/main.go' fragile/main.go
quiet fragile 'go mod init example.com/fragile'
serve fragile 'go run .'
on fragile 'curl -si localhost:8080/boom; echo "exit $?"'
stop
on fragile 'cat .server.log'

block sturdy
lab fresh sturdy
show recovery.md '// sturdy/main.go' sturdy/main.go
quiet sturdy 'go mod init example.com/sturdy'
serve sturdy 'go run .'
on sturdy 'curl -si localhost:8080/boom'
stop
on sturdy 'head -6 .server.log'

block boxoffice
project 2 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
on boxoffice 'ls'
on boxoffice 'go vet ./...'
on boxoffice 'go run .'
MGR=$(openssl rand -hex 16); DOOR=$(openssl rand -hex 16)
printf 'ana@vm:~/boxoffice$ export BOXOFFICE_MANAGER_TOKEN=$(openssl rand -hex 16)\n'
printf 'ana@vm:~/boxoffice$ export BOXOFFICE_DOOR_TOKEN=$(openssl rand -hex 16)\n'
printf 'ana@vm:~/boxoffice$ echo $BOXOFFICE_MANAGER_TOKEN $BOXOFFICE_DOOR_TOKEN\n%s %s\n' "$MGR" "$DOOR"
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR BOXOFFICE_DOOR_TOKEN=$DOOR go run ."

block logging
on boxoffice 'curl -s localhost:8080/events'
on boxoffice 'curl -s localhost:8080/events/9'
on boxoffice 'curl -s -X POST localhost:8080/events'

block cors
on boxoffice "curl -si -H 'Origin: https://tickets.example.com' localhost:8080/events/1"
on boxoffice "curl -si -H 'Origin: https://elsewhere.example.net' localhost:8080/events/1"
on boxoffice "curl -si -X OPTIONS -H 'Origin: https://tickets.example.com' -H 'Access-Control-Request-Method: GET' -H 'Access-Control-Request-Headers: authorization' localhost:8080/admin/report"

block auth
on boxoffice 'curl -si localhost:8080/admin/report'
on boxoffice "curl -s -H 'Authorization: Bearer 0123456789abcdef' localhost:8080/admin/report"
printf 'ana@vm:~/boxoffice$ curl -si -H "Authorization: Bearer $BOXOFFICE_DOOR_TOKEN" localhost:8080/admin/report\n'
lab exec boxoffice "curl -si -H 'Authorization: Bearer $DOOR' localhost:8080/admin/report" 2>&1
printf 'ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" localhost:8080/admin/report\n'
lab exec boxoffice "curl -s -H 'Authorization: Bearer $MGR' localhost:8080/admin/report" 2>&1
stop
on boxoffice 'cat .server.log'
