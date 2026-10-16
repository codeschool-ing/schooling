#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# The load balancer the web ACL is attached to is made by the lesson's own
# fence (building.md, the first sh fence). web-acl.json is read out of the
# lesson. Nothing here sends a request through the web ACL: moto stores it and
# inspects no traffic.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf waf && mkdir waf && cd waf || exit 1
moto_up
student_env
from_lesson "$HERE/building.md" web-acl.json > web-acl.json
fence "$HERE/building.md" 1

block ipset
run 'IPSET=$(aws wafv2 create-ip-set --name blocked --scope REGIONAL --ip-address-version IPV4 --addresses 203.0.113.0/24 198.51.100.7/32 --query Summary.ARN --output text); echo $IPSET'
run "jq --arg a \"\$IPSET\" '.Rules[0].Statement.IPSetReferenceStatement.ARN = \$a' web-acl.json > shop-acl.json"
block create
run 'aws wafv2 create-web-acl --cli-input-json file://shop-acl.json'
block create-raw
run 'aws wafv2 create-web-acl --cli-input-json file://shop-acl.json --cli-binary-format raw-in-base64-out --query Summary.Id --output text'
block read
run 'ID=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[0].Id" --output text)'
run "aws wafv2 get-web-acl --name shop --scope REGIONAL --id \$ID --query 'WebACL.Rules[].[Priority,Name,keys(Action || OverrideAction)[0]]' --output text"
run "aws wafv2 get-web-acl --name shop --scope REGIONAL --id \$ID --query WebACL.Capacity"
block attach
run 'ACL=$(aws wafv2 list-web-acls --scope REGIONAL --query "WebACLs[0].ARN" --output text)'
run 'LB=$(aws elbv2 describe-load-balancers --names shop --query "LoadBalancers[0].LoadBalancerArn" --output text)'
run 'aws wafv2 associate-web-acl --web-acl-arn $ACL --resource-arn $LB'
run 'aws wafv2 get-web-acl-for-resource --resource-arn $LB --query WebACL.Name'
block capacity
run "aws wafv2 check-capacity --scope REGIONAL --cli-binary-format raw-in-base64-out --rules \"\$(jq .Rules shop-acl.json)\" 2>&1 | grep -m1 ERROR"

block count
run 'TOKEN=$(aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query LockToken --output text)'
run "jq '.Rules[1].Action = {\"Count\": {}} | del(.Name, .Scope)' shop-acl.json > login-count.json"
run 'aws wafv2 update-web-acl --name shop --scope REGIONAL --id $ID --lock-token $TOKEN --cli-input-json file://login-count.json --cli-binary-format raw-in-base64-out'
run 'aws wafv2 update-web-acl --name shop --scope REGIONAL --id $ID --lock-token $TOKEN --cli-input-json file://login-count.json --cli-binary-format raw-in-base64-out'
run "aws wafv2 get-web-acl --name shop --scope REGIONAL --id \$ID --query 'WebACL.Rules[1].Action'"
block logging
run 'aws logs create-log-group --log-group-name shop-waf'
run 'aws wafv2 put-logging-configuration --logging-configuration ResourceArn=$ACL,LogDestinationConfigs=arn:aws:logs:sa-east-1:123456789012:log-group:shop-waf --query LoggingConfiguration.LogDestinationConfigs'

cd "$HOME/aws" || exit 1
block prices
run 'python3 price.py awswaf SAE1-WebACLV2'
run 'python3 price.py awswaf SAE1-RuleV2'
run 'python3 price.py awswaf SAE1-RequestV2-Tier'
