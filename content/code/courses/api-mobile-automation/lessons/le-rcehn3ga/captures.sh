#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of api-mobile-automation, as the
# script that produces them. Every transcript in the lesson was copied from its
# output, where each block starts with a line `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. package.json, .gitignore,
# ci-local.sh and the workflow are shown whole, and ../../lab.sh writes them
# from those very blocks; Newman comes from registry.npmjs.org. The GitHub
# Actions workflow is NOT run here: GitHub is not reachable from this machine
# as a runner, and the lesson says so. What is STAGED rather than typed:
#   - the project's package.json is removed before "init", so npm init starts
#     from nothing as it does for the student, and the lesson's package.json is
#     put back after "install": that is the edit the student makes by hand;
#   - `git init -q`, which the student ran in lesson 3;
#   - boxoffice, started in the background where the lesson has it running in
#     a second terminal, and stopped before "local-ci", which starts its own.
# Times in milliseconds, and the audit's counts, change from run to run.
#
# Recorded 2026-10-11 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4 and
# Newman 6.2.3, as user ana. See ../../lab.sh for the rest.

source "$(dirname "$0")/../../lab.sh"
project 6 /home/ana/boxoffice
here /home/ana/boxoffice
cp /home/ana/boxoffice/package.json /tmp/lab-package6.json
rm -f /home/ana/boxoffice/package.json
quiet 'git init -q'

block init
run 'npm init -y'

block install
run 'npm install --save-dev --save-exact newman@6.2.3'

block audit
run "npm audit | grep -m1 'Will install'"

cp /tmp/lab-package6.json /home/ana/boxoffice/package.json && chown ana /home/ana/boxoffice/package.json

block version
run 'npx newman --version'

serve api 'node boxoffice.mjs'

block run
run 'npm run test:api'

block exit
run 'npm run test:api > /dev/null; echo "exit code $?"'
run 'npm run test:api -- --folder orders > /dev/null; echo "exit code $?"'

block bail
run 'npm run test:api -- --bail --reporters json --reporter-json-export results/bail.json > /dev/null; echo "exit code $?"'
run "jq -r '.run.executions[].item.name' results/bail.json"

block reporters
run 'npm run test:api -- --reporters cli,junit,json --reporter-junit-export results/newman.xml --reporter-json-export results/newman.json > /dev/null'
run 'ls results'

block junit
run "grep -c '<testcase' results/newman.xml"
run "grep -B1 -A2 '<failure' results/newman.xml"

block json
run "jq '.run.stats.assertions' results/newman.json"
run "jq -r '.run.failures[] | .source.name + \": \" + .error.message' results/newman.json"

block status
run 'git status --short'

halt api

block local-ci
run 'bash ci-local.sh; echo "exit code $?"'
