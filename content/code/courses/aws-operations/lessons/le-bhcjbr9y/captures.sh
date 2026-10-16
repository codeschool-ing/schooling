#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# moto keeps the trail and delivers nothing to its bucket, and lookup-events
# is a 500. The day of records is made up by mk-trail.py, read out of the
# lesson with the metric filter and the rule pattern, and copied into the
# bucket by the lesson's own command, standing for the trail's delivery.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf trail && mkdir trail && cd trail || exit 1
moto_up
student_env
from_lesson "$HERE/who-did-this.md" mk-trail.py > mk-trail.py
from_lesson "$HERE/alarms.md" key-events.json > key-events.json

block trail
run 'aws s3 mb s3://shop-trail-123456789012'
run "aws cloudtrail create-trail --name shop --s3-bucket-name shop-trail-123456789012 --is-multi-region-trail --enable-log-file-validation --query '[TrailARN,IsMultiRegionTrail,LogFileValidationEnabled]' --output text"
run 'aws cloudtrail start-logging --name shop'
run "aws cloudtrail get-trail-status --name shop --query '[IsLogging,LatestDeliveryTime]' --output text"
run 'aws s3 ls s3://shop-trail-123456789012 --recursive | wc -l'
block selectors
run "aws cloudtrail put-event-selectors --trail-name shop --advanced-event-selectors '[{\"Name\":\"management\",\"FieldSelectors\":[{\"Field\":\"eventCategory\",\"Equals\":[\"Management\"]}]},{\"Name\":\"orders objects\",\"FieldSelectors\":[{\"Field\":\"eventCategory\",\"Equals\":[\"Data\"]},{\"Field\":\"resources.type\",\"Equals\":[\"AWS::S3::Object\"]},{\"Field\":\"resources.ARN\",\"StartsWith\":[\"arn:aws:s3:::shop-orders/\"]}]}]' --query 'AdvancedEventSelectors[].Name' --output text"

block lookup
run 'aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteBucket 2>&1 | grep -m1 ERROR'
block delivered
run 'python3 mk-trail.py'
run 'aws s3 cp --recursive --quiet AWSLogs s3://shop-trail-123456789012/AWSLogs'
run "aws s3 ls s3://shop-trail-123456789012 --recursive | awk 'NR <= 2'"
run 'rm -r AWSLogs && aws s3 sync --quiet s3://shop-trail-123456789012/AWSLogs AWSLogs && find AWSLogs -name "*.json.gz" | wc -l'
block who-bucket
run "find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -c '.Records[] | select(.eventName == \"DeleteBucket\") | [.eventTime, .userIdentity.arn, .sourceIPAddress, .requestParameters.bucketName]'"
block who-changes
run "find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | select(.readOnly == false) | [.eventTime, .userIdentity.sessionContext.sessionIssuer.userName, (.userIdentity.arn | split(\"/\")[-1]), .eventName, .errorCode // \"-\"] | @tsv' | sort"
block who-denied
run "find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | select(.errorCode) | .errorMessage'"
block who-count
run "find AWSLogs -name '*.json.gz' -exec zcat {} + | jq -r '.Records[] | .userIdentity.arn' | sort | uniq -c"

block alarms
run 'aws logs create-log-group --log-group-name /shop/cloudtrail'
run "aws logs put-metric-filter --log-group-name /shop/cloudtrail --filter-name kms-pending-use --filter-pattern '{ (\$.eventSource = kms.amazonaws.com) && (\$.errorMessage = \"* is pending deletion.\") }' --metric-transformations metricName=KmsPendingKeyUse,metricNamespace=Shop/Security,metricValue=1"
run "aws logs describe-metric-filters --log-group-name /shop/cloudtrail --query 'metricFilters[].[filterName,metricTransformations[0].metricName]' --output text"
run 'aws cloudwatch put-metric-alarm --alarm-name kms-pending-key-used --namespace Shop/Security --metric-name KmsPendingKeyUse --statistic Sum --period 300 --evaluation-periods 1 --threshold 0 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions arn:aws:sns:sa-east-1:123456789012:shop-page'
block rule
run 'aws events put-rule --name key-changes --event-pattern file://key-events.json --query RuleArn --output text'

cd "$HOME/aws" || exit 1
block prices
run 'python3 price.py AWSCloudTrail EventsRecorded'
