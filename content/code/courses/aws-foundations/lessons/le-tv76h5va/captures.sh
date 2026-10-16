#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Recorded in the lab lesson 1 built, against an empty moto with no permission
# checking. trust-ec2.json, trust-checkout.json and token.py are read out of the
# lesson's own fences, so the files the capture uses are the ones the student
# saves; they are removed from ~/aws when the capture ends.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - a line that changes the shell (unset, export, TOKEN=..., source) is printed
#     with the prompt and then applied to this script's own shell, which is what
#     typing it at the prompt does; `run` alone would apply it to a child shell
#     and lose it;
#   - the first `aws configure list` is taken before anything is unset, with the
#     keys env.sh exports, as the student's terminal has them.
#
# MEASURED AND NOT QUOTED: the block `irsa-checked` restarts moto with
# INITIAL_NO_AUTH_ACTION_COUNT=3 and shows that the unsigned
# AssumeRoleWithWebIdentity then fails inside moto with HTTP 500 (its checking
# looks for an Authorization header). The prose reports it in a sentence.
#
# NOT PRODUCED HERE, and said so in the prose: anything on a real instance or
# cluster (the role's ARN as an EC2 session, a 401 from IMDSv2, the EKS service
# account, Pod Identity, an ECS agent), and modify-instance-metadata-defaults,
# whose companion get-instance-metadata-defaults answers 500 in moto 5.2.3.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
trap 'moto_stop; rm -f ~/aws/trust-ec2.json ~/aws/trust-checkout.json ~/aws/token.py ~/aws/token' EXIT

sets() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*"; }

fences json "$HERE/instance-profiles.md" 1 > ~/aws/trust-ec2.json || exit 1
fences json "$HERE/workload-roles.md" 1 > ~/aws/trust-checkout.json || exit 1
example "$HERE/workload-roles.md" token.py > ~/aws/token.py || exit 1

# ---- the-chain ---------------------------------------------------------------
block configure-env
run 'aws configure list'

block chain-order
sets 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY'
sets 'export AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/'
run 'aws sts get-caller-identity --debug 2>&1 | grep -oE "Looking for credentials via: .*|Found credentials .*|(PUT|GET) /latest[^ ]*"'

block imds-v1
run 'curl -s http://localhost:4567/latest/meta-data/iam/security-credentials/; echo'

block imds-v2
sets 'TOKEN=$(curl -s -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" http://localhost:4567/latest/api/token)'
export TOKEN
run 'echo $TOKEN'
run 'curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://localhost:4567/latest/meta-data/iam/security-credentials/default-role; echo'

block configure-imds
run 'aws configure list'
run 'aws sts get-caller-identity'

block back-to-env
sets 'source ~/aws/env.sh'
run 'aws configure list'

# ---- instance-profiles -------------------------------------------------------
block profile
run 'aws iam create-role --role-name shop-app --assume-role-policy-document file://trust-ec2.json --query Role.Arn --output text'
run 'aws iam attach-role-policy --role-name shop-app --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess'
run 'aws iam create-instance-profile --instance-profile-name shop-app --query InstanceProfile.Arn --output text'
run 'aws iam add-role-to-instance-profile --instance-profile-name shop-app --role-name shop-app'
run 'aws iam create-role --role-name shop-app-reports --assume-role-policy-document file://trust-ec2.json --query Role.Arn --output text'
run 'aws iam add-role-to-instance-profile --instance-profile-name shop-app --role-name shop-app-reports'

block launch
run 'aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.micro --iam-instance-profile Name=shop-app --metadata-options HttpTokens=required,HttpPutResponseHopLimit=1 --query "Instances[0].[InstanceId,IamInstanceProfile.Arn,MetadataOptions.[HttpTokens,HttpPutResponseHopLimit]]" --output text'
run 'aws ec2 describe-iam-instance-profile-associations --query "IamInstanceProfileAssociations[].[InstanceId,IamInstanceProfile.Arn,State]" --output text'
INSTANCE=$(aws ec2 describe-instances --query "Reservations[0].Instances[0].InstanceId" --output text)

block imds-notoken
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/latest/meta-data/iam/security-credentials/'

block image
run 'aws ec2 describe-images --image-ids ami-0629d059c178d0eac --query "Images[0].[Name,ImdsSupport]" --output text'

block hop-limit
run "aws ec2 modify-instance-metadata-options --instance-id $INSTANCE --http-tokens required --http-put-response-hop-limit 2"

# ---- workload-roles ----------------------------------------------------------
block oidc
run 'aws iam create-open-id-connect-provider --url https://oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE --client-id-list sts.amazonaws.com'

block checkout-role
run 'aws iam create-role --role-name shop-checkout --assume-role-policy-document file://trust-checkout.json --query Role.Arn --output text'
run 'aws iam attach-role-policy --role-name shop-checkout --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess'

block web-identity
run 'python3 token.py system:serviceaccount:shop:checkout > token'
sets 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY'
sets 'export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/shop-checkout AWS_WEB_IDENTITY_TOKEN_FILE=~/aws/token AWS_ROLE_SESSION_NAME=checkout-pod'
run 'aws configure list'
run 'aws sts get-caller-identity'

block web-identity-wrong
run 'python3 token.py system:serviceaccount:other:intruder > token'
run 'aws sts get-caller-identity --query Arn --output text'
run 'AWS_ROLE_ARN=arn:aws:iam::123456789012:role/no-such-role aws sts get-caller-identity --query Arn --output text'

block web-identity-direct
run 'aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/shop-checkout --role-session-name checkout-pod --web-identity-token file://token --no-sign-request --query "keys(@)" --output text'

block container
sets 'unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_SESSION_NAME'
run 'AWS_CONTAINER_CREDENTIALS_FULL_URI=http://localhost:4567/latest/meta-data/iam/security-credentials/default-role aws configure list'

# ---- measured, reported in a sentence ----------------------------------------
block irsa-checked
. ~/aws/env.sh
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
aws iam create-user --user-name admin > /dev/null
read -r K S < <(aws iam create-access-key --user-name admin --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)
aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
export AWS_ACCESS_KEY_ID=$K AWS_SECRET_ACCESS_KEY=$S
run 'aws iam create-open-id-connect-provider --url https://oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE --client-id-list sts.amazonaws.com --query OpenIDConnectProviderArn --output text'
run 'aws iam create-role --role-name shop-checkout --assume-role-policy-document file://trust-checkout.json --query Role.Arn --output text'
run 'python3 token.py system:serviceaccount:shop:checkout > token'
run 'aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/shop-checkout --role-session-name checkout-pod --web-identity-token file://token --no-sign-request --query AssumedRoleUser.Arn --output text'
