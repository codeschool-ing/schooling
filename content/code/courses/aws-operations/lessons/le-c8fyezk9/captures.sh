#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of aws-operations. Output not
# committed; every transcript was copied from a run of this script.
#
#   bash ../../lab.sh tools   # once: Terraform from the first sh fence of
#                             # "provider", and the provider mirror (lab.sh)
#   bash captures.sh
#
# STAGED, and why:
#   - the AWS provider comes from a filesystem mirror (lab.sh), because the
#     Terraform Registry was not reachable from the recording machine.
#     `terraform init` then says "(unauthenticated)" and warns about checksums,
#     which a registry install does not; those lines are cut from the quotes
#     with `grep -v`, and the lesson does not show a full init.
#   - the provider addresses S3 Control at 123456789012.localhost:4567. On
#     Ubuntu 24.04, systemd-resolved answers any *.localhost name with
#     127.0.0.1; the recording container had no such resolver, so /etc/hosts
#     carries that one name.
#   - a lock is held by an `apply` left waiting at its prompt, fed from a fifo,
#     and released by answering "no". The lock's "Who" field shows the
#     recording machine's user and host, root@vm; the lesson says so.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/aws" || exit 1
rm -rf tf && mkdir -p tf/bootstrap tf/shop && cd tf/bootstrap || exit 1
moto_up
student_env

block versions
run 'terraform version'

from_lesson "$HERE/state-bucket.md" bootstrap/main.tf > main.tf
block bootstrap
quiet 'terraform init -input=false'
run "terraform apply -auto-approve -input=false -no-color | grep -E '^(aws_|Apply)'"
run 'aws s3api get-bucket-versioning --bucket shop-tfstate-123456789012'
run 'aws s3api get-public-access-block --bucket shop-tfstate-123456789012 --query PublicAccessBlockConfiguration'

cd ../shop || exit 1
from_lesson "$HERE/provider.md" shop/main.tf > main.tf
block tags
quiet 'terraform init -input=false'
run "terraform apply -auto-approve -input=false -no-color | grep -E '^(aws_|Apply)'"
run "aws sns list-tags-for-resource --resource-arn arn:aws:sns:sa-east-1:123456789012:shop-alerts --query 'Tags[].[Key,Value]' --output text"

hold() { # an apply waiting at its prompt, holding the state lock
  rm -f "$HOME/aws/tf/fifo"; mkfifo "$HOME/aws/tf/fifo"
  terraform apply -no-color < "$HOME/aws/tf/fifo" > "$HOME/aws/tf/held.log" 2>&1 &
  HELD=$!
  exec 3> "$HOME/aws/tf/fifo"
  for _ in $(seq 60); do grep -q 'Enter a value' "$HOME/aws/tf/held.log" && return 0; sleep 0.5; done
}
release() { echo no >&3; exec 3>&-; wait "$HELD"; }

from_lesson "$HERE/locking.md" dynamodb/backend.tf > backend.tf
quiet 'terraform init -input=false -migrate-state -force-copy'
block deprecated
run "terraform init -input=false -no-color | sed -n '/Warning/,/instead/p'"
quiet "sed -i 's/shop-alerts\"/shop-alerts\"\n  display_name = \"Shop alerts\"/' main.tf"
hold
block lock-item
run "aws dynamodb scan --table-name shop-tflocks --query 'Items[].Info.S' --output text | jq ."
block lock-refused
run "terraform plan -lock-timeout=0s -no-color 2>&1 | sed -n '/Error: Error acquiring/,\$p'"
release

from_lesson "$HERE/locking.md" both/backend.tf > backend.tf
block both
run "terraform init -input=false -reconfigure -no-color | grep -E 'Warning|Successfully|deprecated'"
hold
block lockfile
run 'aws s3 ls s3://shop-tfstate-123456789012/shop/'
run "aws dynamodb scan --table-name shop-tflocks --query 'Items[].LockID.S' --output text"
release
block released
run 'aws s3 ls s3://shop-tfstate-123456789012/shop/'

from_lesson "$HERE/locking.md" lockfile/backend.tf > backend.tf
block lockfile-only
run "terraform init -input=false -reconfigure -no-color | grep -E 'Warning|Successfully'"
