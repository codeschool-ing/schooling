#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Section `the-lab` installs
# curl, jq and Node 22.22.0 the way this machine had them installed; section
# `boxoffice` shows boxoffice.mjs whole, and ../../lab.sh writes the project
# from that very block before anything runs. What is STAGED rather than typed:
#   - the server, started in the background where the lesson starts it in a
#     second terminal; its first line, the one the lesson shows under
#     `node boxoffice.mjs`, is read from its log;
#   - in "fail-port", a first server left running, and the second start
#     printed as the student's second terminal shows it;
#   - in "fail-paste", a copy of boxoffice.mjs with its last line removed, the
#     way a paste that stopped early leaves it, in a directory of its own;
#   - in "fail-path", an interactive shell whose PATH has no /opt/node/bin, as
#     a terminal opened before ~/.bashrc was changed has; bash's two lines
#     about job control, which only a shell with no terminal prints, are cut.
# The Date header is the moment of the recording and differs on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, curl 8.5.0, jq 1.7.1,
# TZ=America/Sao_Paulo, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 1 /home/ana/boxoffice
here /home/ana

block setup-tools
run 'node --version'
run 'npm --version'
run 'curl --version | head -1'
run 'jq --version'

go boxoffice
block start
prompt; echo 'node boxoffice.mjs'
serve api 'node boxoffice.mjs'
head -1 /tmp/lab-api.log

block health
run 'curl localhost:8080/health'

block shows
run 'curl -s localhost:8080/v1/shows | jq'

block verbose
run 'curl -v localhost:8080/v1/shows/sh-103'

block timing
run "curl -s -o /dev/null -w '%{time_total}\\n' localhost:8080/v1/shows/sh-103"

block get-and-delete
run 'curl -i -X DELETE localhost:8080/v1/shows/sh-103'

block head
run 'curl -I localhost:8080/v1/shows/sh-103'

block token
run "TOKEN=\$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)"
LAB_EXTRA="TOKEN=$(as_ana "curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token")"

block codes
w="-s -o /dev/null -w '%{http_code}\\n'"
run "curl $w localhost:8080/v1/shows"
run "curl $w localhost:8080/v1/shows/sh-999"
run "curl $w localhost:8080/v1/orders"
run "curl $w -X PUT localhost:8080/v1/shows"

block create
run "curl -si localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" -H 'content-type: application/json' -d '{\"show_id\":\"sh-103\",\"seats\":3}'"

block client-errors
for body in '{"show_id":"sh-103","seats":2}' '{"show_id":"sh-103","seats":0}' '{"show_id":"sh-103"'; do
  run "curl -s localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" -H 'content-type: application/json' -d '$body'"
done
run "curl -s localhost:8080/v1/orders -H \"authorization: Bearer \$TOKEN\" -d 'show_id=sh-103&seats=2'"

block etag
run 'curl -si localhost:8080/v1/shows/sh-101 | grep -i etag'
ETAG=$(as_ana "curl -si localhost:8080/v1/shows/sh-101" | grep -i '^etag' | cut -d' ' -f2 | tr -d '\r')
run "curl -si localhost:8080/v1/shows/sh-101 -H 'if-none-match: $ETAG'"

block log
prompt; echo 'node boxoffice.mjs'
cat /tmp/lab-api.log

block fail-port
prompt; echo 'node boxoffice.mjs'
as_ana 'node boxoffice.mjs' 2>&1 | strip | sed "s#$LAB_HOME#/home/ana#g"
halt api

block fail-refused
prompt; echo 'curl localhost:8080/health'
as_ana "script -qec 'curl localhost:8080/health' /dev/null; echo \$? > /tmp/lab-rc" | strip
prompt; echo 'echo $?'; cat /tmp/lab-rc

block fail-paste
rm -rf /tmp/paste && mkdir -p /tmp/paste && head -n -1 /home/ana/boxoffice/boxoffice.mjs > /tmp/paste/boxoffice.mjs && chown -R ana /tmp/paste
prompt; echo 'node boxoffice.mjs'
as_ana 'cd /tmp/paste && node boxoffice.mjs' 2>&1 | strip | sed 's#/tmp/paste#/home/ana/boxoffice#g'

block fail-path
prompt; echo 'node --version'
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin bash -ic 'node --version' 2>&1 | tail -1
