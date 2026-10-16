#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of aws-foundations (CloudFront), as
# a script that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Read out of the lesson: the setup is the ```sh fence of
# "distributions-and-origins", distribution.json and assets-policy.json are its
# two ```json fences. per-million.py is lesson 21's (le-yprxwe78,
# "routing-policies", its ```python fence), which this lesson reuses.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types everything into ONE shell, where `id=...` stays set.
#     Here each command runs in a shell of its own, so the assignment is printed
#     with its prompt, run once in this script's shell and exported;
#   - distribution.json names the OAC and assets-policy.json the distribution
#     by the ids moto gave them in this recording; the lesson tells the student
#     to put their own. The script checks that the ids are still the ones the
#     fences carry, and stops if they are not;
#   - the files the lesson saves in ~/aws are removed at the end.
#
# ONE COMMAND REACHES AWS, with no key: price.py downloads the public price
# list. moto has no edges, so nothing here is a request through CloudFront.
#
# NOT PRODUCED HERE, and said so in the prose: a request through the
# distribution, a cache hit or miss, an invalidation clearing anything, OAC
# refusing a direct read, a certificate being validated, signed URLs, geo
# restriction or WAF doing anything.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L21="$HERE/../le-yprxwe78/routing-policies.md"
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
trap 'moto_stop; rm -f ~/aws/distribution.json ~/aws/assets-policy.json ~/aws/per-million.py' EXIT

assign() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$1"; eval "export $1"; }
SRC="$HERE/distributions-and-origins.md"

# ---- distributions-and-origins -----------------------------------------------
# shellcheck disable=SC1090
. <(sh_fences "$SRC" 1)
cd ~/aws || exit 1

block oac
run 'aws cloudfront create-origin-access-control --origin-access-control-config Name=shop-assets-oac,SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3'

fences json "$SRC" 1 > ~/aws/distribution.json || exit 1
oac=$(aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[0].Id" --output text)
grep -q "\"$oac\"" ~/aws/distribution.json || { echo "the OAC is $oac now: change distribution.json"; exit 1; }

block create
run 'aws cloudfront create-distribution --distribution-config file://distribution.json --query "[Location,Distribution.Id,Distribution.DomainName,Distribution.Status]" --output text'

block id
assign 'id=$(aws cloudfront list-distributions --query "DistributionList.Items[0].Id" --output text)'

block origins
run 'aws cloudfront get-distribution --id $id --query "Distribution.DistributionConfig.Origins.Items[].[Id,DomainName,OriginAccessControlId]" --output text'

fences json "$SRC" 2 > ~/aws/assets-policy.json || exit 1
grep -q "distribution/$id\"" ~/aws/assets-policy.json || { echo "the distribution is $id now: change assets-policy.json"; exit 1; }
block policy
run 'aws s3api put-bucket-policy --bucket shop-assets --policy file://assets-policy.json'

block global
run 'aws cloudfront list-distributions --region ap-southeast-2 --query "DistributionList.Items[].[Id,DomainName]" --output text'

block cert
run 'aws acm request-certificate --domain-name cdn.shop.example.com --validation-method DNS --region us-east-1 --query CertificateArn --output text'
run 'aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[].DomainName" --output text'
run 'aws acm list-certificates --query "CertificateSummaryList[].DomainName" --output text'

# ---- caching-and-invalidation ------------------------------------------------
block cache-policies
run 'aws cloudfront list-cache-policies --type managed'

block behaviours
run 'aws cloudfront get-distribution-config --id $id --query "DistributionConfig.CacheBehaviors.Items[].[PathPattern,TargetOriginId,CachePolicyId,Compress]" --output text'

block invalidate
run 'aws cloudfront create-invalidation --distribution-id $id --paths "/static/css/shop.css" "/static/js/*"'

block invalidations
run 'aws cloudfront list-invalidations --distribution-id $id --query "InvalidationList.Items[].[Id,Status]" --output text'

# ---- price-and-protection ----------------------------------------------------
rm -f ~/.cache/aws-prices/AmazonCloudFront-*
block price-cf
run 'python3 price.py AmazonCloudFront 20260916132208 aws-other SA-DataTransfer-Out-Bytes US-DataTransfer-Out-Bytes Invalidations'

fences python "$L21" 1 > ~/aws/per-million.py || exit 1
block requests
run 'python3 per-million.py AmazonCloudFront 20260916132208 aws-other SA-Requests-Tier2-HTTPS US-Requests-Tier2-HTTPS'

block price-dt
run 'python3 price.py AWSDataTransfer 20260916132208 sa-east-1 SAE1-CloudFront-Out-Bytes SAE1-DataTransfer-Out-Bytes'

block geo
run 'aws cloudfront get-distribution-config --id $id --query "DistributionConfig.Restrictions"'
