#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# The Terraform plans are local, with the fake token. The leak demonstration
# uses only terraform_data, which needs no provider and no network, and its
# password is the lab's own invented one. The secret file mounted into the
# container is written by the script, standing for what Cloud Run mounts.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/secrets tf/leak secrets && mkdir -p tf/secrets tf/leak
cd tf/secrets || exit 1
from_lesson "$HERE/secrets.md" tf/secrets/main.tf > main.tf
quiet 'terraform init -input=false'
block plan
run 'terraform plan -input=false -no-color | grep -E "^  # |location|rotation_period|role|Plan:"'

cd "$HOME/gcp" || exit 1
from_lesson "$HERE/reading.md" readsecret.py > readsecret.py
mkdir -p secrets && printf 'k7-practice-only-9f\n' > secrets/db-password
block mount
run 'docker run --rm -v "$PWD/secrets":/secrets:ro -v "$PWD/readsecret.py":/app/readsecret.py:ro mirror.gcr.io/library/python:3.12.16-slim python /app/readsecret.py'

cd "$HOME/gcp/tf/leak" || exit 1
from_lesson "$HERE/state.md" tf/leak/main.tf > main.tf
quiet 'terraform init -input=false'
block leak
run 'TF_VAR_db_password=k7-practice-only-9f terraform apply -auto-approve -input=false -no-color | grep -E "connection|Apply"'
run 'terraform output connection'
run "grep -c k7-practice-only-9f terraform.tfstate"
run "jq -r '.resources[0].instances[0].attributes.input.value' terraform.tfstate"
