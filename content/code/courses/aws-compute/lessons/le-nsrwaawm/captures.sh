#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of aws-compute (concurrency), as a
# script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT
# COMMITTED.
#
#   bash lessons/le-nsrwaawm/captures.sh              # the moto blocks
#   LAB_HOSTS=1 bash lessons/le-nsrwaawm/captures.sh emulator
#
# The default run talks to an empty moto 5.2.3 only. `emulator` runs AWS's
# Lambda base image, public.ecr.aws/lambda/python:3.12, with the Runtime
# Interface Emulator inside it, so it needs Docker and the host's network
# (a port Docker publishes is not reachable from inside a network namespace).
#
# The handler slow/app.py is read out of the section `what-concurrency-is`,
# and provisioned.py out of the example in `provisioned`; prices.py out of
# lesson 1's `the-price-sheet`. None of them is kept twice.
#
# What is STAGED rather than typed:
#   - the student writes slow/app.py and provisioned.py with an editor; here
#     they are extracted from the lesson without being shown;
#   - the image was pulled once by the lab, through a mirror, and tagged with
#     the name the lesson pulls (`docker pull` of public.ecr.aws cannot be run
#     on the recording machine), so `docker image ls` shows it;
#   - a pause of two seconds after `docker run`, while the emulator starts, and
#     the container is removed at the end with `docker rm -f slow`;
#   - in the default run, slow/app.py exists because the first section made
#     it, and the price cache was filled by an earlier run of prices.py.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

INVOKE=localhost:9000/2015-03-31/functions/function/invocations

if [ "${1:-}" = emulator ]; then
  quiet 'docker rm -f slow'
  mkdir -p slow
  from_lesson "$HERE/what-concurrency-is.md" slow/app.py > slow/app.py
  block image
  run 'docker image ls public.ecr.aws/lambda/python'
  block one-environment
  run 'cd slow'
  run 'docker run -d --name slow -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler'
  quiet 'sleep 2'
  run "curl -s -w ' %{time_total} s\n' -XPOST $INVOKE -d '{}'"
  run "curl -s -w ' %{time_total} s\n' -XPOST $INVOKE -d '{}'"
  block two-at-once
  run "for n in 1 2; do curl -s -o /dev/null -w \"call \$n: HTTP %{http_code} after %{time_total} s\n\" -XPOST $INVOKE -d '{}' & done; wait"
  run 'docker logs slow 2>&1 | grep -E "REPORT|Reserve|panic"'
  quiet 'docker rm -f slow'
  exit 0
fi

mkdir -p slow
from_lesson "$HERE/what-concurrency-is.md" slow/app.py > slow/app.py
from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py
from_example "$HERE/provisioned.md" provisioned.py > provisioned.py

block account-settings
run 'aws lambda get-account-settings'

block function
run "aws iam create-role --role-name orders-role --query Role.Arn --output text --assume-role-policy-document '{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"lambda.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}'"
run 'zip -j orders.zip slow/app.py'
run 'aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --memory-size 1024 --role arn:aws:iam::123456789012:role/orders-role --zip-file fileb://orders.zip --query "{Name: FunctionName, Memory: MemorySize, State: State}"'

block reserve
run 'aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 100'
run 'aws lambda get-function --function-name orders --query Concurrency'

block too-much
run 'aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 2000'

block switch-off
run 'aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 0'
run 'aws lambda delete-function-concurrency --function-name orders'
run 'aws lambda get-function-concurrency --function-name orders'

block version-alias
run 'aws lambda publish-version --function-name orders --query "{Version: Version, Arn: FunctionArn}"'
run 'aws lambda create-alias --function-name orders --name live --function-version 1 --query "{Alias: Name, Version: FunctionVersion}"'

block provision
run 'aws lambda put-provisioned-concurrency-config --function-name orders --qualifier live --provisioned-concurrent-executions 10'

block sheet
run 'python3 prices.py lambda'

block compare
run 'python3 provisioned.py'
