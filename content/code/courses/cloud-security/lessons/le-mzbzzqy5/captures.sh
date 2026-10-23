#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Only "one-control-three-ways" has transcripts: the AWS half of the clinic's
# control, against moto without its checking.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOT PRODUCED HERE, and said so in the prose: everything about Azure and
# Google Cloud; AWS's own default of Block Public Access on new buckets (moto
# has none); the account-level setting, which the CLI sends to
# 123456789012.localhost and so never reaches moto; the service control policy,
# which is shown as a document and not created (moto would store it and enforce
# nothing, and SCPs never apply to a management account anyway).
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh

block bucket
run 'aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api get-public-access-block --bucket clinic-records'

block switches
run 'aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
run 'aws s3api get-public-access-block --bucket clinic-records'

block account
run 'aws s3control put-public-access-block --account-id 123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
