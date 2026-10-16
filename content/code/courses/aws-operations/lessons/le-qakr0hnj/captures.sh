#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# moto records configuration items for the buckets it holds and evaluates no
# rule: compliance is a 500, and so is put-conformance-pack. evaluate.py and
# shop-pack.yaml are read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf config && mkdir config && cd config || exit 1
moto_up
student_env
from_lesson "$HERE/custom-rule.md" evaluate.py > evaluate.py
from_lesson "$HERE/conformance-packs.md" shop-pack.yaml > shop-pack.yaml
from_lesson "$HERE/rules.md" required-owner.json > required-owner.json

block recorder
run 'aws s3 mb s3://shop-config-123456789012'
run 'aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=arn:aws:iam::123456789012:role/config-recorder --recording-group allSupported=true,includeGlobalResourceTypes=false'
run 'aws configservice put-delivery-channel --delivery-channel name=default,s3BucketName=shop-config-123456789012'
run 'aws configservice start-configuration-recorder --configuration-recorder-name default'
run "aws configservice describe-configuration-recorder-status --query 'ConfigurationRecordersStatus[0].[name,recording,lastStatus]' --output text"
block buckets
fence "$HERE/recorder.md" 1
run "aws configservice list-discovered-resources --resource-type AWS::S3::Bucket --query 'resourceIdentifiers[].resourceId' --output text"
run "aws configservice get-resource-config-history --resource-type AWS::S3::Bucket --resource-id shop-exports --query 'configurationItems[0].[configurationItemStatus,configurationItemCaptureTime]' --output text"
run "aws configservice get-resource-config-history --resource-type AWS::S3::Bucket --resource-id shop-exports --query 'configurationItems[0].[tags, supplementaryConfiguration.PublicAccessBlockConfiguration]'"

block rules
run "aws configservice put-config-rule --config-rule '{\"ConfigRuleName\":\"s3-public-read\",\"Source\":{\"Owner\":\"AWS\",\"SourceIdentifier\":\"S3_BUCKET_PUBLIC_READ_PROHIBITED\"},\"Scope\":{\"ComplianceResourceTypes\":[\"AWS::S3::Bucket\"]}}'"
run 'aws configservice put-config-rule --config-rule file://required-owner.json'
run "aws configservice describe-config-rules --query 'ConfigRules[].[ConfigRuleName,Source.SourceIdentifier,ConfigRuleState]' --output text"
block rules-bad
run "aws configservice put-config-rule --config-rule '{\"ConfigRuleName\":\"tags\",\"Source\":{\"Owner\":\"AWS\",\"SourceIdentifier\":\"REQUIRED_TAG\"}}' 2>&1 | tail -1"
block rules-compliance
run 'aws configservice get-compliance-details-by-config-rule --config-rule-name required-owner 2>&1 | grep -m1 ERROR'

block evaluate
run 'python3 evaluate.py'

block pack
run 'aws configservice put-conformance-pack --conformance-pack-name shop-baseline --template-body file://shop-pack.yaml 2>&1 | grep -m1 ERROR'

cd "$HOME/aws" || exit 1
block prices
run 'python3 price.py AWSConfig ConfigurationItemRecorded'
run 'python3 price.py AWSConfig SAE1-ConfigRuleEvaluations'
