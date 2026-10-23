#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# One moto, empty and seeded, with checking off, kept running from "iaas" into
# "paas" as the prose says. app.py and confirm.zip are written by the first
# ```sh fence of "paas", run as it stands.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: commands
# that set nothing in the shell are run with `run`; the instance id the fixes
# name is the one run-instances printed, expanded into the command before it is
# printed.
#
# NOT PRODUCED HERE, and said so in the prose: AWS refusing a new function on a
# deprecated runtime (moto accepts python3.7); AWS's account-level IMDSv2
# default; a new machine from a current image and its patching; everything in
# "saas", which needs SaaS tenants this lab does not have.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
trap 'moto_stop; rm -f ~/aws/app.py ~/aws/confirm.zip' EXIT

# ---- iaas -------------------------------------------------------------------
block sg
run 'aws ec2 create-security-group --group-name booking-vm --description "booking system" --query GroupId --output text'

block open
run 'aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 0.0.0.0/0 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text'
run 'aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 443 --cidr 0.0.0.0/0 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text'

block launch
run 'aws ec2 run-instances --image-id ami-1e749f67 --instance-type t3.micro --security-groups booking-vm --query "Instances[0].InstanceId" --output text'
I=$(aws ec2 describe-instances --query "Reservations[0].Instances[0].InstanceId" --output text)

block image
run 'aws ec2 describe-images --image-ids ami-1e749f67 --query "Images[0].Description" --output text'

block world
run "aws ec2 describe-security-groups --group-names booking-vm --query \"SecurityGroups[0].IpPermissions[?IpRanges[?CidrIp=='0.0.0.0/0']].[FromPort,ToPort]\" --output text"

block imds
run 'aws ec2 describe-instances --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text'

block fix
run 'aws ec2 revoke-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return'
run 'aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 203.0.113.10/32 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text'
run "aws ec2 modify-instance-metadata-options --instance-id $I --http-tokens required --http-endpoint enabled --query InstanceMetadataOptions.HttpTokens --output text"

block again
run "aws ec2 describe-security-groups --group-names booking-vm --query \"SecurityGroups[0].IpPermissions[?IpRanges[?CidrIp=='0.0.0.0/0']].[FromPort,ToPort]\" --output text"
run 'aws ec2 describe-instances --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text'

# ---- paas -------------------------------------------------------------------
bash -e <(sh_fences "$HERE/paas.md" 1) || exit 1

block role
run "aws iam create-role --role-name booking-confirm --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}' --query Role.Arn --output text"

block function
run 'aws lambda create-function --function-name booking-confirm --runtime python3.7 --handler app.handler --role arn:aws:iam::123456789012:role/booking-confirm --zip-file fileb://confirm.zip --query "[FunctionName,Runtime,State]" --output text'

block inventory
run 'aws lambda list-functions --query "Functions[].[FunctionName,Runtime]" --output text'

block upgrade
run 'aws lambda update-function-configuration --function-name booking-confirm --runtime python3.12 --query "[FunctionName,Runtime]" --output text'
run 'aws lambda list-functions --query "Functions[].[FunctionName,Runtime]" --output text'
