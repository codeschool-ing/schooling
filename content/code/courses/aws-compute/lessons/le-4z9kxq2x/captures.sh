#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of aws-compute (Lambda: handler,
# runtimes, layers and the package), as a script that produces them.
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-4z9kxq2x/captures.sh                     # moto's Lambda
#   LAB_HOSTS=1 bash lessons/le-4z9kxq2x/captures.sh emulator  # the real runtime
#
# Two different things answer here, and the lesson says which each time:
#   - moto 5.2.3 keeps the functions, versions and layers the API creates. Its
#     `invoke` tries to run the code in a community image pulled from Docker
#     Hub, which this machine cannot pull, and the transcript shows that;
#   - `emulator` runs the handlers in public.ecr.aws/lambda/python:3.12, AWS's
#     own Lambda base image with the Runtime Interface Emulator inside, through
#     Docker on this machine's own network. The timings it prints are this
#     laptop's, not Lambda's.
#
# What is STAGED rather than typed:
#   - the base image was on this machine before the run, pulled through a
#     mirror and tagged with the name the lesson uses; the student pulls it
#     with the command the lesson shows;
#   - a pause of two seconds after each `docker run -d`, while the emulator
#     starts, where the student is simply slower than a script;
#   - `emulator` also prints the Lambda block of prices.py, read out of lesson
#     1's example, through the recording machine's proxy (HTTPS_PROXY), as
#     lesson 1's own captures do;
#   - after each `docker stop`, a wait until Docker has removed the container,
#     so the next `docker run` can reuse its name;
#   - the edit to app.py in `update` is made with sed, and shown.
#
# Request ids, container ids, hashes and dates differ on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04, Docker 29, no AWS account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

INVOKE='curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations'

mkdir -p greet shop layer/python
from_example "$HERE/the-handler.md" app.py > greet/app.py
from_lesson "$HERE/layers.md" shop.py > shop/shop.py
from_lesson "$HERE/layers.md" python/shopfmt.py > layer/python/shopfmt.py

if [ "${1:-}" = emulator ]; then
  quiet 'docker rm -f greet shop >/dev/null 2>&1'
  block image
  run 'docker image ls public.ecr.aws/lambda/python'
  run "docker image inspect public.ecr.aws/lambda/python:3.12 --format '{{.Os}}/{{.Architecture}}'"

  block run
  cd greet || exit 1
  run 'docker run --rm -d --name greet -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler'
  quiet 'sleep 2'
  run "$INVOKE -d '{\"name\": \"ana\"}'; echo"
  run "$INVOKE -d '{}'; echo"
  run "$INVOKE -d '{\"fail\": true}'; echo"
  block logs
  run 'docker logs greet 2>&1 | cut -c1-175'
  block stop
  run 'docker stop greet'
  quiet 'while docker inspect greet >/dev/null 2>&1; do sleep 0.2; done'
  cd .. || exit 1

  block no-layer
  run 'ls -R shop layer'
  run 'docker run --rm -d --name shop -p 9000:8080 -v "$PWD/shop":/var/task:ro public.ecr.aws/lambda/python:3.12 shop.handler'
  quiet 'sleep 2'
  run "$INVOKE -d '{\"cents\": 129990}'; echo"
  run 'docker stop shop'
  quiet 'while docker inspect shop >/dev/null 2>&1; do sleep 0.2; done'
  block with-layer
  run 'docker run --rm -d --name shop -p 9000:8080 -v "$PWD/shop":/var/task:ro -v "$PWD/layer":/opt:ro public.ecr.aws/lambda/python:3.12 shop.handler'
  quiet 'sleep 2'
  run "$INVOKE -d '{\"cents\": 129990}'; echo"
  run 'docker exec shop ls -R /opt'
  run 'docker stop shop'
  quiet 'while docker inspect shop >/dev/null 2>&1; do sleep 0.2; done'

  block prices
  export HTTPS_PROXY=$LAB_PROXY
  from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py
  run 'python3 prices.py lambda'
  exit 0
fi

block package
cd greet || exit 1
run 'zip function.zip app.py'
run 'unzip -l function.zip'
run 'aws lambda create-function --function-name greet --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://function.zip'
block role
run "aws iam create-role --role-name greet-role --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}' --query Role.Arn"
run 'aws lambda create-function --function-name greet --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://function.zip --query "{State:State,CodeSize:CodeSize,MemorySize:MemorySize,Timeout:Timeout,Architectures:Architectures,EphemeralStorage:EphemeralStorage}"'
block get
run 'aws lambda get-function --function-name greet --query "Code"'
block update
run "sed -i \"s/'hello, /'olá, /\" app.py"
run 'zip -q function.zip app.py'
run 'aws lambda update-function-code --function-name greet --zip-file fileb://function.zip --query "[CodeSize,CodeSha256,Version]"'
run 'aws lambda publish-version --function-name greet --query "[Version,CodeSha256]"'
block invoke
run "aws lambda invoke --function-name greet --cli-binary-format raw-in-base64-out --payload '{\"name\": \"ana\"}' out.json"
run 'cut -c1-150 out.json; echo'
block big
run 'head -c 60000000 /dev/urandom > blob.bin'
run "zip -q big.zip app.py blob.bin && stat -c '%s bytes' big.zip"
run 'aws lambda create-function --function-name big --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://big.zip --query CodeSize'
cd .. || exit 1

block layer
run 'cd layer && zip -r ../shopfmt.zip python && cd ..'
run 'aws lambda publish-layer-version --layer-name shopfmt --zip-file fileb://shopfmt.zip --compatible-runtimes python3.12 --compatible-architectures x86_64 arm64 --query "[LayerVersionArn,Version]"'
run 'cd shop && zip -q ../shop.zip shop.py && cd ..'
run 'aws lambda create-function --function-name shop --runtime python3.12 --handler shop.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://shop.zip --layers arn:aws:lambda:sa-east-1:123456789012:layer:shopfmt:1 --query "Layers"'

block runtimes
run 'aws lambda create-function --function-name old --runtime python2.7 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query Runtime'
run 'aws lambda create-function --function-name typo --runtime python3.99 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query Runtime'
block arm
run 'aws lambda create-function --function-name greet-arm --runtime python3.12 --architectures arm64 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query "[FunctionName,Architectures[0]]"'
