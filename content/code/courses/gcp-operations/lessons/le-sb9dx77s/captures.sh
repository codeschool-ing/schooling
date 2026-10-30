#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# The state bucket is created by Terraform (tf/bootstrap) in fake-gcs-server,
# with versioning, and the shop's configuration (tf/shop) moves its state into
# it through the gcs backend's storage_custom_endpoint. The lock contention is
# real: a first apply holds the lock while a local-exec sleeps, in the
# background, and a second plan is refused.
# STAGED: the holding apply runs in the background (`&`), where the student is
# told to use a second terminal; its output is not quoted.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
emulators_up
student_env
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf "$HOME/gcp/tf/bootstrap" "$HOME/gcp/tf/shop"
mkdir -p "$HOME/gcp/tf/bootstrap" "$HOME/gcp/tf/shop"
gcloud storage buckets create gs://planner-dev-shop-assets --location=southamerica-east1 > /dev/null 2>&1

cd "$HOME/gcp/tf/bootstrap" || exit 1
from_lesson "$HERE/state-bucket.md" tf/bootstrap/main.tf > main.tf
block bootstrap
quiet 'terraform init -input=false'
run 'terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"'

cd "$HOME/gcp/tf/shop" || exit 1
from_lesson "$HERE/state-bucket.md" tf/shop/main.tf > main.tf
block local-first
quiet 'terraform init -input=false'
run 'terraform apply -auto-approve -input=false -no-color | grep -E "^google_|Apply"'
run 'ls'

block migrate
from_lesson "$HERE/state-bucket.md" tf/shop/backend.tf > backend.tf
run 'terraform init -migrate-state -force-copy -input=false -no-color | grep -E "backend|Successfully|copy"'
run 'rm terraform.tfstate terraform.tfstate.backup'
run 'gcloud storage ls gs://planner-dev-tfstate/shop/'
run 'terraform state list'

block lock
from_lesson "$HERE/locking.md" tf/shop/slow.tf > slow.tf
( terraform apply -auto-approve -input=false -no-color > /var/tmp/hold.log 2>&1 & )
for _ in $(seq 60); do gcloud storage ls gs://planner-dev-tfstate/shop/ 2>/dev/null | grep -q tflock && break; sleep 0.5; done
run 'terraform plan -lock-timeout=0s -input=false -no-color 2>&1 | head -12'
run 'gcloud storage cat gs://planner-dev-tfstate/shop/default.tflock; echo'
for _ in $(seq 80); do grep -q 'Apply complete' /var/tmp/hold.log && break; sleep 0.5; done
sleep 1
run 'gcloud storage ls gs://planner-dev-tfstate/shop/'
rm -f slow.tf
quiet 'terraform apply -auto-approve -input=false'

block accident
run 'curl -s -X DELETE localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate'
run 'terraform plan -input=false -no-color 2>&1 | grep -E "^  # |Plan:|Error|already exists"'

block restore
run "curl -s 'localhost:4443/storage/v1/b/planner-dev-tfstate/o?prefix=shop/default.tfstate&versions=true' | jq -r '.items[] | [.generation, .updated] | @tsv' | sort"
B='localhost:4443/storage/v1/b/planner-dev-tfstate/o'
run "for g in \$(curl -s '$B?prefix=shop/default.tfstate&versions=true' | jq -r '.items[].generation' | sort); do printf '%s ' \$g; curl -s \"$B/shop%2Fdefault.tfstate?generation=\$g&alt=media\" | jq -c '[.serial, (.resources | length)]'; done"
GEN=$(for g in $(curl -s "$B?prefix=shop/default.tfstate&versions=true" | jq -r '.items[].generation'); do printf '%s ' "$g"; curl -s "$B/shop%2Fdefault.tfstate?generation=$g&alt=media" | jq -r '.serial'; done | sort -k2 -n | tail -1 | cut -d' ' -f1)
run "curl -s -o restored.tfstate 'localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate?generation=$GEN&alt=media'"
run 'terraform state push -force restored.tfstate'
run 'terraform plan -input=false -no-color | grep -E "^  # |No changes|Plan:"'
run 'rm restored.tfstate'

block import
from_lesson "$HERE/prevention.md" tf/shop/backend.tf > backend.tf
run 'terraform init -reconfigure -input=false -no-color | grep -E "Successfully"'
from_lesson "$HERE/prevention.md" tf/shop/imports.tf > imports.tf
run 'terraform plan -input=false -no-color | grep -E "^  # |^Plan:|import"'
run 'terraform plan -input=false -no-color | sed -n "/pubsub_topic.orders will be/,/^    }/p" | grep -E "^ +[~+-] "'
emulators_down
