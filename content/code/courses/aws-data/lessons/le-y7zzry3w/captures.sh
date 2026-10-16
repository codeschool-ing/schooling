#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSONS': the table is the first ```sh fence of lesson
# 9's the-key.md and its items come from lesson 9's seed.py; the stream, the
# variables and the three changes are the ```sh fences of this lesson's
# the-stream.md, the totals table the first of consumer.md, totals.py its
# schooling-example, and handler.py and trust.json the files ttl-and-lambda.md
# introduces. moto is empty when this starts.
#
# STAGED: nothing beyond what lab.sh stages for every lesson. Stream ARNs,
# shard ids, sequence numbers and event ids are moto's and change on every run.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$HERE"
L9="$LESSONS/le-4edkwgs2"

# ---- the-stream ------------------------------------------------------------------
bash -e <(fence "$L9/the-key.md" 1) || exit 1
example "$L9/single-table.md" seed.py seed.py
bash -e <(fence "$L/the-stream.md" 1) || exit 1
eval "$(fence "$L/the-stream.md" 2)"; export ARN SHARD
block stream-describe
run "aws dynamodb describe-table --table-name quitanda --query 'Table.[StreamSpecification,LatestStreamLabel]'"
run 'aws dynamodbstreams describe-stream --stream-arn "$ARN" --query "StreamDescription.[StreamStatus,StreamViewType,length(Shards),Shards[0].ShardId]"'
block stream-seed
run 'python3 seed.py'
run "aws dynamodbstreams get-records --shard-iterator \"\$(aws dynamodbstreams get-shard-iterator --stream-arn \"\$ARN\" --shard-id \"\$SHARD\" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)\" --query 'Records[:4].[eventName,dynamodb.SequenceNumber,dynamodb.Keys.sk.S]' --output text"
bash -e <(fence "$L/the-stream.md" 3) > /dev/null || exit 1
block stream-changes
run "aws dynamodbstreams get-records --shard-iterator \"\$(aws dynamodbstreams get-shard-iterator --stream-arn \"\$ARN\" --shard-id \"\$SHARD\" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)\" --query 'Records[30:].[eventName,dynamodb.SequenceNumber,dynamodb.Keys.sk.S]' --output text"

# ---- view-types ------------------------------------------------------------------
block view-modify
run "aws dynamodbstreams get-records --shard-iterator \"\$(aws dynamodbstreams get-shard-iterator --stream-arn \"\$ARN\" --shard-id \"\$SHARD\" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)\" --query 'Records[31]'"
block view-change
run "aws dynamodb update-table --table-name quitanda --stream-specification StreamEnabled=true,StreamViewType=KEYS_ONLY"

# ---- consumer --------------------------------------------------------------------
bash -e <(fence "$L/consumer.md" 1) || exit 1
example "$L/consumer.md" totals.py totals.py
block totals-run
run 'python3 totals.py'
run "aws dynamodb query --table-name quitanda --key-condition-expression 'pk = :p AND begins_with(sk, :o)' --expression-attribute-values '{\":p\": {\"S\": \"CUSTOMER#c-17\"}, \":o\": {\"S\": \"ORDER#\"}}' --query \"sum(Items[?!contains(sk.S, '#LINE#')].to_number(total_cents.N))\""

# ---- delivery --------------------------------------------------------------------
block totals-again
run 'python3 totals.py'
run 'python3 totals.py --naive'

# ---- ttl-and-lambda --------------------------------------------------------------
block ttl
run 'aws dynamodb update-time-to-live --table-name quitanda --time-to-live-specification Enabled=true,AttributeName=expires_at'
run "aws dynamodb put-item --table-name quitanda --item '{\"pk\": {\"S\": \"CART#c-18\"}, \"sk\": {\"S\": \"CART\"}, \"expires_at\": {\"N\": \"1760000000\"}}'"
run 'date -d @1760000000'
run "aws dynamodb get-item --table-name quitanda --key '{\"pk\": {\"S\": \"CART#c-18\"}, \"sk\": {\"S\": \"CART\"}}' --query 'Item.expires_at.N'"
file_fence "$L/ttl-and-lambda.md" handler.py > handler.py
file_fence "$L/ttl-and-lambda.md" trust.json > trust.json
block lambda
run 'python3 -m zipfile -c function.zip handler.py'
run 'aws iam create-role --role-name quitanda-totals --assume-role-policy-document file://trust.json --query Role.Arn'
run 'aws lambda create-function --function-name quitanda-totals --runtime python3.12 --handler handler.handler --role arn:aws:iam::123456789012:role/quitanda-totals --zip-file fileb://function.zip --query State'
run "aws lambda create-event-source-mapping --function-name quitanda-totals --event-source-arn \"\$ARN\" --starting-position TRIM_HORIZON --batch-size 100 --maximum-retry-attempts 2 --bisect-batch-on-function-error --query '[State,BatchSize,MaximumRetryAttempts,BisectBatchOnFunctionError]' --output text"
run "aws lambda list-event-source-mappings --query 'EventSourceMappings[].[State,LastProcessingResult]' --output text"
block kinesis
run 'aws kinesis create-stream --stream-name quitanda-changes --shard-count 1'
run 'aws dynamodb enable-kinesis-streaming-destination --table-name quitanda --stream-arn arn:aws:kinesis:sa-east-1:123456789012:stream/quitanda-changes 2>&1 | head -2'
block stream-price
run 'python3 prices.py dynamodb'
