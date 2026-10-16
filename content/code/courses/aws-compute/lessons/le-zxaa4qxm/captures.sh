#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of aws-compute (cold start), as a
# script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT
# COMMITTED.
#
#   bash lessons/le-zxaa4qxm/captures.sh              # snapstart, against moto
#   LAB_HOSTS=1 bash lessons/le-zxaa4qxm/captures.sh emulator
#
# `emulator` runs AWS's Lambda base image, public.ecr.aws/lambda/python:3.12,
# with the Runtime Interface Emulator inside it, so it needs Docker and the
# host's network. EVERY TIMING IN IT IS THE RECORDING LAPTOP'S (4 CPUs, shared
# with other work), and the lesson says so; none of them is AWS's.
#
# The handlers bare/app.py, eager/app.py and lazy/app.py are read out of the
# lesson's fences, and the shell function `cold` out of the example in
# `measuring-it`, so none of them is kept twice.
#
# What is STAGED rather than typed:
#   - the student writes the three handlers with an editor and pastes `cold`
#     into the terminal; here they are extracted and sourced without being
#     shown;
#   - the image was pulled once by the lab, through a mirror, and tagged with
#     the name the lesson pulls;
#   - in `bare`, a pause of two seconds after `docker run` while the emulator
#     starts (the function `cold` has its own, shown), and the container is
#     removed afterwards;
#   - in the default run, the role `fn-role` exists already (created quietly:
#     lesson 16 shows how), and so does fn.zip, the bare handler zipped.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

INVOKE=localhost:9000/2015-03-31/functions/function/invocations
IMAGE=public.ecr.aws/lambda/python:3.12

for d in bare eager lazy; do
  mkdir -p "$d"
done
from_lesson "$HERE/the-init-phase.md" bare/app.py > bare/app.py
from_lesson "$HERE/measuring-it.md" eager/app.py > eager/app.py
from_lesson "$HERE/measuring-it.md" lazy/app.py > lazy/app.py

if [ "${1:-}" = emulator ]; then
  quiet 'docker rm -f bare eager lazy'
  from_example "$HERE/measuring-it.md" cold.sh > cold.sh
  quiet '. ./cold.sh'
  quiet 'rm cold.sh'

  block bare
  run 'docker run -d --name bare -p 9000:8080 -v "$PWD/bare":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler'
  quiet 'sleep 2'
  run "curl -s -XPOST $INVOKE -d '{}'; echo"
  run "curl -s -XPOST $INVOKE -d '{}'; echo"
  run 'docker logs bare'
  quiet 'docker rm -f bare'

  block eager
  run 'cold eager'
  block lazy
  run 'cold lazy'

  block cpus
  run 'cold eager 1'
  run 'cold eager 0.5'
  run 'cold eager 0.25'

  block importtime
  run "docker run --rm --entrypoint python3 $IMAGE -X importtime -c 'import boto3' 2>&1 | sort -t'|' -k2 -n | tail -5"

  block sdk-size
  run "docker run --rm --entrypoint python3 $IMAGE -c 'import boto3; print(boto3.__version__)'"
  run "docker run --rm --entrypoint du $IMAGE -sh /var/lang/lib/python3.12/site-packages/boto3 /var/lang/lib/python3.12/site-packages/botocore"
  exit 0
fi

quiet "aws iam create-role --role-name fn-role --assume-role-policy-document '{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"lambda.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}'"
quiet 'zip -j fn.zip bare/app.py'

block snapstart
run 'aws lambda create-function --function-name snappy --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/fn-role --zip-file fileb://fn.zip --snap-start ApplyOn=PublishedVersions --query SnapStart'
run 'aws lambda publish-version --function-name snappy --query "{Version: Version, SnapStart: SnapStart}"'
