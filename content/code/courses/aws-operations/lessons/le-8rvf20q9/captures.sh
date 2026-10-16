#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# Two moto servers, one after the other: an open one for the first sections,
# then one started with INITIAL_NO_AUTH_ACTION_COUNT for the section on
# access. STAGED: the count is 10 here and 9 in the lesson, because moto_up's
# readiness check is a request too and moto counts it. The access
# keys moto issues are read into variables and never printed. dbconfig.py,
# cache-demo.py and the policies are read out of the lesson.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf secrets && mkdir secrets && cd secrets || exit 1
moto_up
student_env

block params
run "aws ssm put-parameter --name /shop/prod/db/host --type String --value db.internal --query '[Version,Tier]' --output text"
run "aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value first-pass --query '[Version,Tier]' --output text"
run "aws ssm get-parameter --name /shop/prod/db/password --query 'Parameter.[Type,Value]' --output text"
run "aws ssm get-parameter --name /shop/prod/db/password --with-decryption --query Parameter.Value --output text"
block params-path
run "aws ssm get-parameters-by-path --path /shop/prod --recursive --with-decryption --query 'Parameters[].[Name,Type,Version]' --output text"
block params-overwrite
run 'aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value second-pass'
run "aws ssm put-parameter --name /shop/prod/db/password --type SecureString --value second-pass --overwrite --query Version"
run "aws ssm get-parameter-history --name /shop/prod/db/password --query 'Parameters[].[Version,LastModifiedDate]' --output text"
block params-size
run 'aws ssm put-parameter --name /shop/prod/too-big --type String --value "$(printf "%5000s" | tr " " x)" --query Tier'

block secret
run "aws secretsmanager create-secret --name shop/prod/db --secret-string '{\"username\":\"shop\",\"password\":\"first-pass\"}' --query ARN --output text"
run "aws secretsmanager get-secret-value --secret-id shop/prod/db --query '[SecretString,VersionStages[0]]' --output text"
block secret-versions
run "aws secretsmanager put-secret-value --secret-id shop/prod/db --secret-string '{\"username\":\"shop\",\"password\":\"second-pass\"}' --query VersionStages"
run "aws secretsmanager list-secret-version-ids --secret-id shop/prod/db --query 'Versions[].[VersionId,VersionStages[0]]' --output text"
run "aws secretsmanager get-secret-value --secret-id shop/prod/db --version-stage AWSPREVIOUS --query SecretString --output text"
block secret-random
run 'aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text'
block secret-rotate
run 'aws secretsmanager create-secret --name shop/prod/smtp --secret-string smtp-pass --query Name'
run 'aws secretsmanager rotate-secret --secret-id shop/prod/smtp --rotation-rules AutomaticallyAfterDays=30 --query Name'
run 'aws secretsmanager get-secret-value --secret-id shop/prod/smtp --query SecretString'
block secret-delete
run "aws secretsmanager delete-secret --secret-id shop/prod/smtp --query DeletionDate --output text"
run 'aws secretsmanager get-secret-value --secret-id shop/prod/smtp 2>&1 | tail -1'
run 'aws secretsmanager restore-secret --secret-id shop/prod/smtp --query Name'

block reading
from_lesson "$HERE/reading.md" dbconfig.py > dbconfig.py
from_lesson "$HERE/reading.md" cache-demo.py > cache-demo.py
run 'python3 cache-demo.py'

block prices
cd "$HOME/aws" || exit 1
run 'python3 price.py AWSSecretsManager'
run 'python3 price.py AWSSystemsManager Parameter'

cd "$HOME/aws/secrets" || exit 1
from_lesson "$HERE/access.md" app-policy.json > app-policy.json
from_lesson "$HERE/access.md" wide-policy.json > wide-policy.json
moto_up INITIAL_NO_AUTH_ACTION_COUNT=10
fence "$HERE/access.md" 2
block access
run 'read -r KEY SECRET < <(aws iam create-access-key --user-name shop-app --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)'
run 'read -r WKEY WSECRET < <(aws iam create-access-key --user-name shop-wide --query "AccessKey.[AccessKeyId,SecretAccessKey]" --output text)'
block access-app
run 'AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws sts get-caller-identity --query Arn'
run 'AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws ssm get-parameter --name /shop/prod/db/host 2>&1 | grep -o "User: [^<]*"'
run 'AWS_ACCESS_KEY_ID=$KEY AWS_SECRET_ACCESS_KEY=$SECRET aws secretsmanager get-secret-value --secret-id shop/prod/db 2>&1 | grep -o "User: [^<]*"'
block access-wide
run 'AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager get-secret-value --secret-id shop/prod/db --query Name'
run 'AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager get-secret-value --secret-id shop/prod/payments --query Name'
run 'AWS_ACCESS_KEY_ID=$WKEY AWS_SECRET_ACCESS_KEY=$WSECRET aws secretsmanager put-secret-value --secret-id shop/prod/db --secret-string x 2>&1 | grep -o "User: [^<]*"'
block access-test
run 'aws secretsmanager list-secrets 2>&1 | grep -o "<Message>[^<]*"'
