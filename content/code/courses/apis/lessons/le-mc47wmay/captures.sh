#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, with every package of
# lesson 1's "The packages" already installed; db.py and rest.py, copied out of
# lesson 1's "The shelf" by `shown`; openapi.yaml and check_contract.py, copied
# out of this lesson's own sections the same way rather than pasted into nano.
# This machine keeps the computer's network, because the section on validating
# the spec downloads one package with pip; the computer it was recorded on
# reaches PyPI through a proxy, which pip is pointed at by the environment and
# which appears nowhere in the transcripts. The server runs in the background,
# where the lesson has the student run it in a second terminal. The versions
# pip resolves for the validator's dependencies, the ids the contract test
# creates and the server's log times differ between runs.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l06 net

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/shelfs-spec.md" "$HERE_DIR/contract-test.md"
at '~/shelf'

block data
run "python3 -c 'import json, sys, yaml; json.dump(yaml.safe_load(sys.stdin), sys.stdout)' < openapi.yaml | jq -c 'keys'"
run "python3 -c 'import json, sys, yaml; json.dump(yaml.safe_load(sys.stdin), sys.stdout)' < openapi.yaml | jq -r '.paths | to_entries[] | .key as \$p | .value | keys_unsorted[] | select(. != \"parameters\") | ascii_upcase + \" \" + \$p'"

block venv
run 'pip install openapi-spec-validator==0.9.0'
run 'python3 -m venv ~/shelf/.venv'
run '.venv/bin/pip install openapi-spec-validator==0.9.0 | tail -1'
run '.venv/bin/openapi-spec-validator openapi.yaml'

block broken
run "sed 's|^  /authors/{id}:|  /authors/{author}:|' openapi.yaml > broken.yaml"
run 'diff openapi.yaml broken.yaml'
run '.venv/bin/openapi-spec-validator broken.yaml; echo "exit $?"'
run '.venv/bin/openapi-spec-validator --validation-errors all broken.yaml'

block twopy
run ".venv/bin/python -c 'import jsonschema; print(jsonschema.__file__)'"
run "python3 -c 'import jsonschema; print(jsonschema.__file__)'"

serve 'python3 rest.py'
block contract
run 'python3 check_contract.py; echo "exit $?"'
run "curl -s localhost:8000/v1/books | jq length"

block next
run "sed 's/price_cents/price/' openapi.yaml > next.yaml"
run 'diff openapi.yaml next.yaml'
run '.venv/bin/openapi-spec-validator next.yaml'

block log
log
