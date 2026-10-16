#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
#   bash ../../lab.sh tools   # once: Node.js, the CDK and its library, from
#                             # the first sh fence of the section "app"
#   bash captures.sh
#
# app.js and app.test.js are read out of the lesson (from_lesson). The
# parameter /cdk-bootstrap/hnb659fds/version is put into moto by hand, in a
# transcript, standing for what `cdk bootstrap` would create; the lesson says so.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws/cdk" || exit 1
rm -rf cdk.out template.yaml app.js app.test.js
from_lesson "$HERE/app.md" app.js > app.js
from_lesson "$HERE/tests.md" app.test.js > app.test.js
moto_up
student_env

block versions
run 'node --version'
run 'cdk --version'

block synth
run 'cdk synth --app "node app.js" > template.yaml'
run 'wc -l app.js template.yaml'
run "grep -E '^    Type: ' template.yaml | sort | uniq -c"
run 'ls cdk.out'

block policy
run "sed -n '/UploadsPolicy/,/Version/p' template.yaml"
block bootstrap-rule
run "sed -n '/^Parameters:/,\$p' template.yaml"

block deploy-refused
run 'aws cloudformation create-stack --stack-name ShopBase --template-body file://cdk.out/ShopBase.template.json --query StackId --output text'
run 'aws cloudformation wait stack-create-complete --stack-name ShopBase'
run "aws cloudformation describe-stacks --stack-name ShopBase --query 'Stacks[0].[StackStatus,StackStatusReason]' --output text"
quiet 'aws cloudformation delete-stack --stack-name ShopBase'
quiet 'aws cloudformation wait stack-delete-complete --stack-name ShopBase'

block deploy
run 'aws ssm put-parameter --name /cdk-bootstrap/hnb659fds/version --type String --value 30 --query Version'
run 'aws cloudformation create-stack --stack-name ShopBase --template-body file://cdk.out/ShopBase.template.json --query StackId --output text'
run 'aws cloudformation wait stack-create-complete --stack-name ShopBase'
run "aws cloudformation describe-stacks --stack-name ShopBase --query 'Stacks[0].StackStatus' --output text"
run "aws cloudformation describe-stack-resources --stack-name ShopBase --query 'StackResources[].[LogicalResourceId,ResourceType]' --output text"

block test-pass
run "node --test 2>&1 | grep -E '^(ok|not ok|# (pass|fail))'"
block test-fail
run "sed -i 's/enforceSSL: true/enforceSSL: false/' app.js"
run "node --test 2>&1 | grep -E '^(ok|not ok|# (pass|fail))|^  error:|Template has'"
quiet "sed -i 's/enforceSSL: false/enforceSSL: true/' app.js"
