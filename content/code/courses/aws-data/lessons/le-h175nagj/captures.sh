#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of aws-data (delivery guarantees),
# as a script that produces them. Every transcript in the lesson was copied
# from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S. pay.py and totals.py are read out of the
# examples in the-replay.md, and the commands that create the stream and the
# two tables are that section's first ```sh fence, run as it stands. moto is
# empty when this starts.
#
# The "crash" is the program's own: totals.py ends itself with os._exit after
# the number of records it is given, before writing its checkpoint, which is
# what a process killed by its machine does. Nothing else is staged.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
example "$HERE/the-replay.md" pay.py pay.py || exit 1
example "$HERE/the-replay.md" totals.py totals.py || exit 1

block retry
run 'aws kinesis create-stream --stream-name orders --shard-count 1'
for _ in 1 2; do
  run "aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{\"order_id\": \"o-301\", \"cents\": 4590}' --query SequenceNumber --output text"
done
run "IT=\$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator \"\$IT\" --query 'Records[].[SequenceNumber,PartitionKey,Data]' --output text"

bash -e <(fence "$HERE/the-replay.md" 1) || exit 1
block pay
run 'python3 pay.py'

SCAN="aws dynamodb scan --table-name quitanda-totals --query 'Items[].[customer_id.S,cents.N]' --output text"
block plain
run 'python3 totals.py plain 4'
run 'ls checkpoint.txt'
run 'python3 totals.py plain'
run "$SCAN"

block dedupe
run 'rm checkpoint.txt && aws dynamodb delete-table --table-name quitanda-totals --query TableDescription.TableStatus'
run 'aws dynamodb create-table --table-name quitanda-totals --billing-mode PAY_PER_REQUEST --attribute-definitions AttributeName=customer_id,AttributeType=S --key-schema AttributeName=customer_id,KeyType=HASH --query TableDescription.TableStatus'
run 'python3 totals.py dedupe 4'
run 'python3 totals.py dedupe'
run "$SCAN"

block again
run 'rm checkpoint.txt && python3 totals.py dedupe'
run "$SCAN"
run 'aws dynamodb scan --table-name quitanda-processed --select COUNT --query Count'

block s3keys
run 'aws s3 mb s3://quitanda-raw-prod'
run "printf '%s\\n' '{\"order_id\": \"o-301\", \"cents\": 4590}' '{\"order_id\": \"o-302\", \"cents\": 12800}' > batch.json"
for _ in 1 2; do
  run 'aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json'
done
for _ in 1 2; do
  run 'aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json'
done
run 'aws s3 ls s3://quitanda-raw-prod/raw/ --recursive'

block upsert
for _ in 1 2; do
  run "aws dynamodb update-item --table-name quitanda-totals --key '{\"customer_id\": {\"S\": \"c-08\"}}' --update-expression 'ADD cents :c' --expression-attribute-values '{\":c\": {\"N\": \"500\"}}' --return-values UPDATED_NEW --query Attributes.cents.N --output text"
done
for _ in 1 2; do
  run "aws dynamodb put-item --table-name quitanda-totals --item '{\"customer_id\": {\"S\": \"c-09\"}, \"cents\": {\"N\": \"500\"}}'"
done
run "aws dynamodb get-item --table-name quitanda-totals --key '{\"customer_id\": {\"S\": \"c-09\"}}' --query Item.cents.N --output text"
