#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. The collection, the
# environment, the data file and the brittle collection are shown whole, and
# ../../lab.sh writes them from those very blocks. Postman cannot run on this
# machine, so the scripts run in Newman, fetched with npx from
# registry.npmjs.org, which runs the same scripts. What is STAGED rather than
# typed:
#   - ana's npx cache is emptied first, so the first npx run downloads Newman
#     the way it does on a machine that never ran it;
#   - boxoffice, started in the background where the lesson has it running in
#     a second terminal, and restarted before "brittle-1" where the lesson tells
#     the student to restart it;
#   - in "trap", the environment file as lesson 4 left it (with its empty
#     `token`), written from lesson 4's own block, because the lesson runs the
#     new collection against it before replacing it.
# The times in milliseconds differ on every run.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4 and
# Newman 6.2.3, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 5 /home/ana/boxoffice
rm -rf /home/ana/.npm/_npx
here /home/ana/boxoffice
serve api 'node boxoffice.mjs'

C=postman/boxoffice.postman_collection.json
E=postman/lab.postman_environment.json
NM='npx --yes newman@6.2.3'

block version
run "$NM --version"

block trap
lab_files 4 /tmp/lab4 && cp /tmp/lab4/$E /tmp/lab-env5.json && rm -rf /tmp/lab4
cp /home/ana/boxoffice/$E /tmp/lab-env5-new.json
cp /tmp/lab-env5.json /home/ana/boxoffice/$E && chown ana /home/ana/boxoffice/$E
run "$NM run $C -e $E --folder orders --disable-unicode"
cp /tmp/lab-env5-new.json /home/ana/boxoffice/$E && chown ana /home/ana/boxoffice/$E

block token-in-env
run "jq -r '.values[].key' $E"

block run
run "$NM run $C -e $E --disable-unicode"

block data
run "$NM run $C -e $E --folder 'seat rules' -d postman/seats.csv --disable-unicode"

halt api
serve api 'node boxoffice.mjs'

block brittle-1
run "$NM run postman/brittle.postman_collection.json -e $E --disable-unicode"

block brittle-2
run "$NM run postman/brittle.postman_collection.json -e $E --disable-unicode"
halt api
