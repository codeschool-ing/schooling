#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of aws-compute (Step Functions), as
# a script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT
# COMMITTED.
#
#   bash lessons/le-xmskh6yb/captures.sh
#
# moto 5.2.3 RUNS a state machine only when its `execute_state_machine` setting
# is on; by default an execution returns a fixed, invented history. The first
# command below turns it on, through moto's own configuration address, and the
# lesson shows the student that command. With it on, moto runs Choice, Wait,
# Task (the SQS integration, against moto's own SQS), Map, Parallel, Pass,
# Succeed and Fail, with Retry and Catch, and honours .waitForTaskToken. The
# waits are real seconds, so the timestamps are this machine's.
#
# What moto does NOT do, and the lesson says so: it stores an EXPRESS state
# machine as STANDARD; it accepts a definition AWS refuses; it cannot answer
# start-sync-execution (the command line sends it to a `sync-` host).
#
# What is STAGED rather than typed:
#   - order.asl.json, split.asl.json, retry.asl.json and token.asl.json are
#     read out of the examples in the sections that show them;
#   - prices.py is read out of the example in lesson 1's `the-price-sheet`; its
#     cache (~/.cache/aws-prices) was filled by lesson 1's `prices` run.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/amazon-states-language.md" order.asl.json > order.asl.json
from_example "$HERE/amazon-states-language.md" split.asl.json > split.asl.json
from_example "$HERE/errors-and-retries.md" retry.asl.json > retry.asl.json
from_example "$HERE/waiting.md" token.asl.json > token.asl.json
from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py

block config
run 'curl -s -XPOST localhost:4567/moto-api/config -d '"'"'{"stepfunctions": {"execute_state_machine": true}}'"'"'; echo'

block setup
run 'aws sqs create-queue --queue-name orders --query QueueUrl --output text'
run 'aws iam create-role --role-name orders-sfn --assume-role-policy-document '"'"'{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "states.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'"'"' --query Role.Arn --output text'
run 'ROLE=arn:aws:iam::123456789012:role/orders-sfn'
run 'SM=$(aws stepfunctions create-state-machine --name orders --definition file://order.asl.json --role-arn "$ROLE" --query stateMachineArn --output text); echo "$SM"'

block run-large
run 'aws stepfunctions start-execution --state-machine-arn "$SM" --name order-42 --input '"'"'{"id": "42", "total": 1500}'"'"' --query executionArn --output text'
run 'aws stepfunctions describe-execution --execution-arn "${SM/stateMachine/execution}:order-42" --query status'
run 'sleep 3'
run 'aws stepfunctions describe-execution --execution-arn "${SM/stateMachine/execution}:order-42" --query "{status: status, output: output}"'
run 'aws stepfunctions get-execution-history --execution-arn "${SM/stateMachine/execution}:order-42" --query "events[].[id, type]" --output text'
run 'aws sqs receive-message --queue-url https://sqs.sa-east-1.amazonaws.com/123456789012/orders --query "Messages[0].Body" --output text'

block run-small
run 'aws stepfunctions start-execution --state-machine-arn "$SM" --name order-43 --input '"'"'{"id": "43", "total": 300}'"'"' --query executionArn --output text'
run 'sleep 1'
run 'aws stepfunctions get-execution-history --execution-arn "${SM/stateMachine/execution}:order-43" --query "events[].type" --output text'

block bad-definition
run 'aws stepfunctions create-state-machine --name broken --definition '"'"'{"StartAt": "A", "States": {"A": {"Type": "Pass", "Next": "B"}}}'"'"' --role-arn "$ROLE" --query stateMachineArn --output text'

block split
run 'SPLIT=$(aws stepfunctions create-state-machine --name split --definition file://split.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)'
run 'aws stepfunctions start-execution --state-machine-arn "$SPLIT" --name order-44 --input '"'"'{"lines": [{"sku": "A1", "cents": 1200}, {"sku": "B7", "cents": 350}]}'"'"' --query executionArn --output text'
run 'sleep 1'
run 'aws stepfunctions describe-execution --execution-arn "${SPLIT/stateMachine/execution}:order-44" --query output --output text | jq -c .'

block express
run 'aws stepfunctions create-state-machine --name orders-fast --type EXPRESS --definition file://split.asl.json --role-arn "$ROLE" --query stateMachineArn --output text'
run 'aws stepfunctions describe-state-machine --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast --query type'
run 'aws stepfunctions start-sync-execution --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast --input '"'"'{"lines": []}'"'"''

block prices
run 'python3 prices.py integration | sed -n 9,12p'

block retry
run 'RETRY=$(aws stepfunctions create-state-machine --name retry --definition file://retry.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)'
run 'aws stepfunctions start-execution --state-machine-arn "$RETRY" --name order-45 --input '"'"'{"id": "45"}'"'"' --query executionArn --output text'
run 'sleep 5'
run 'aws stepfunctions describe-execution --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "{status: status, error: error, cause: cause}"'
run 'aws stepfunctions get-execution-history --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "events[].[id, type, timestamp]" --output text'
run 'aws stepfunctions get-execution-history --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "events[?type==\`TaskFailed\`].taskFailedEventDetails | [0]"'

block token
run 'aws sqs create-queue --queue-name store --query QueueUrl --output text'
run 'TOKEN_SM=$(aws stepfunctions create-state-machine --name ask-store --definition file://token.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)'
run 'aws stepfunctions start-execution --state-machine-arn "$TOKEN_SM" --name order-46 --input '"'"'{"id": "46"}'"'"' --query executionArn --output text'
run 'sleep 1'
run 'aws stepfunctions describe-execution --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query status'
run 'MSG=$(aws sqs receive-message --queue-url https://sqs.sa-east-1.amazonaws.com/123456789012/store --query "Messages[0].Body" --output text); echo "$MSG"'
run 'aws stepfunctions send-task-success --task-token "$(echo "$MSG" | jq -r .token)" --task-output '"'"'{"picked": true}'"'"''
run 'sleep 1'
run 'aws stepfunctions describe-execution --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query "{status: status, output: output}"'
run 'aws stepfunctions get-execution-history --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query "events[].type" --output text'
