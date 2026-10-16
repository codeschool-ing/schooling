#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of aws-compute (user data, instance
# metadata and IMDSv2), as a script that produces them. THE SCRIPT IS THE
# SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-xmntxg8j/captures.sh
#
# Every block runs against an empty moto 5.2.3 on localhost:4567, in the
# environment lesson 1's `your-lab` builds. NOTHING HERE BOOTS A MACHINE: an
# instance is a record moto keeps, so the user data is stored and read back and
# never run, and no metadata service answers from inside any instance.
#
# What moto's metadata answers are: moto serves a few metadata paths on its own
# port (/latest/meta-data/..., /latest/api/token) for SDKs under test. They are
# fixed placeholders (i-fake, us-east-1a, default-role, fake-imdsv2-token),
# shared by every "instance", and they check no token. The lesson says so where
# it quotes them.
#
# What is STAGED rather than typed:
#   - first-boot.sh is read out of the schooling-example in `user-data`, the
#     file the student copies with the block's button;
#   - `sdk-chain` runs the CLI with the two credential variables removed and
#     AWS_EC2_METADATA_SERVICE_ENDPOINT pointed at moto, which is how the
#     section shows it; the student types the same `env -u ...` line.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/user-data.md" first-boot.sh > first-boot.sh

block launch
run 'AMI=$(aws ec2 describe-images --owners amazon --filters Name=name,Values=al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64 --query "Images[0].ImageId" --output text)'
run 'echo "$AMI"'
run 'ID=$(aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --user-data file://first-boot.sh --query "Instances[0].InstanceId" --output text)'
run 'echo "$ID"'

block read-back
run 'aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | cut -c1-60'
run 'aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | base64 -d | head -4'
run 'wc -c < first-boot.sh'
run 'base64 -w0 first-boot.sh | wc -c'

block too-big
run 'yes "echo padding" | head -c 20000 > big.sh'
run 'aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --user-data file://big.sh --query "Instances[0].State.Name" --output text'

block modify-running
run 'printf "#!/bin/bash\necho changed\n" > second.sh'
run 'aws ec2 modify-instance-attribute --instance-id "$ID" --attribute userData --value "$(base64 -w0 second.sh)"'
run 'aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].State.Name" --output text'
run 'aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | base64 -d'

block metadata
run 'curl -s localhost:4567/latest/meta-data/; echo'
run 'curl -s localhost:4567/latest/meta-data/instance-id; echo'
run 'curl -s localhost:4567/latest/meta-data/placement/availability-zone; echo'
run 'curl -s localhost:4567/latest/meta-data/iam/security-credentials/; echo'
run 'curl -s localhost:4567/latest/meta-data/iam/security-credentials/default-role; echo'

block sdk-chain
run 'env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/ aws configure list'
run 'env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/ aws sts get-caller-identity --debug 2>&1 | grep -E "\"(PUT|GET) /latest|Found credentials" | sed "s/^.* - //"'

block token
run 'TOKEN=$(curl -s -X PUT localhost:4567/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 300")'
run 'echo "$TOKEN"'
run 'curl -s -H "X-aws-ec2-metadata-token: $TOKEN" localhost:4567/latest/meta-data/iam/security-credentials/; echo'
run 'curl -s -H "X-aws-ec2-metadata-token: not-a-token" localhost:4567/latest/meta-data/iam/security-credentials/; echo'

block enforce-launch
run 'aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --metadata-options HttpTokens=required,HttpPutResponseHopLimit=1,HttpEndpoint=enabled --query "Instances[0].[InstanceId,MetadataOptions]"'

block enforce-running
run 'OLD=$(aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --query "Instances[0].InstanceId" --output text)'
run 'aws ec2 describe-instances --instance-ids "$OLD" --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text'
run 'aws ec2 modify-instance-metadata-options --instance-id "$OLD" --http-tokens required --http-endpoint enabled'

block enforce-template
run 'aws ec2 create-launch-template --launch-template-name web --launch-template-data "{\"ImageId\":\"$AMI\",\"InstanceType\":\"t3.micro\",\"MetadataOptions\":{\"HttpTokens\":\"required\",\"HttpPutResponseHopLimit\":1}}" --query LaunchTemplate.LatestVersionNumber'
run 'aws ec2 describe-launch-template-versions --launch-template-name web --query "LaunchTemplateVersions[0].LaunchTemplateData.MetadataOptions"'

block ami-flag
run 'aws ec2 describe-images --image-ids "$AMI" --query "Images[0].[Name,ImdsSupport]" --output text'

block account-default
run 'aws ec2 modify-instance-metadata-defaults --http-tokens required 2>&1 | head -3 | cut -c1-100'

block lenient
run 'aws ec2 modify-instance-metadata-options --instance-id "$OLD" --http-put-response-hop-limit 65 --http-tokens sometimes'
