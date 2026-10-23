#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# One moto, empty and seeded, with checking off: this lesson reads settings
# back and is about nobody's permission.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOT PRODUCED HERE, and said so in the prose: AWS's 2023 defaults (SSE-S3 on
# every new object, Block Public Access and BucketOwnerEnforced on every new
# bucket), which moto 5.2.3 does not apply; AWS Artifact and every compliance
# report, which need an AWS account; the incidents of "where-it-breaks".
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh

block create
run 'aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'

block before
run 'aws s3api get-bucket-encryption --bucket clinic-records'
run 'aws s3api get-public-access-block --bucket clinic-records'
run 'aws s3api get-bucket-ownership-controls --bucket clinic-records'
run 'aws s3api get-bucket-versioning --bucket clinic-records'

block set
run "aws s3api put-bucket-encryption --bucket clinic-records --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}'"
run 'aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
run "aws s3api put-bucket-ownership-controls --bucket clinic-records --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'"
run 'aws s3api put-bucket-versioning --bucket clinic-records --versioning-configuration Status=Enabled'

block after
run 'aws s3api get-bucket-encryption --bucket clinic-records --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault"'
run 'aws s3api get-public-access-block --bucket clinic-records'
run 'aws s3api get-bucket-ownership-controls --bucket clinic-records --query "OwnershipControls.Rules[0].ObjectOwnership" --output text'
run 'aws s3api get-bucket-versioning --bucket clinic-records --query Status --output text'
