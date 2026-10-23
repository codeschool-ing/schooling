#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of go-back, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. The five programs
# are taken out of the lesson's .md files, so each is the one printed.
#
#   sudo bash ../../lab.sh setup      # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed:
#   - each server is started in the background and stopped by the script; the
#     lesson has the student run it in one terminal and curl from another. What
#     it printed is read from its log afterwards.
#   - the module cache already held every framework from a trial run of the
#     same programs, so `go mod tidy` finds them without printing a download.
#   - `cat -v` shows the server's log, so that the colour codes beego writes
#     appear as ^[ rather than as raw escape bytes.
# Timestamps, durations and sizes are whatever the run printed.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

probe() {
  local d=$1
  on "$d" 'curl -si localhost:8080/events/1'
  on "$d" "curl -s --json '{\"quantity\": 2, \"email\": \"ana@example.com\"}' localhost:8080/events/1/tickets"
  on "$d" "curl -s --json '{\"quantity\": 40, \"email\": \"ana\"}' localhost:8080/events/1/tickets"
  on "$d" "curl -s --json '{\"quantity\": \"two\"}' localhost:8080/events/1/tickets"
  if [ "$d" = fw/beego ]; then
    on "$d" 'curl -si -X DELETE localhost:8080/events/1 | head -5'
    on "$d" 'curl -s localhost:8080/nothing | grep -i -e title -e powered'
  else
    on "$d" 'curl -si -X DELETE localhost:8080/events/1'
    on "$d" 'curl -si localhost:8080/nothing'
  fi
}

for fw in std gin echo fiber beego; do
  case $fw in std) md=why-routers.md ;; *) md=$fw.md ;; esac
  lab fresh fw/$fw
  show "$md" "// fw/$fw/main.go" "fw/$fw/main.go"
  block "$fw-setup"
  on fw/$fw "go mod init example.com/fw/$fw"
  on fw/$fw 'go mod tidy'
  on fw/$fw 'go build -o server . && ls -l server'
  serve fw/$fw './server'
  block "$fw-probe"
  probe fw/$fw
  stop
  block "$fw-log"
  on fw/$fw 'cat -v .server.log'
done

block numbers
for fw in std gin echo fiber beego; do
  on fw/$fw 'grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5'
done
on fw 'du -sh ~/go/pkg/mod/github.com/{gin-gonic,labstack,gofiber,beego}'
