#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of aws-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-nzr57ay5/captures.sh
#   LAB_HOSTS=1 bash lessons/le-nzr57ay5/captures.sh prices
#
# `prices` reads prices.py out of the example in lesson 1's section
# `the-price-sheet` and compare.py out of the example in this lesson's section
# `the-cost-model`, so the programs run are the ones the student copies. The
# prices are the sheet's, at the offer versions pinned in prices.py (16 October
# 2026); prices.py reads its cached files and downloads one only when the cache
# lacks it, through the recording machine's proxy (HTTPS_PROXY), as lesson 1's
# `prices` does. Every number compare.py prints is arithmetic on that sheet and
# on the assumptions written at the top of compare.py.
#
# The default block runs against moto: a function and an HTTP API integration
# created with limits AWS refuses, to show that moto accepts them. AWS's
# refusals are NOT run, and the lesson quotes no error text for them.
#
# What is STAGED rather than typed:
#   - moto is started by the lab before the first command, as lesson 1's
#     section `your-lab` starts it, in a terminal of the student's own;
#   - app.py, app.zip and the role are made quietly before the transcript; the
#     lesson shows the two lines of app.py and says how the zip is made.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
LESSON1=$HERE/../le-ps61q5st

if [ "${1:-}" = prices ]; then
  export HTTPS_PROXY=$LAB_PROXY
  from_example "$LESSON1/the-price-sheet.md" prices.py > prices.py
  from_example "$HERE/the-cost-model.md" compare.py > compare.py
  block compare
  run 'python3 prices.py | python3 compare.py'
  block shop
  run 'python3 prices.py | python3 compare.py shop=2,2,2,2,2,2,2,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,2'
  block shop-quiet
  run 'python3 prices.py | python3 compare.py shop=0,0,0,0,0,0,0,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,0'
  exit 0
fi

quiet "printf 'def handler(event, context):\n    return {\"ok\": True}\n' > app.py"
quiet "python3 -c 'import zipfile; z = zipfile.ZipFile(\"app.zip\", \"w\"); z.write(\"app.py\"); z.close()'"
quiet "aws iam create-role --role-name report --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}'"

block limits
run 'aws lambda create-function --function-name report --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/report --zip-file fileb://app.zip --timeout 901 --query "[FunctionName, Timeout]"'
run 'API=$(aws apigatewayv2 create-api --name shop --protocol-type HTTP --query ApiId --output text)'
run 'aws apigatewayv2 create-integration --api-id "$API" --integration-type AWS_PROXY --integration-uri arn:aws:lambda:sa-east-1:123456789012:function:report --payload-format-version 2.0 --timeout-in-millis 120000 --query "[IntegrationType, TimeoutInMillis]"'
