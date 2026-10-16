#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of aws-data (Kinesis Data Streams),
# as a script that produces them. Every transcript in the lesson was copied
# from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S. shard_of.py is read out of shards.md, and
# producer.py and consumer.py out of the examples in ordering.md, so what runs
# here is what the student copies. moto is empty when this starts, as it is
# for the student at the start of every lesson.
#
# STAGED: nothing. The price block reads the cache lesson 1 filled.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
file_fence "$HERE/shards.md" shard_of.py > shard_of.py || exit 1
example "$HERE/ordering.md" producer.py producer.py || exit 1
example "$HERE/ordering.md" consumer.py consumer.py || exit 1

block create
run 'aws kinesis create-stream --stream-name orders --shard-count 2'
run "aws kinesis describe-stream-summary --stream-name orders --query 'StreamDescriptionSummary.[StreamStatus,OpenShardCount,RetentionPeriodHours]' --output text"
run "aws kinesis list-shards --stream-name orders --query 'Shards[].[ShardId,HashKeyRange.StartingHashKey,HashKeyRange.EndingHashKey]' --output text"

block predict
run 'python3 shard_of.py orders c-17 c-03 c-02 c-05'

block produce
run 'python3 producer.py orders'

block consume
run 'python3 consumer.py orders'

S0='--stream-name orders --shard-id shardId-000000000000'
block iterators
run "IT=\$(aws kinesis get-shard-iterator $S0 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator \"\$IT\" --limit 1"
run "IT=\$(aws kinesis get-shard-iterator $S0 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator \"\$IT\" --limit 1 --query 'Records[0].Data' --output text | base64 -d; echo"
for t in TRIM_HORIZON LATEST; do
  run "IT=\$(aws kinesis get-shard-iterator $S0 --shard-iterator-type $t --query ShardIterator --output text) && aws kinesis get-records --shard-iterator \"\$IT\" --query 'Records[].SequenceNumber' --output text"
done
for t in AT_SEQUENCE_NUMBER AFTER_SEQUENCE_NUMBER; do
  run "IT=\$(aws kinesis get-shard-iterator $S0 --shard-iterator-type $t --starting-sequence-number 3 --query ShardIterator --output text) && aws kinesis get-records --shard-iterator \"\$IT\" --query 'Records[].SequenceNumber' --output text"
done
run "IT=\$(aws kinesis get-shard-iterator $S0 --shard-iterator-type AT_TIMESTAMP --timestamp \$(date -d '10 minutes ago' +%s) --query ShardIterator --output text) && aws kinesis get-records --shard-iterator \"\$IT\" --query 'Records[].SequenceNumber' --output text"
run "IT=\$(aws kinesis get-shard-iterator $S0 --shard-iterator-type LATEST --query ShardIterator --output text) && aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{\"order_id\": \"o-105\", \"customer_id\": \"c-17\", \"status\": \"placed\"}' --query SequenceNumber --output text && aws kinesis get-records --shard-iterator \"\$IT\" --query 'Records[].SequenceNumber' --output text"

block retention
run 'aws kinesis increase-stream-retention-period --stream-name orders --retention-period-hours 168'
run "aws kinesis describe-stream-summary --stream-name orders --query StreamDescriptionSummary.RetentionPeriodHours"
run 'aws kinesis increase-stream-retention-period --stream-name orders --retention-period-hours 9000'
run 'aws kinesis decrease-stream-retention-period --stream-name orders --retention-period-hours 12'

block nothrottle
run 'aws kinesis create-stream --stream-name orders-test --shard-count 1'
run "python3 -c \"import boto3, time; k = boto3.client('kinesis'); t = time.time(); f = sum(k.put_records(StreamName='orders-test', Records=[{'PartitionKey': f'c-{i}', 'Data': b'x' * 900} for i in range(500)])['FailedRecordCount'] for _ in range(4)); print(f, 'failed of 2000 in', round(time.time() - t, 2), 's')\""

block reshard
run 'aws kinesis update-shard-count --stream-name orders --target-shard-count 4 --scaling-type UNIFORM_SCALING'
run "aws kinesis list-shards --stream-name orders --query 'Shards[].[ShardId,ParentShardId,HashKeyRange.StartingHashKey,SequenceNumberRange.EndingSequenceNumber]' --output text"
run 'python3 shard_of.py orders c-17 c-03 c-02 c-05'

block splitmerge
run 'aws kinesis split-shard --stream-name orders-test --shard-to-split shardId-000000000000 --new-starting-hash-key 170141183460469231731687303715884105728'
run "aws kinesis list-shards --stream-name orders-test --query 'Shards[].[ShardId,ParentShardId,SequenceNumberRange.EndingSequenceNumber]' --output text"
run 'aws kinesis merge-shards --stream-name orders-test --shard-to-merge shardId-000000000001 --adjacent-shard-to-merge shardId-000000000002'
run "aws kinesis list-shards --stream-name orders-test --query 'Shards[].[ShardId,ParentShardId,AdjacentParentShardId,SequenceNumberRange.EndingSequenceNumber]' --output text"

block ondemand
run 'aws kinesis create-stream --stream-name orders-od --stream-mode-details StreamMode=ON_DEMAND'
for s in orders orders-od; do
  run "aws kinesis describe-stream-summary --stream-name $s --query 'StreamDescriptionSummary.[StreamName,StreamModeDetails.StreamMode,OpenShardCount]' --output text"
done

block prices
run 'python3 prices.py kinesis'
