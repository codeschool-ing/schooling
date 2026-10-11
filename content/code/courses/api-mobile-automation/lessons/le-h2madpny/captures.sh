#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Postman itself cannot run on
# this machine, so nothing here opens it: every transcript is jq or grep reading
# the two files the lesson shows whole, which ../../lab.sh writes from those
# very blocks. Nothing talks to boxoffice. What is STAGED rather than typed:
#   - in "broken", a copy of the environment file with the comma after its
#     first value removed, the way a hand edit that went wrong leaves it, in a
#     directory of its own; the path is printed as the student's.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with jq 1.7, as user ana. See
# ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 4 /home/ana/boxoffice
here /home/ana/boxoffice

C=postman/boxoffice.postman_collection.json
E=postman/lab.postman_environment.json

block valid
run "jq empty $E && echo valid JSON"

block valid-collection
run "jq empty $C && echo valid JSON"

block names
run "jq -r '.. | objects | select(has(\"request\")) | .name' $C"

block auth
run "jq -r '\"collection: \" + .auth.type, (.item[] | .name + \": \" + (.auth.type // \"inherit\"))' $C"

block collection-vars
run "jq -c '.variable[]' $C"

block used
run "grep -o '{{[A-Za-z]*}}' $C | sort | uniq -c"

block env
run "jq -r '.values[] | [.key, .type, .value] | @tsv' $E"

block broken
rm -rf /tmp/broken && mkdir -p /tmp/broken/postman
python3 - /home/ana/boxoffice/$E /tmp/broken/$E <<'PY'
import sys
lines = open(sys.argv[1]).read().split("\n")
for i, l in enumerate(lines):
    if '"baseUrl"' in l:
        lines[i] = l.rstrip(",")
        break
open(sys.argv[2], "w").write("\n".join(lines))
PY
chown -R ana /tmp/broken
prompt; echo "jq empty $E"
as_ana "cd /tmp/broken && jq empty $E" 2>&1 | strip
