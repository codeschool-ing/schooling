#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# One moto for the whole lesson, started empty and seeded, checking off. The
# files the student writes come from the lesson's own fences:
# referral-0412.txt and report-2026-09.csv are the ```sh fences 1 and 2 of
# "how-a-bucket-goes-public", public_buckets.py is the example of
# "finding-every-bucket".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the files the lesson asks the student to save are written from its
#     fences, and removed at the end.
#
# NOT PRODUCED HERE, and said so in the prose: anything Block Public Access or
# BucketOwnerEnforced would do on AWS (moto stores both and enforces neither:
# the public letter is still served and a public ACL is still accepted with
# all four switches on); the account-level switches (the CLI sends S3 Control
# to <account-id>.localhost, which does not answer); an anonymous listing,
# because moto lists even a private bucket to an unsigned request; a signed
# request from another AWS account against AuthenticatedUsers; CloudFront with
# an origin access control. The incidents in "a-decade" are from UpGuard's
# published reports and AWS's announcements.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
G="$HERE/how-a-bucket-goes-public.md"

FILES='referral-0412.txt report-2026-09.csv public_buckets.py'
moto_fresh
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT
bash -e <(sh_fences "$G" 1) || exit 1
bash -e <(sh_fences "$G" 2) || exit 1
example "$HERE/finding-every-bucket.md" public_buckets.py > public_buckets.py || exit 1

# ---- how-a-bucket-goes-public ---------------------------------------------------
block object-acl
run 'aws s3api create-bucket --bucket clinic-referrals --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-object --bucket clinic-referrals --key referral-0412.txt --body referral-0412.txt --acl public-read --query ETag --output text'
run 'curl -s -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt'

block object-acl-read
run 'aws s3api get-object-acl --bucket clinic-referrals --key referral-0412.txt --query "Grants[].[Grantee.URI,Permission]" --output text'
run 'aws s3api get-bucket-policy --bucket clinic-referrals'

block bucket-acl
run 'aws s3api put-bucket-acl --bucket clinic-referrals --acl public-read'
run 'aws s3api get-bucket-acl --bucket clinic-referrals --query "Grants[].[Grantee.URI,Permission]" --output text'

block authenticated
run 'aws s3api create-bucket --bucket clinic-reports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-object --bucket clinic-reports --key report-2026-09.csv --body report-2026-09.csv --acl authenticated-read --query ETag --output text'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-reports/report-2026-09.csv'
run 'aws s3api get-object-acl --bucket clinic-reports --key report-2026-09.csv --query "Grants[].[Grantee.URI,Permission]" --output text'

block bucket-acl-private
run 'aws s3api put-bucket-acl --bucket clinic-referrals --acl private'
run 'aws s3api get-bucket-acl --bucket clinic-referrals --query "Grants[].[Grantee.URI,Permission]" --output text'

# ---- block-public-access ----------------------------------------------------------
block bpa
run 'aws s3api put-public-access-block --bucket clinic-referrals --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
run 'aws s3api get-public-access-block --bucket clinic-referrals'

block bpa-test
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt'
run 'aws s3api put-object-acl --bucket clinic-referrals --key referral-0412.txt --acl public-read'
run 'aws s3api get-object-acl --bucket clinic-referrals --key referral-0412.txt --query "Grants[].[Grantee.URI,Permission]" --output text'

# ---- finding-every-bucket ---------------------------------------------------------
block records
run 'aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
run 'aws s3api put-object --bucket clinic-records --key referrals/referral-0412.txt --body referral-0412.txt --query ETag --output text'

block checker
run 'python3 public_buckets.py'

# ---- the-fix-and-the-proof --------------------------------------------------------
block revoke
run 'aws s3api put-object-acl --bucket clinic-referrals --key referral-0412.txt --acl private'
run 'aws s3api put-object-acl --bucket clinic-reports --key report-2026-09.csv --acl private'

block guard
run 'aws s3api put-public-access-block --bucket clinic-reports --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'
run 'for b in clinic-referrals clinic-reports clinic-records; do aws s3api put-bucket-ownership-controls --bucket "$b" --ownership-controls "Rules=[{ObjectOwnership=BucketOwnerEnforced}]"; done'

block proof
run 'python3 public_buckets.py'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt'
