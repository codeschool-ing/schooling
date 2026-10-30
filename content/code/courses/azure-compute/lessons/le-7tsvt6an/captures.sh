#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of azure-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-7tsvt6an/captures.sh
#
# The environment the transcripts run in is the one the section `your-lab`
# builds: lab.sh runs that section's own install fence, and every run starts
# with the lines of its third fence, the ones a student types in every new
# terminal.
#
# What is STAGED rather than typed:
#   - `no-path` runs one command with the terminal lines left out, as a new
#     terminal would be, by starting a shell with an empty environment;
#   - `docker` is the Docker daemon the `docker` course installed, already
#     running on this machine.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

block check
run 'az version'
run 'bicep --version'
run 'docker --version'

block login
run 'az account show'
run 'az vm list-skus --size Standard_D2 --output table'

block no-path
run 'env -i HOME=$HOME bash --norc -c "az version"'

block docker-down
run 'DOCKER_HOST=unix:///run/nothing.sock docker info 2>&1 | tail -n 1'

block defaults
run 'az vm create --help | tr -s "[:space:]" " " | grep -o "Default: Standard_[A-Za-z0-9_]*"'
run 'echo $AZURE_DEFAULTS_LOCATION'

block compiler
from_lesson "$HERE/what-answers.md" check.bicep > check.bicep
run 'cat check.bicep'
run 'bicep build check.bicep'
run 'ls'
run 'jq ".resources[0] | {type, apiVersion, name}" check.json'
