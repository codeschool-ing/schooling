#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of aws-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with moto empty. The September export is made by the first ```sh
# fence of on-upload.md, run as it stands, and year.py is read out of the
# example in a-terabyte-a-year.md, so neither has a second copy here.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran
# the whole sheet once, which is the first step lesson 1 asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1

block price-s3
run 'python3 prices.py s3'

bash -e <(fence "$HERE/on-upload.md" 1) || exit 1
block upload-classes
run 'aws s3 mb s3://quitanda-archive-prod'
run 'aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/standard.csv'
run 'aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/ia.csv --storage-class STANDARD_IA'
run 'aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/instant.csv --storage-class GLACIER_IR'
run 'aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/deep.csv --storage-class DEEP_ARCHIVE'
run 'aws s3api list-objects-v2 --bucket quitanda-archive-prod --query "Contents[].[Key,StorageClass,Size]" --output text'
run 'aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/ia.csv'
run 'aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv'

block upload-badclass
run 'aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/x.csv --storage-class INFREQUENT_ACCESS 2>&1 | head -2'

block archived-get
run 'aws s3 cp s3://quitanda-archive-prod/orders/2026-09/deep.csv back.csv'
run 'aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv back.csv'
run 'aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/instant.csv back.csv --query "[ContentLength,StorageClass]" --output text'

block restore
run 'aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv --restore-request "Days=2,GlacierJobParameters={Tier=Bulk}"'
run 'aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv --query "[StorageClass,Restore]"'
run 'aws s3api get-object --bucket quitanda-archive-prod --key orders/2026-09/deep.csv back.csv --query "[ContentLength,StorageClass]" --output text'
run 'aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/deep2.csv --storage-class DEEP_ARCHIVE'
run 'aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/deep2.csv --restore-request "Days=1,GlacierJobParameters={Tier=Expedited}"'
run 'aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --restore-request Days=1'
run 'aws s3api restore-object --bucket quitanda-archive-prod --key orders/2026-09/instant.csv --restore-request Days=1'

block class-change
run 'aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --query "[StorageClass,LastModified,ETag]"'
run 'aws s3 cp s3://quitanda-archive-prod/orders/2026-09/standard.csv s3://quitanda-archive-prod/orders/2026-09/standard.csv --storage-class GLACIER_IR'
run 'aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/standard.csv --query "[StorageClass,LastModified,ETag]"'

block int-tiering
run 'aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/auto.csv --storage-class INTELLIGENT_TIERING'
run 'aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/auto.csv --query StorageClass'
run "aws s3api put-bucket-intelligent-tiering-configuration --bucket quitanda-archive-prod --id archive-after-90 --intelligent-tiering-configuration 'Id=archive-after-90,Status=Enabled,Tierings=[{Days=90,AccessTier=ARCHIVE_ACCESS}]'"

example "$HERE/a-terabyte-a-year.md" year.py ~/aws/year.py || exit 1
block year
run 'python3 year.py'
