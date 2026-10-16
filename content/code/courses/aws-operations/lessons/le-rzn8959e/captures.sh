#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
# The bootstrap configuration is lesson 6's, read out of that lesson; the
# shop's configuration is read out of this one. The provider mirror and the
# /etc/hosts line are lesson 6's staging (see its captures.sh). The deletion of
# the state object is the accident the lesson is about, made on purpose.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf tf7 && mkdir -p tf7/bootstrap tf7/shop tf7/rebuilt && cd tf7/bootstrap || exit 1
moto_up
student_env
B=shop-tfstate-123456789012
K=shop/terraform.tfstate

from_lesson "$HERE/../le-c8fyezk9/state-bucket.md" bootstrap/main.tf > main.tf
quiet 'terraform init -input=false && terraform apply -auto-approve -input=false'

cd ../shop || exit 1
from_lesson "$HERE/the-accident.md" shop/main.tf > main.tf
quiet 'terraform init -input=false'
block applied
run "terraform apply -auto-approve -input=false -no-color | grep -E '^(Apply|Outputs)'"
run 'terraform state list'

block accident
run "aws s3 rm s3://$B/$K"
block plan-after
run "terraform plan -no-color | grep -E '^  # |^Plan:'"
block apply-after
run "terraform apply -auto-approve -input=false -no-color 2>&1 | grep -E '^(aws_.*(complete|Creating)|Error:)' "
run 'terraform state list'

block versions
run "aws s3api list-object-versions --bucket $B --prefix $K --query \"Versions[?Key=='$K'].[LastModified,Size,VersionId]\" --output text"
run "aws s3api list-object-versions --bucket $B --prefix $K --query \"DeleteMarkers[?Key=='$K'].[LastModified,VersionId]\" --output text"
GOOD=$(aws s3api list-object-versions --bucket $B --prefix $K --query "sort_by(Versions[?Key=='$K'], &Size)[-1].VersionId" --output text)
block restore
run "aws s3api copy-object --bucket $B --key $K --copy-source '$B/$K?versionId=$GOOD' --query VersionId --output text"
run "terraform plan -no-color | grep -E '^(No changes|Plan:)'"
run 'terraform state list'

block pull
run 'terraform state pull > state-2026-10-16.json && wc -c state-2026-10-16.json'

cd ../rebuilt || exit 1
from_lesson "$HERE/import.md" rebuilt/backend.tf > backend.tf
from_lesson "$HERE/import.md" rebuilt/imports.tf > imports.tf
quiet "sed -n '/^provider/,/^}/p' ../shop/main.tf > provider.tf"
quiet "sed -n '/^terraform {/,/^}/p' ../shop/main.tf | sed '/backend/,/^  }/d' > versions.tf"
quiet 'terraform init -input=false'
block generate
run "terraform plan -generate-config-out=generated.tf -no-color | grep -E '^Plan:|generated'"
run 'cat generated.tf | grep -v -E "^ *#|= null$" | head -24'
