#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of gcp-operations.
#
#   bash lab.sh tools    # once: Terraform from this lesson's own fence
#   bash captures.sh
#
# Terraform 1.16.4 and the google provider 8.9.0, fetched by `terraform init`
# from the Terraform Registry. The bucket is created in fake-gcs-server through
# storage_custom_endpoint. GOOGLE_OAUTH_ACCESS_TOKEN=fake is what the lesson
# has the student export; with it the provider makes one call to Google, to
# ask whose token it is, is told it is invalid, and carries on (it says so
# only in its debug log). Nothing else leaves the laptop.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
emulators_up
student_env
rm -rf "$HOME/gcp/tf/shop"
mkdir -p "$HOME/gcp/tf/shop" && cd "$HOME/gcp/tf/shop" || exit 1
from_lesson "$HERE/provider.md" tf/shop/main.tf > main.tf

block version
run 'terraform version'

block no-credentials
run 'terraform init -input=false -no-color | grep -E "Installing|Installed|successfully"'
run 'terraform plan -input=false -no-color 2>&1 | tail -8'

block token
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
run 'terraform plan -input=false -no-color | grep -A3 -E "^  #|terraform_labels" | grep -v "^--"'

block apply
run 'terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"'
run "gcloud storage buckets describe gs://planner-dev-shop-assets --format='yaml(name,labels,location)'"

block drift
run 'terraform plan -input=false -no-color | grep -E "^  #|forces replacement|Plan:"'

block service
mkdir -p "$HOME/gcp/tf/apis" && cd "$HOME/gcp/tf/apis" || exit 1
from_lesson "$HERE/apply.md" tf/apis/main.tf > main.tf
quiet 'terraform init -input=false'
run 'terraform plan -input=false -no-color | grep -E "^  # |Plan:"'
emulators_down
