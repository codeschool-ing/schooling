#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice is
# assembled from lessons 1 to 3 by ../../lab/project.py, and catchall is taken
# out of problem-details.md, so the files are the ones printed.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the server is started in the background with two tokens from
#     `openssl rand -hex 16`, as lesson 2 section 06 has the student do, and
#     stopped by the script; what it printed is read from its log.
#   - the transcripts of sections 02 to 06 come from boxoffice as section 07
#     leaves it, because each one prints the same without the files after it.
#   - `go mod init` for catchall.
# Timestamps, durations and tokens are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

project 3 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
MGR=$(openssl rand -hex 16); DOOR=$(openssl rand -hex 16)
block files
on boxoffice 'ls'
on boxoffice 'go vet ./...'
serve boxoffice "env BOXOFFICE_MANAGER_TOKEN=$MGR BOXOFFICE_DOOR_TOKEN=$DOOR go run ."

block encoding
on boxoffice 'curl -s localhost:8080/events'
on boxoffice 'curl -si localhost:8080/events/1'

block decoding
on boxoffice 'curl -s -X POST localhost:8080/events/1/tickets'
on boxoffice "curl -s --json '{\"quantity\": 2,}' localhost:8080/events/1/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2' localhost:8080/events/1/tickets"
on boxoffice "curl -s --json '{\"quantity\": \"two\"}' localhost:8080/events/1/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2, \"seat\": \"A1\"}' localhost:8080/events/1/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2}{\"quantity\": 9}' localhost:8080/events/1/tickets"
on boxoffice "python3 -c 'print(\"{\\\"email\\\": \\\"\" + \"a\" * 2000000 + \"\\\"}\")' | curl -s --json @- localhost:8080/events/1/tickets"

block validation
on boxoffice "curl -s --json '{}' localhost:8080/events/1/tickets"
on boxoffice "curl -s --json '{\"quantity\": 40, \"email\": \"ana\"}' localhost:8080/events/1/tickets"
on boxoffice "curl -si --json '{\"quantity\": 0, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets"

block domain
on boxoffice "curl -si --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/2/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/9/tickets"
on boxoffice "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/nine/tickets"
on boxoffice 'curl -s localhost:8080/events/1'

block admin
on boxoffice "curl -si --json '{\"name\": \"Organ Recital\", \"seats\": 60}' localhost:8080/admin/events"
printf 'ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_DOOR_TOKEN" --json %s localhost:8080/admin/events\n' "'{\"name\": \"Organ Recital\", \"seats\": 60}'"
lab exec boxoffice "curl -s -H 'Authorization: Bearer $DOOR' --json '{\"name\": \"Organ Recital\", \"seats\": 60}' localhost:8080/admin/events" 2>&1
printf 'ana@vm:~/boxoffice$ curl -si -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json %s localhost:8080/admin/events\n' "'{\"name\": \"Organ Recital\", \"seats\": 60}'"
lab exec boxoffice "curl -si -H 'Authorization: Bearer $MGR' --json '{\"name\": \"Organ Recital\", \"seats\": 60}' localhost:8080/admin/events" 2>&1
printf 'ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" --json %s localhost:8080/admin/events\n' "'{\"name\": \"\", \"seats\": 0}'"
lab exec boxoffice "curl -s -H 'Authorization: Bearer $MGR' --json '{\"name\": \"\", \"seats\": 0}' localhost:8080/admin/events" 2>&1
printf 'ana@vm:~/boxoffice$ curl -s -H "Authorization: Bearer $BOXOFFICE_MANAGER_TOKEN" localhost:8080/admin/report\n'
lab exec boxoffice "curl -s -H 'Authorization: Bearer $MGR' localhost:8080/admin/report" 2>&1
on boxoffice 'curl -si -X DELETE localhost:8080/events'
stop
on boxoffice 'cat .server.log'

block catchall
lab fresh catchall
show problem-details.md '// catchall/main.go' catchall/main.go
quiet catchall 'go mod init example.com/catchall'
serve catchall 'go run .'
on catchall 'curl -s localhost:8080/events'
on catchall 'curl -si localhost:8080/nothing'
on catchall 'curl -si -X DELETE localhost:8080/events'
stop
