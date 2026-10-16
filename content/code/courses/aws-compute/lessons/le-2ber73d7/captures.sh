#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of aws-compute (triggers), as a
# script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT
# COMMITTED.
#
#   LAB_HOSTS=1 bash lessons/le-2ber73d7/captures.sh
#
# Two things answer here, and the lesson says which each time:
#   - moto 5.2.3 keeps the function, its URL, its asynchronous settings, the
#     bucket notification, the event source mappings and the EventBridge rule.
#     It runs no function: a source that would invoke one is pointed at an SQS
#     queue instead where the lesson needs to see what was delivered, and moto
#     does deliver S3 notifications and EventBridge events to SQS;
#   - the handlers run in public.ecr.aws/lambda/python:3.12, AWS's Lambda base
#     image with the Runtime Interface Emulator, through Docker on this
#     machine's own network (LAB_HOSTS=1), with events made from what moto
#     delivered or, for SQS, written by hand in AWS's documented shape.
#
# What is STAGED rather than typed:
#   - the base image was on the machine before the run (see lesson 14);
#   - a pause of two seconds after each `docker run -d`, and a wait after each
#     `docker stop` until the container is gone;
#   - the role, the functions' zips and photo.jpg, a three-byte
#     file, are made quietly; the lesson shows how in lesson 14.
#
# Ids, hashes, dates and the function URL's host differ on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04, Docker 29, no AWS account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

INVOKE='curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations'
ROLE=arn:aws:iam::123456789012:role/trigger-role

# nth_json MD N: the Nth ```json fence of MD
nth_json() {
  python3 - "$1" "$2" <<'PY'
import re, sys
fences = re.findall(r'^```json\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)
sys.stdout.write(fences[int(sys.argv[2]) - 1])
PY
}

mkdir -p thumbs orders
from_lesson "$HERE/push-sources.md" thumbs.py > thumbs/thumbs.py
from_example "$HERE/pollers.md" orders.py > orders/orders.py
nth_json "$HERE/pollers.md" 1 > sqs-event.json
nth_json "$HERE/eventbridge-rules.md" 1 > pattern.json
quiet 'docker rm -f thumbs orders'
quiet 'printf "hi\n" > photo.jpg'
quiet "aws iam create-role --role-name trigger-role --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}'"
quiet '(cd thumbs && zip -q ../thumbs.zip thumbs.py) && (cd orders && zip -q ../orders.zip orders.py)'

block functions
run "aws lambda create-function --function-name thumbs --runtime python3.12 --handler thumbs.handler --role $ROLE --zip-file fileb://thumbs.zip --query FunctionArn"
run "aws lambda create-function --function-name orders --runtime python3.12 --handler orders.handler --role $ROLE --zip-file fileb://orders.zip --query FunctionArn"

block async-config
run "aws lambda put-function-event-invoke-config --function-name thumbs --maximum-retry-attempts 1 --maximum-event-age-in-seconds 3600 --destination-config '{\"OnFailure\": {\"Destination\": \"arn:aws:sqs:sa-east-1:123456789012:thumbs-failed\"}}'"

block url
run 'aws lambda create-function-url-config --function-name orders --auth-type AWS_IAM'

block s3-permission
run 'aws s3api create-bucket --bucket shop-uploads-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1 --query Location'
run 'aws lambda add-permission --function-name thumbs --statement-id s3-uploads --action lambda:InvokeFunction --principal s3.amazonaws.com --source-arn arn:aws:s3:::shop-uploads-123456789012 --source-account 123456789012 --query Statement --output text | jq .'
block s3-notify
run "aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{\"LambdaFunctionConfigurations\": [{\"LambdaFunctionArn\": \"arn:aws:lambda:sa-east-1:123456789012:function:thumbs\", \"Events\": [\"s3:ObjectCreated:*\"], \"Filter\": {\"Key\": {\"FilterRules\": [{\"Name\": \"prefix\", \"Value\": \"uploads/\"}]}}}]}'"
run "aws s3api get-bucket-notification-configuration --bucket shop-uploads-123456789012 --query 'LambdaFunctionConfigurations[0].[LambdaFunctionArn,Events[0]]'"
block s3-nothere
run "aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{\"LambdaFunctionConfigurations\": [{\"LambdaFunctionArn\": \"arn:aws:lambda:sa-east-1:123456789012:function:no-such-function\", \"Events\": [\"s3:ObjectCreated:*\"]}]}' && echo accepted"

block s3-queue
run 'aws sqs create-queue --queue-name s3-witness --query QueueUrl'
run "aws s3api put-bucket-notification-configuration --bucket shop-uploads-123456789012 --notification-configuration '{\"QueueConfigurations\": [{\"QueueArn\": \"arn:aws:sqs:sa-east-1:123456789012:s3-witness\", \"Events\": [\"s3:ObjectCreated:*\"], \"Filter\": {\"Key\": {\"FilterRules\": [{\"Name\": \"prefix\", \"Value\": \"uploads/\"}]}}}]}'"
run 'aws s3api put-object --bucket shop-uploads-123456789012 --key uploads/cat.jpg --body photo.jpg --query ETag'
run 'aws s3api put-object --bucket shop-uploads-123456789012 --key drafts/dog.jpg --body photo.jpg --query ETag'
run "aws sqs receive-message --queue-url http://localhost:4567/123456789012/s3-witness --max-number-of-messages 10 --visibility-timeout 0 --query 'Messages[].Body' | jq -r '.[]' | cut -c1-90"
block s3-event
run "aws sqs receive-message --queue-url http://localhost:4567/123456789012/s3-witness --max-number-of-messages 10 --visibility-timeout 0 --query 'Messages[].Body' | jq -r '.[]' | grep Records > s3-event.json"
run 'jq . s3-event.json'
block s3-handler
run 'docker run --rm -d --name thumbs -p 9000:8080 -v "$PWD/thumbs":/var/task:ro public.ecr.aws/lambda/python:3.12 thumbs.handler'
quiet 'sleep 2'
run "$INVOKE -d @s3-event.json; echo"
run "docker logs thumbs 2>&1 | grep resize"
run 'docker stop thumbs'
quiet 'while docker inspect thumbs >/dev/null 2>&1; do sleep 0.2; done'

block sqs-mapping
run 'aws sqs create-queue --queue-name orders --query QueueUrl'
run 'aws lambda create-event-source-mapping --function-name orders --event-source-arn arn:aws:sqs:sa-east-1:123456789012:orders --batch-size 10 --maximum-batching-window-in-seconds 5 --function-response-types ReportBatchItemFailures --query "{State:State,BatchSize:BatchSize,Window:MaximumBatchingWindowInSeconds,Responses:FunctionResponseTypes}"'
block partial
run 'docker run --rm -d --name orders -p 9000:8080 -v "$PWD/orders":/var/task:ro public.ecr.aws/lambda/python:3.12 orders.handler'
quiet 'sleep 2'
run "$INVOKE -d @sqs-event.json; echo"
run "docker logs orders 2>&1 | grep -E '^(order|cannot)'"
run 'docker stop orders'
quiet 'while docker inspect orders >/dev/null 2>&1; do sleep 0.2; done'

block stream
run 'aws dynamodb create-table --table-name carts --attribute-definitions AttributeName=id,AttributeType=S --key-schema AttributeName=id,KeyType=HASH --billing-mode PAY_PER_REQUEST --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES --query TableDescription.LatestStreamArn'
run 'STREAM=$(aws dynamodb describe-table --table-name carts --query Table.LatestStreamArn --output text)'
run 'aws lambda create-event-source-mapping --function-name orders --event-source-arn "$STREAM" --starting-position TRIM_HORIZON --batch-size 100 --bisect-batch-on-function-error --maximum-retry-attempts 2 --query "{State:State,Start:StartingPosition,Bisect:BisectBatchOnFunctionError,Retries:MaximumRetryAttempts}"'
run 'aws lambda list-event-source-mappings --function-name orders --query "EventSourceMappings[].[EventSourceArn,State,BatchSize]" --output text'

block rule
run 'aws events put-rule --name big-orders --event-pattern file://pattern.json --query RuleArn'
run 'aws lambda add-permission --function-name orders --statement-id big-orders --action lambda:InvokeFunction --principal events.amazonaws.com --source-arn arn:aws:events:sa-east-1:123456789012:rule/big-orders --query Statement --output text | jq -c .Condition'
run 'aws events put-targets --rule big-orders --targets Id=orders,Arn=arn:aws:lambda:sa-east-1:123456789012:function:orders'
block test-pattern
run "aws events test-event-pattern --event-pattern file://pattern.json --event '{\"id\": \"1\", \"account\": \"123456789012\", \"source\": \"shop.orders\", \"time\": \"2026-10-16T12:00:00Z\", \"region\": \"sa-east-1\", \"resources\": [], \"detail-type\": \"OrderPlaced\", \"detail\": {\"total\": 99.9}}'; echo \"exit status \$?\""
block witness
run 'aws sqs create-queue --queue-name rule-witness --query QueueUrl'
run 'aws events put-targets --rule big-orders --targets Id=witness,Arn=arn:aws:sqs:sa-east-1:123456789012:rule-witness --query FailedEntryCount'
run 'aws events remove-targets --rule big-orders --ids orders --query FailedEntryCount'
run "aws events put-events --entries '[{\"Source\": \"shop.orders\", \"DetailType\": \"OrderPlaced\", \"Detail\": \"{\\\"order\\\": \\\"A-1\\\", \\\"total\\\": 1299.9}\"}, {\"Source\": \"shop.orders\", \"DetailType\": \"OrderPlaced\", \"Detail\": \"{\\\"order\\\": \\\"A-2\\\", \\\"total\\\": 99.9}\"}, {\"Source\": \"shop.payments\", \"DetailType\": \"OrderPlaced\", \"Detail\": \"{\\\"order\\\": \\\"A-3\\\", \\\"total\\\": 5000}\"}]' --query FailedEntryCount"
run "aws sqs receive-message --queue-url http://localhost:4567/123456789012/rule-witness --max-number-of-messages 10 --query 'Messages[].Body' | jq -r '.[]' | jq -c '{source, detail}'"
