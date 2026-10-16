#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# moto produces no findings of its own: GuardDuty's list-findings is a 404 and
# Inspector's enable a 500. The six findings Security Hub holds are made up by
# mk-findings.py, read out of the lesson with triage.py and the rule pattern.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf findings && mkdir findings && cd findings || exit 1
moto_up
student_env
from_lesson "$HERE/security-hub.md" mk-findings.py > mk-findings.py
from_lesson "$HERE/triage.md" triage.py > triage.py
from_lesson "$HERE/triage.md" guardduty-high.json > guardduty-high.json

block detector
run 'aws guardduty create-detector --enable --finding-publishing-frequency FIFTEEN_MINUTES --query DetectorId --output text'
run 'DETECTOR=$(aws guardduty list-detectors --query "DetectorIds[0]" --output text)'
run "aws guardduty get-detector --detector-id \$DETECTOR --query '[Status,FindingPublishingFrequency,DataSources.CloudTrail.Status]' --output text"
block filter
run "aws guardduty create-filter --detector-id \$DETECTOR --name office-scanner --action ARCHIVE --rank 1 --finding-criteria '{\"Criterion\":{\"type\":{\"Eq\":[\"Recon:EC2/PortProbeUnprotectedPort\"]},\"service.action.networkConnectionAction.remoteIpDetails.ipAddressV4\":{\"Eq\":[\"198.51.100.10\"]}}}' --query Name"
block no-findings
run 'aws guardduty list-findings --detector-id $DETECTOR 2>&1 | grep -m1 -o "Not Found"'
run 'aws inspector2 enable --resource-types ECR EC2 2>&1 | grep -m1 ERROR'

block hub
run "aws securityhub enable-security-hub --no-enable-default-standards"
run "aws securityhub describe-hub --query '[HubArn,ControlFindingGenerator]' --output text"
block import
run 'python3 mk-findings.py'
run "aws securityhub batch-import-findings --findings file://findings.json --query '[SuccessCount,FailedCount]' --output text"
run "aws securityhub get-findings --query 'Findings[].[Id,Severity.Label,Title]' --output text"
block filter-ignored
run "aws securityhub get-findings --filters '{\"SeverityLabel\":[{\"Value\":\"CRITICAL\",\"Comparison\":\"EQUALS\"}]}' --query 'Findings[].Id' --output text"

block triage
run 'python3 triage.py'
block rule
run 'aws events put-rule --name guardduty-high --event-pattern file://guardduty-high.json --query RuleArn --output text'
run 'aws sns create-topic --name shop-page --query TopicArn --output text'
run 'aws events put-targets --rule guardduty-high --targets Id=page,Arn=arn:aws:sns:sa-east-1:123456789012:shop-page --query FailedEntryCount'

cd "$HOME/aws" || exit 1
block prices
run 'python3 price.py AmazonGuardDuty "CloudTrail event analyzed"'
run 'python3 price.py AmazonGuardDuty PaidEventsAnalyzed-Bytes'
run 'python3 price.py AmazonInspectorV2 SAE1-container-image'
run 'python3 price.py AmazonInspectorV2 SAE1-EC2-Scanning'
run 'python3 price.py AWSSecurityHub "security checks per account"'
