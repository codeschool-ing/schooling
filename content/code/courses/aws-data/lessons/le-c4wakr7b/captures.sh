#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of aws-data (Data Firehose), as a
# script that produces them. Every transcript in the lesson was copied from its
# output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE FILES ARE THE LESSON'S: each JSON file below is read out of the section
# that shows it, under the name the section gives it. moto is empty when this
# starts. The Kinesis stream `orders` of lesson 20 is rebuilt here with one
# shard, because lesson 20's moto is gone.
#
# STAGED: nothing. The price block reads the cache lesson 1 filled.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
for f in delivery-stream.md:orders-to-s3.json delivery-stream.md:batch.json delivery-stream.md:batch-nl.json \
         prefixes.md:orders-by-store.json transform-and-convert.md:orders-parquet.json; do
  file_fence "$HERE/${f%%:*}" "${f#*:}" > "${f#*:}" || exit 1
done
show() { echo "for k in \$(aws s3api list-objects-v2 --bucket $1 --prefix $2 --query 'Contents[].Key' --output text); do echo \"\$k\"; aws s3 cp s3://$1/\$k - | cat -A; echo; done"; }

block create
run 'aws s3 mb s3://quitanda-raw-prod'
run 'aws firehose create-delivery-stream --delivery-stream-name orders-to-s3 --delivery-stream-type DirectPut --extended-s3-destination-configuration file://orders-to-s3.json'
run "aws firehose describe-delivery-stream --delivery-stream-name orders-to-s3 --query 'DeliveryStreamDescription.[DeliveryStreamStatus,DeliveryStreamType,Destinations[0].ExtendedS3DestinationDescription.BufferingHints]'"

block put
run "aws firehose put-record --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --record '{\"Data\": \"{\\\"order_id\\\": \\\"o-200\\\", \\\"customer_id\\\": \\\"c-17\\\", \\\"total_cents\\\": 1500}\\n\"}'"
run 'aws firehose put-record-batch --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --records file://batch.json --query FailedPutCount'
run 'aws firehose put-record-batch --delivery-stream-name orders-to-s3 --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount'
run 'aws s3 ls s3://quitanda-raw-prod --recursive'
run "$(show quitanda-raw-prod raw/orders/)"

block bounds
run "jq '.BufferingHints = {\"SizeInMBs\": 500, \"IntervalInSeconds\": 5000} | .Prefix = \"raw/orders-big/\"' orders-to-s3.json > orders-big.json"
run 'aws firehose create-delivery-stream --delivery-stream-name orders-big --extended-s3-destination-configuration file://orders-big.json'
run "aws firehose describe-delivery-stream --delivery-stream-name orders-big --query 'DeliveryStreamDescription.Destinations[0].ExtendedS3DestinationDescription.BufferingHints'"

block prefix-dt
run "jq '.Prefix = \"raw/orders-dt/dt=!{timestamp:yyyy-MM-dd}/\" | .ErrorOutputPrefix = \"errors/orders-dt/!{firehose:error-output-type}/\"' orders-to-s3.json > orders-dt.json"
run 'aws firehose create-delivery-stream --delivery-stream-name orders-dt --extended-s3-destination-configuration file://orders-dt.json'
run 'aws firehose put-record-batch --delivery-stream-name orders-dt --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount'
run 'aws s3 ls s3://quitanda-raw-prod/raw/orders-dt/ --recursive'

block prefix-store
run 'aws firehose create-delivery-stream --delivery-stream-name orders-by-store --extended-s3-destination-configuration file://orders-by-store.json'
run "aws firehose put-record --delivery-stream-name orders-by-store --cli-binary-format raw-in-base64-out --record '{\"Data\": \"{\\\"order_id\\\": \\\"o-205\\\", \\\"store\\\": \\\"pinheiros\\\"}\\n\"}'"
run 'aws s3 ls s3://quitanda-raw-prod/raw/orders-by-store/ --recursive'

block gzip
run "jq '.CompressionFormat = \"GZIP\" | .Prefix = \"raw/orders-gz/\"' orders-to-s3.json > orders-gz.json"
run 'aws firehose create-delivery-stream --delivery-stream-name orders-gz --extended-s3-destination-configuration file://orders-gz.json'
run 'aws firehose put-record-batch --delivery-stream-name orders-gz --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount'
run "K=\$(aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/orders-gz/ --query 'Contents[0].Key' --output text) && echo \"\$K\" && aws s3 cp s3://quitanda-raw-prod/\$K - | head -c 16 | od -c"

block parquet
run 'aws s3 mb s3://quitanda-curated-prod'
run 'aws glue get-table --database-name quitanda --name orders'
run 'aws firehose create-delivery-stream --delivery-stream-name orders-parquet --extended-s3-destination-configuration file://orders-parquet.json'
run 'aws firehose put-record-batch --delivery-stream-name orders-parquet --cli-binary-format raw-in-base64-out --records file://batch-nl.json --query FailedPutCount'
run "$(show quitanda-curated-prod curated/)"

block source
run 'aws kinesis create-stream --stream-name orders --shard-count 1'
run 'aws firehose create-delivery-stream --delivery-stream-name orders-from-stream --delivery-stream-type KinesisStreamAsSource --kinesis-stream-source-configuration KinesisStreamARN=arn:aws:kinesis:sa-east-1:123456789012:stream/orders,RoleARN=arn:aws:iam::123456789012:role/quitanda-firehose --extended-s3-destination-configuration RoleARN=arn:aws:iam::123456789012:role/quitanda-firehose,BucketARN=arn:aws:s3:::quitanda-raw-prod,Prefix=raw/orders-from-stream/'
run "aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{\"order_id\": \"o-206\"}'"
run 'aws s3 ls s3://quitanda-raw-prod/raw/orders-from-stream/ --recursive'
run "aws firehose put-record --delivery-stream-name orders-from-stream --cli-binary-format raw-in-base64-out --record '{\"Data\": \"{\\\"order_id\\\": \\\"o-207\\\"}\"}'"
run 'aws s3 ls s3://quitanda-raw-prod/raw/orders-from-stream/ --recursive'

block prices
run 'python3 prices.py kinesis'
