#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. reader.json and curated-policy.json are read out
# of the fences after their names, and the two ```sh fences a student types in
# who-may-read.md (the keys, and putting `test` back) are run from the lesson
# as they stand.
#
# STAGED, and why:
#   - moto is restarted with INITIAL_NO_AUTH_ACTION_COUNT=5 for "who-may-read",
#     as the student restarts it in the other terminal, and plain again after.
#   - /etc/hosts is a private copy for this run (a bind mount inside the run's
#     own mount namespace), so the line the lesson adds with sudo tee reaches
#     no other run and not the recording machine.
#   - the dashboard's secret key is read into a variable and never printed.
#   - presigned URLs carry the date and a signature that change on every run;
#     the prose quotes neither.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
C=quitanda-curated-prod

block presign-make
run "aws s3 mb s3://$C"
run "printf 'day,orders,total_cents\n2026-10-15,412,5108840\n' > daily.csv && aws s3 cp daily.csv s3://$C/reports/daily.csv"
run "aws s3 presign s3://$C/reports/daily.csv --expires-in 300"
U=$(aws s3 presign s3://$C/reports/daily.csv --expires-in 300)
run "curl -s '$U'"
run "aws s3 presign s3://$C/reports/daily.csv --expires-in 300 | tr '?&' '\n\n'"

block presign-nothing
run "aws s3 presign s3://$C/reports/no-such-report.csv"
U=$(aws s3 presign s3://$C/reports/no-such-report.csv)
run "curl -s -o /dev/null -w '%{http_code}\n' '$U'"

block presign-expiry
run "url=\$(aws s3 presign s3://$C/reports/daily.csv --expires-in 1); sleep 3; curl -s -w '%{http_code}\n' \"\$url\""
run "url=\$(aws s3 presign s3://$C/reports/daily.csv); curl -s -w '%{http_code}\n' \"\${url%?}x\""
run "aws s3 presign s3://$C/reports/daily.csv --expires-in 604801 | grep -o 'X-Amz-Expires=[0-9]*'"

moto_stop; moto_start INITIAL_NO_AUTH_ACTION_COUNT=5
file_fence "$HERE/who-may-read.md" reader.json > ~/aws/reader.json || exit 1
block iam-setup
run "aws s3 mb s3://$C"
run "aws s3 cp daily.csv s3://$C/reports/daily.csv"
run "aws iam create-user --user-name dashboard --query User.Arn --output text"
run "aws iam put-user-policy --user-name dashboard --policy-name read-reports --policy-document file://reader.json"
eval "$(fence "$HERE/who-may-read.md" 2)"
block iam-check
run "aws sts get-caller-identity --query Arn --output text"
run "aws s3 cp s3://$C/reports/daily.csv -"
run "aws s3 cp daily.csv s3://$C/reports/edited.csv"
run "aws s3 ls"
run "AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test aws s3 cp s3://$C/reports/daily.csv -"
block iam-sigbug
run "aws s3 ls s3://$C"
run "aws s3 ls s3://$C --recursive"
run "aws s3api list-objects-v2 --bucket $C --prefix reports/ --query 'Contents[].Key'"
run "aws s3api list-objects-v2 --bucket $C --prefix reports --query 'Contents[].Key'"
run "url=\$(aws s3 presign s3://$C/reports/daily.csv); curl -s -o /dev/null -w '%{http_code}\n' \"\$url\""
moto_stop; moto_start
eval "$(fence "$HERE/who-may-read.md" 3)"

block bpa-bucket
run "aws s3 mb s3://$C"
run "aws s3api get-public-access-block --bucket $C"
run "aws s3api put-public-access-block --bucket $C --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
run "aws s3api get-public-access-block --bucket $C"

cp /etc/hosts /tmp/hosts.lesson4 && mount --bind /tmp/hosts.lesson4 /etc/hosts || exit 1
block bpa-account
run "getent hosts 123456789012.localhost"
run "echo '127.0.0.1 123456789012.localhost' | sudo tee -a /etc/hosts"
run "getent hosts 123456789012.localhost"
run "aws s3control put-public-access-block --account-id 123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
run "aws s3control get-public-access-block --account-id 123456789012"

block bpa-ignored
run "aws s3 cp daily.csv s3://$C/reports/daily.csv"
run "aws s3api put-bucket-policy --bucket $C --policy '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::$C/*\"}]}'"
run "curl -s -w '%{http_code}\n' http://localhost:4567/$C/reports/daily.csv"
run "aws s3api delete-bucket-policy --bucket $C"

block ownership
run "aws s3api put-bucket-ownership-controls --bucket $C --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'"
run "aws s3api get-bucket-ownership-controls --bucket $C"
run "aws s3api put-object-acl --bucket $C --key reports/daily.csv --acl public-read"
run "aws s3api get-object-acl --bucket $C --key reports/daily.csv --query 'Grants[].[Grantee.URI,Permission]' --output text"

file_fence "$HERE/defender-policies.md" curated-policy.json > ~/aws/curated-policy.json || exit 1
block policy-put
run "aws s3api put-bucket-policy --bucket $C --policy file://curated-policy.json"
run "aws s3api get-bucket-policy --bucket $C --query Policy --output text | python3 -m json.tool | head -12"
run "aws s3 cp s3://$C/reports/daily.csv -"
block policy-reversed
run "aws s3api delete-bucket-policy --bucket $C"
run "jq '.Statement |= [.[0] | .Condition.Bool.\"aws:SecureTransport\" = \"true\"]' curated-policy.json > tls-true.json && jq -c .Statement[0].Condition tls-true.json"
run "aws s3api put-bucket-policy --bucket $C --policy file://tls-true.json"
run "aws s3 cp s3://$C/reports/daily.csv -"
run "aws s3api delete-bucket-policy --bucket $C"
run "aws s3 cp s3://$C/reports/daily.csv -"

L=quitanda-logs-prod
block leak-policy
run "aws s3 mb s3://$L"
run "printf '203.0.113.7 GET /checkout 200\n' > access.log && aws s3 cp access.log s3://$L/web/access.log"
run "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/$L/web/access.log"
run "aws s3api put-bucket-policy --bucket $L --policy '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::$L/*\"}]}'"
run "curl -s -w '%{http_code}\n' http://localhost:4567/$L/web/access.log"
run "aws s3api delete-bucket-policy --bucket $L"
run "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/$L/web/access.log"
umount /etc/hosts
