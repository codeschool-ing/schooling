#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. boxoffice is
# assembled from lessons 1 to 3 by ../../lab/project.py; the chi program is
# taken out of middle-path.md; the echo program is lesson 4's, from echo.md.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - the chi server is started in the background and stopped by the script;
#     what it printed is read from its log afterwards.
#   - fw/echo4 is lesson 4's Echo program with the one import line changed by
#     the sed the lesson shows.
# Timestamps and durations are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

block plumbing
project 3 boxoffice
quiet boxoffice 'go mod init example.com/boxoffice'
on boxoffice 'wc -l middleware.go recover.go cors.go auth.go json.go decode.go problem.go'
on boxoffice 'wc -l store.go events.go admin.go routes.go main.go'

block echo4
lab fresh fw/echo4
show ../le-q50yeb1v/echo.md '// fw/echo/main.go' fw/echo4/main.go
quiet fw/echo4 'go mod init example.com/fw/echo4'
on fw/echo4 'sed -i "s#labstack/echo/v5#labstack/echo/v4#g" main.go && grep echo/v4 main.go'
on fw/echo4 'go mod tidy'
on fw/echo4 'go build -o server .'

block chi
lab fresh fw/chi
show middle-path.md '// fw/chi/main.go' fw/chi/main.go
on fw/chi 'go mod init example.com/fw/chi'
on fw/chi 'go mod tidy'
on fw/chi 'go build -o server . && ls -l server && go list -m all'
serve fw/chi './server'
on fw/chi 'curl -s localhost:8080/events/1'
on fw/chi "curl -s --json '{\"quantity\": 40, \"email\": \"ana\"}' localhost:8080/events/1/tickets"
on fw/chi 'curl -si -X DELETE localhost:8080/events/1'
on fw/chi 'curl -si localhost:8080/nothing'
stop
on fw/chi 'cat .server.log'
