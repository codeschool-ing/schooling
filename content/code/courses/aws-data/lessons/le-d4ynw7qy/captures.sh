#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. versions.py is read out of the example in
# what-versions-cost.md and lifecycle.json out of the fence after its name in
# life-cycle.md, so neither has a second copy here.
#
# STAGED: the small files written with echo before a command are written in
# the same command line the student sees. The version ids, the dates and the
# upload id are moto's and change on every run; the prose quotes none of them.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
B=quitanda-curated-prod

block versioning-on
run "aws s3 mb s3://$B"
run "aws s3api get-bucket-versioning --bucket $B"
run "aws s3api put-bucket-versioning --bucket $B --versioning-configuration Status=Enabled"
run "aws s3api get-bucket-versioning --bucket $B"

block versioning-two
run "printf 'customer_id,city\nc-17,Santos\n' > customers.csv && aws s3 cp customers.csv s3://$B/customers/customers.csv"
run "printf 'customer_id,city\nc-17,Campinas\n' > customers.csv && aws s3 cp customers.csv s3://$B/customers/customers.csv"
run "aws s3api list-object-versions --bucket $B --query 'Versions[].[VersionId,IsLatest,Size,LastModified]' --output text"
OLD=$(aws s3api list-object-versions --bucket $B --query 'Versions[?IsLatest==`false`].VersionId' --output text)
run "aws s3 cp s3://$B/customers/customers.csv -"
run "aws s3api get-object --bucket $B --key customers/customers.csv --version-id $OLD old.csv --query VersionId && cat old.csv"

block versioning-delete
run "aws s3 rm s3://$B/customers/customers.csv"
run "aws s3 ls s3://$B --recursive"
run "aws s3api get-object --bucket $B --key customers/customers.csv out.csv"
run "aws s3api list-object-versions --bucket $B --query '{versions: Versions[].[VersionId,IsLatest], markers: DeleteMarkers[].[VersionId,IsLatest]}'"

block versioning-undelete
DM=$(aws s3api list-object-versions --bucket $B --query 'DeleteMarkers[0].VersionId' --output text)
run "aws s3api delete-object --bucket $B --key customers/customers.csv --version-id $DM"
run "aws s3 cp s3://$B/customers/customers.csv -"

block versioning-suspend
run "aws s3api put-bucket-versioning --bucket $B --versioning-configuration Status=Suspended"
run "printf 'customer_id,city\nc-17,Sorocaba\n' > customers.csv && aws s3 cp customers.csv s3://$B/customers/customers.csv"
run "aws s3api list-object-versions --bucket $B --query 'Versions[].[VersionId,IsLatest,Size]' --output text"
run "aws s3api get-object --bucket $B --key customers/customers.csv --version-id $OLD old.csv --query VersionId"

example "$HERE/what-versions-cost.md" versions.py ~/aws/versions.py || exit 1
block versions-run
run 'python3 versions.py'

file_fence "$HERE/life-cycle.md" lifecycle.json > ~/aws/lifecycle.json || exit 1
R=quitanda-raw-prod
block lc-put
run "aws s3 mb s3://$R"
run "aws s3api put-bucket-lifecycle-configuration --bucket $R --lifecycle-configuration file://lifecycle.json"
run "aws s3api get-bucket-lifecycle-configuration --bucket $R --query '[TransitionDefaultMinimumObjectSize, Rules[].ID]'"

block lc-noclock
run "aws s3api put-bucket-lifecycle-configuration --bucket $R --lifecycle-configuration '{\"Rules\":[{\"ID\":\"at-once\",\"Status\":\"Enabled\",\"Filter\":{\"Prefix\":\"now/\"},\"Transitions\":[{\"Days\":0,\"StorageClass\":\"GLACIER\"}],\"Expiration\":{\"Days\":1}}]}'"
run "head -c 200000 /dev/urandom > big.bin && aws s3 cp big.bin s3://$R/now/big.bin"
run "sleep 5; aws s3api head-object --bucket $R --key now/big.bin --query '{class: StorageClass, expiration: Expiration}'"
run "aws s3api create-multipart-upload --bucket $R --key now/half.bin --query Key"
run "aws s3api list-multipart-uploads --bucket $R --query 'Uploads[].[Key,Initiated]' --output text"
run "aws s3 ls s3://$R --recursive"

block lc-loose
run "aws s3api put-bucket-lifecycle-configuration --bucket $R --lifecycle-configuration '{\"Rules\":[{\"ID\":\"too-soon\",\"Status\":\"Enabled\",\"Filter\":{\"Prefix\":\"raw/\"},\"Transitions\":[{\"Days\":10,\"StorageClass\":\"STANDARD_IA\"}]}]}'"
run "aws s3api get-bucket-lifecycle-configuration --bucket $R --query 'Rules[].Transitions'"

A=quitanda-archive-prod
block lock-create
run "aws s3api create-bucket --bucket $A --create-bucket-configuration LocationConstraint=sa-east-1 --object-lock-enabled-for-bucket"
run "aws s3api get-bucket-versioning --bucket $A"
run "aws s3api get-object-lock-configuration --bucket $A"

block lock-default
run "aws s3api put-object-lock-configuration --bucket $A --object-lock-configuration '{\"ObjectLockEnabled\":\"Enabled\",\"Rule\":{\"DefaultRetention\":{\"Mode\":\"COMPLIANCE\",\"Years\":1}}}'"
run "aws s3api get-object-lock-configuration --bucket $A"

block lock-compliance
run "printf 'invoice,total_cents\nnf-2026-10-0001,4590\n' > nf.csv && aws s3api put-object --bucket $A --key invoices/2026-10/nf.csv --body nf.csv --query VersionId --output text"
V=$(aws s3api head-object --bucket $A --key invoices/2026-10/nf.csv --query VersionId --output text)
run "aws s3api head-object --bucket $A --key invoices/2026-10/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'"
run "aws s3api delete-object --bucket $A --key invoices/2026-10/nf.csv --version-id $V"
run "aws s3api delete-object --bucket $A --key invoices/2026-10/nf.csv"
run "aws s3api list-object-versions --bucket $A --query '{versions: Versions[].[VersionId,IsLatest], markers: DeleteMarkers[].[VersionId,IsLatest]}'"

block lock-governance
run "aws s3api put-object --bucket $A --key drafts/nf-draft.csv --body nf.csv --object-lock-mode GOVERNANCE --object-lock-retain-until-date 2026-11-16T00:00:00Z --query VersionId --output text"
G=$(aws s3api head-object --bucket $A --key drafts/nf-draft.csv --query VersionId --output text)
run "aws s3api head-object --bucket $A --key drafts/nf-draft.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'"
run "aws s3api delete-object --bucket $A --key drafts/nf-draft.csv --version-id $G"
run "aws s3api delete-object --bucket $A --key drafts/nf-draft.csv --version-id $G --bypass-governance-retention"

block lock-hold
run "aws s3api put-object --bucket $A --key disputes/c-17/order.csv --body nf.csv --object-lock-mode GOVERNANCE --object-lock-retain-until-date 2026-10-17T00:00:00Z --query VersionId --output text"
H=$(aws s3api head-object --bucket $A --key disputes/c-17/order.csv --query VersionId --output text)
run "aws s3api put-object-legal-hold --bucket $A --key disputes/c-17/order.csv --version-id $H --legal-hold Status=ON"
run "aws s3api get-object-legal-hold --bucket $A --key disputes/c-17/order.csv --version-id $H"
run "aws s3api delete-object --bucket $A --key disputes/c-17/order.csv --version-id $H --bypass-governance-retention"
run "aws s3api get-object-retention --bucket $A --key disputes/c-17/order.csv --version-id $H"

block weak-compliance
run "aws s3api put-object --bucket $A --key invoices/2026-09/nf.csv --body nf.csv --object-lock-mode COMPLIANCE --object-lock-retain-until-date 2027-10-16T00:00:00Z --query VersionId --output text"
W=$(aws s3api head-object --bucket $A --key invoices/2026-09/nf.csv --query VersionId --output text)
run "aws s3api head-object --bucket $A --key invoices/2026-09/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'"
run "aws s3api put-object-retention --bucket $A --key invoices/2026-09/nf.csv --version-id $W --retention Mode=GOVERNANCE,RetainUntilDate=2026-10-17T00:00:00Z"
run "aws s3api head-object --bucket $A --key invoices/2026-09/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'"
run "aws s3api delete-object --bucket $A --key invoices/2026-09/nf.csv --version-id $W --bypass-governance-retention"
run "aws s3api list-object-versions --bucket $A --prefix invoices/2026-09/ --query 'Versions'"

block weak-suspend
run "aws s3api put-bucket-versioning --bucket $A --versioning-configuration Status=Suspended"
run "aws s3api get-bucket-versioning --bucket $A"
run "aws s3api put-object --bucket $A --key invoices/2026-11/nf.csv --body nf.csv --query VersionId --output text"
run "aws s3api put-object --bucket $A --key invoices/2026-12/nf.csv --body nf.csv --query VersionId --output text"
