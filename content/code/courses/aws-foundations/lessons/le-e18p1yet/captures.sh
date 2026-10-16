#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the account id moto gives shop-prod is read from moto and put into the
#     commands that name it, so the prose and the capture agree on the number
#     whatever the seed produces;
#   - the profile the lesson writes goes into the lab's ~/.aws/config, which is
#     removed again at the end with the AWS CLI's cache of assumed-role
#     credentials, so no other lesson's capture inherits either.
#
# NOT PRODUCED HERE, and said so in the prose: the refusal of a sixth VPC, which
# moto does not count, and everything about real accounts' root users and
# e-mail addresses, which needs AWS.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
cleanup() { rm -f ~/.aws/config; rm -rf ~/.aws/cli/cache; }
cleanup
trap 'moto_stop; cleanup' EXIT

# ---- what-an-account-holds ---------------------------------------------------
block whoami
run 'aws sts get-caller-identity'
run 'aws sns create-topic --name shop-alerts'
run 'aws iam create-user --user-name bia --query User.Arn --output text'

block quota
run 'aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE --query "Quota.[QuotaName,Value,Adjustable,GlobalQuota]" --output text'
run 'aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text'
run 'for n in 1 2 3 4 5; do aws ec2 create-vpc --cidr-block 10.$n.0.0/16 --query Vpc.VpcId --output text; done'
run 'aws ec2 describe-vpcs --query "length(Vpcs)"'

# ---- a-second-account --------------------------------------------------------
block organization
run 'aws organizations create-organization --query "Organization.[Id,MasterAccountId]" --output text'
run 'aws organizations create-account --email aws+shop-prod@example.com --account-name shop-prod --query "CreateAccountStatus.[State,AccountId]" --output text'
run 'aws organizations list-accounts --query "Accounts[].[Id,Name,Email]" --output text'
PROD=$(aws organizations list-accounts --query "Accounts[?Name=='shop-prod'].Id" --output text)

block profile
run "aws configure set profile.shop-prod.role_arn arn:aws:iam::$PROD:role/OrganizationAccountAccessRole"
run 'aws configure set profile.shop-prod.credential_source Environment'
run 'aws configure set profile.shop-prod.role_session_name ana'
run 'cat ~/.aws/config'
run 'aws --profile shop-prod sts get-caller-identity'

block apart
run 'aws --profile shop-prod ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault,OwnerId]" --output text'
run 'aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[].[VpcId,CidrBlock,IsDefault,OwnerId]" --output text'
run 'aws --profile shop-prod sns list-topics --query "Topics[].TopicArn"'
run 'aws --profile shop-prod iam list-users --query "Users[].UserName"'

block bucket
run 'aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1'
run 'aws --profile shop-prod s3api list-buckets --query "Buckets[].Name"'
run 'aws --profile shop-prod s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1'
run 'aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1'
run "aws --profile shop-prod s3api create-bucket --bucket $PROD-shop-assets --create-bucket-configuration LocationConstraint=sa-east-1"
