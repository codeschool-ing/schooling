#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of aws-compute (IRSA), as a script
# that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-437cf4d3/captures.sh            # every section but one
#   LAB_MOTO_ENV='INITIAL_NO_AUTH_ACTION_COUNT=6' \
#     bash lessons/le-437cf4d3/captures.sh denial   # the-exchange, the denial
#
# There is no AWS account and no Kubernetes cluster here. moto records the
# cluster and answers its OIDC issuer; nothing serves that issuer, nothing signs
# a token and no pod runs. The tokens are made by mktoken.py, which the lesson
# shows whole and calls unsigned, and moto accepts them because it reads none.
#
# What is STAGED rather than typed:
#   - ~/.aws is a private directory for this run: the command line keeps the credentials of a role it
#     assumed in ~/.aws/cli/cache, and a cache left by an earlier run against
#     an earlier moto would answer instead of this one. A student running this
#     the first time has none;
#   - agent.py runs in the background, where the student runs it in a second
#     terminal; its output is printed afterwards as that terminal's;
#   - `denial` starts from an empty moto, so trust.json and token
#     are written quietly first, from the same example and program the lesson
#     shows, with a fixed issuer (moto does not read either). The lab's
#     readiness probe is one request to moto, so the count is 6 here where the
#     student, who sends no probe, uses 5.
#
# moto invents the cluster's issuer id, the role ids and every date, so a
# second run prints different ones.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

A=$(mktemp -d /tmp/aws-capture.XXXXXX)
mount --bind "$A" /home/ana/.aws
cd /home/ana/aws || exit 1

# nth_example MD N: the code of the Nth schooling-example of MD, counted from 1
nth_example() {
  python3 - "$1" "$2" <<'PY'
import json, re, sys
blocks = re.findall(r'^```schooling-example\n(.*?)\n```$', open(sys.argv[1]).read(), re.S | re.M)
sys.stdout.write(''.join(p['code'] for p in json.loads(blocks[int(sys.argv[2]) - 1])['parts']))
PY
}

from_lesson "$HERE/the-exchange.md" mktoken.py > mktoken.py

if [ "${1:-}" = denial ]; then
  quiet 'ISSUER=https://oidc.eks.sa-east-1.amazonaws.com/id/EXAMPLE'
  quiet "$(nth_example "$HERE/oidc-and-trust.md" 1)"
  quiet 'python3 mktoken.py "$ISSUER" > token'
  block denial
  run 'printf "hi\n" > photo.jpg'
  run 'aws s3api create-bucket --bucket shop-photos-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1 --query Location'
  run 'aws s3api put-object --bucket shop-photos-123456789012 --key cat.jpg --body photo.jpg --query ETag'
  run 'aws iam create-role --role-name photos-reader --assume-role-policy-document file://trust.json --query Role.Arn'
  run "aws iam put-role-policy --role-name photos-reader --policy-name read-photos --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::shop-photos-123456789012/*\"}]}'"
  run 'read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN < <(aws sts assume-role-with-web-identity --role-arn arn:aws:iam::123456789012:role/photos-reader --role-session-name photos-pod --web-identity-token file://token --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text)'
  run 'export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN'
  run 'aws sts get-caller-identity --query Arn'
  run 'aws s3api get-object --bucket shop-photos-123456789012 --key cat.jpg cat.jpg --query ContentLength'
  run 'aws s3api put-object --bucket shop-photos-123456789012 --key dog.jpg --body photo.jpg'
  exit 0
fi

block static-key
run 'aws iam create-user --user-name shop-app --query User.Arn'
run 'aws iam create-access-key --user-name shop-app --query "AccessKey.[Status,CreateDate]" --output text'
run 'aws iam list-access-keys --user-name shop-app --query "AccessKeyMetadata[0]" | grep -v AccessKeyId'
run 'aws sts get-session-token --query "Credentials.Expiration"'

block secret
from_lesson "$HERE/the-static-key.md" secret.yaml > secret.yaml
run 'grep SECRET secret.yaml'
run "grep SECRET secret.yaml | awk '{print \$2}' | base64 -d; echo"

block issuer
run 'aws eks create-cluster --name shop --role-arn arn:aws:iam::123456789012:role/shop-cluster --resources-vpc-config subnetIds=subnet-0a1,subnet-0b2 --query cluster.identity'
run 'ISSUER=$(aws eks describe-cluster --name shop --query cluster.identity.oidc.issuer --output text)'
run 'aws iam create-open-id-connect-provider --url "$ISSUER" --client-id-list sts.amazonaws.com'

block trust-cat
quiet "$(nth_example "$HERE/oidc-and-trust.md" 1)"
run 'cat trust.json'
block trust-role
run 'aws iam create-role --role-name photos-reader --assume-role-policy-document file://trust.json --query Role.Arn'
run "aws iam put-role-policy --role-name photos-reader --policy-name read-photos --policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::shop-photos-123456789012/*\"}]}'"

block exchange
run 'python3 mktoken.py "$ISSUER" > token'
run 'export AWS_ROLE_ARN=arn:aws:iam::123456789012:role/photos-reader'
run 'export AWS_WEB_IDENTITY_TOKEN_FILE=~/aws/token AWS_ROLE_SESSION_NAME=photos-pod'
run 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY'
run 'aws sts get-caller-identity'

block moto-accepts
run 'echo not-a-token > token'
run 'rm -rf ~/.aws/cli/cache'
run 'aws sts get-caller-identity --query Arn'
run 'AWS_ROLE_ARN=arn:aws:iam::123456789012:role/no-such-role aws sts get-caller-identity --query Arn'

block back
run 'unset AWS_ROLE_ARN AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_SESSION_NAME'
run 'export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test'

block pod-identity
from_example "$HERE/pod-identity.md" pod-trust.json > pod-trust.json
run 'aws iam create-role --role-name photos-pod-identity --assume-role-policy-document file://pod-trust.json --query Role.Arn'
run 'aws eks create-pod-identity-association --cluster-name shop --namespace shop --service-account photos --role-arn arn:aws:iam::123456789012:role/photos-pod-identity'

block agent
from_example "$HERE/pod-identity.md" agent.py > agent.py
quiet 'setsid python3 agent.py > agent.log 2>&1 < /dev/null & echo $! > agent.pid; sleep 2'
run 'python3 mktoken.py "$ISSUER" pods.eks.amazonaws.com > pod-token'
run 'export AWS_CONTAINER_CREDENTIALS_FULL_URI=http://127.0.0.1:8099/v1/credentials'
run 'export AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=~/aws/pod-token'
run 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY'
run 'aws sts get-caller-identity'
block agent-terminal
cat agent.log
quiet 'kill "$(cat agent.pid)"'
