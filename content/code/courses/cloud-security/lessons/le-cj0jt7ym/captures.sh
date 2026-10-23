#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The tools are installed by the section "installing", out of its own ```sh
# fences 1 (Terraform, Checkov) and 2 (the plugin cache). Fence 3, apt-get
# install git, needs sudo and is not run: the script checks git is installed.
# Every main.tf is read out of the lesson's ```hcl fences, and the one-line
# edit of "the-plan-is-the-review" is applied by replacing the line it names.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the Terraform Registry is not reachable from the recording machine, and
#     releases.hashicorp.com is. The AWS provider 6.67.0 is downloaded from
#     releases.hashicorp.com, checked against HashiCorp's SHA256SUMS, and served
#     from a filesystem mirror in $LAB_ROOT/mirror. TF_CLI_CONFIG_FILE names a
#     file holding the student's ~/.terraformrc (from fence 2) plus that mirror.
#     `terraform init` is therefore run without its output being quoted, and the
#     prose says so ("installing", "A note on the recording");
#   - CHECKPOINT_DISABLE=1, because Terraform's version check calls a HashiCorp
#     host the recording machine cannot reach; it changes nothing printed here;
#   - the access key in "secrets-in-the-repo" is invented and was never valid;
#   - git commits carry the time of the run, so their hashes differ every run;
#     no hash is quoted in the prose.
#
# NOT RUN, and said so in the prose: gitleaks and TruffleHog, GitHub's secret
# scanning, a remote state backend.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
export CHECKPOINT_DISABLE=1

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }
installed git || { echo "install git first, as in the third fence"; exit 1; }

provider_mirror() {
  local v=6.67.0 name=terraform-provider-aws
  local file=${name}_${v}_linux_amd64.zip dir=$LAB_ROOT/mirror/registry.terraform.io/hashicorp/aws/$v/linux_amd64
  [ -d "$dir" ] && return 0
  mkdir -p "$LAB_ROOT/dl" "$dir"
  [ -f "$LAB_ROOT/dl/$file" ] || curl -sSfo "$LAB_ROOT/dl/$file" "https://releases.hashicorp.com/$name/$v/$file"
  curl -sSf "https://releases.hashicorp.com/$name/$v/${name}_${v}_SHA256SUMS" | grep " $file\$" \
    | (cd "$LAB_ROOT/dl" && sha256sum -c --quiet) || exit 1
  unzip -oq "$LAB_ROOT/dl/$file" -d "$dir"
}

# ---- installing --------------------------------------------------------------
bash -e <(sh_fences "$HERE/installing.md" 1) > /dev/null 2>&1 || { echo "installing fence 1 failed"; exit 1; }
bash -e <(sh_fences "$HERE/installing.md" 2) || { echo "installing fence 2 failed"; exit 1; }
provider_mirror
{ cat ~/.terraformrc; printf 'provider_installation {\n  filesystem_mirror {\n    path = "%s/mirror"\n  }\n}\n' "$LAB_ROOT"; } \
  > "$LAB_ROOT/terraformrc"
export TF_CLI_CONFIG_FILE=$LAB_ROOT/terraformrc
hash -r

moto_fresh
DIRS="$HOME/aws/clinic $HOME/aws/reports $HOME/aws/clinic-db"
rm -rf $DIRS
trap 'moto_stop; rm -rf $DIRS' EXIT

block versions
run 'terraform version'
run 'checkov --version'
run 'git --version'

# ---- the-plan-is-the-review ----------------------------------------------------
PLAN=$HERE/the-plan-is-the-review.md
bash -e <(sh_fences "$PLAN" 1) || exit 1
cd ~/aws/clinic && at '~/aws/clinic'
fences hcl "$PLAN" 1 > main.tf || exit 1
terraform init -input=false > /dev/null || { echo "terraform init failed"; exit 1; }

block plan-unknown
run "terraform plan -no-color | sed -n '/tablet will be created/,/^    }/p'"

python3 - "$(fences hcl "$PLAN" 2)" <<'PY' || exit 1
import sys
new = sys.argv[1].rstrip('\n')
old = '      Resource  = "${aws_s3_bucket.exports.arn}/*"'
s = open('main.tf').read()
assert old in s
open('main.tf', 'w').write(s.replace(old, new))
PY

block plan-known
run "terraform plan -no-color | sed -n '/tablet will be created/,/^    }/p'"

block query
run 'terraform plan -out=plan.bin -no-color > /dev/null'
run "terraform show -json plan.bin | jq -r '.resource_changes[] | select(.change.after.policy != null) | .address as \$a | .change.after.policy | fromjson | .Statement[] | select(.Principal == \"*\") | \"\\(\$a)  \\(.Effect)  \\(.Action)\"'"

# ---- scanning ----------------------------------------------------------------
block scan-before
run 'checkov -d . --framework terraform --compact --quiet --skip-download; echo "exit status $?"'

fences hcl "$HERE/scanning.md" 1 > main.tf || exit 1
block scan-after
run 'checkov -d . --framework terraform --compact --quiet --skip-download; echo "exit status $?"'

block plan-after
run 'terraform plan -out=plan.bin -no-color > /dev/null'
run "terraform show -json plan.bin | jq -r '[.resource_changes[].address] | .[]'"

# ---- secrets-in-the-repo -----------------------------------------------------
REPO=$HERE/secrets-in-the-repo.md
cd ~/aws && bash -e <(sh_fences "$REPO" 1) || exit 1
cd ~/aws/reports && at '~/aws/reports'
fences hcl "$REPO" 1 > main.tf || exit 1

block repo-leak
run 'git add main.tf && git commit -q -m "Monthly reports bucket"'
run 'checkov -d . --framework secrets --compact --quiet --skip-download; echo "exit status $?"'

python3 - "$(fences hcl "$REPO" 2)" <<'PY' || exit 1
import re, sys
s = open('main.tf').read()
new, n = re.subn(r'^provider "aws" \{\n.*?^\}\n', sys.argv[1], s, flags=re.S | re.M)
assert n == 1
open('main.tf', 'w').write(new)
PY

block repo-history
run 'git commit -q -am "Take the keys out of the provider"'
run 'checkov -d . --framework secrets --compact --quiet --skip-download; echo "exit status $?"'
run "git log -p -S AKIA2E0A8F3B244C9986 --format='%an %s' | grep -E '^bia|AKIA'"

# ---- secrets-in-the-state ----------------------------------------------------
STATE=$HERE/secrets-in-the-state.md
cd ~/aws && bash -e <(sh_fences "$STATE" 1) || exit 1
cd ~/aws/clinic-db && at '~/aws/clinic-db'
fences hcl "$STATE" 1 > main.tf || exit 1
terraform init -input=false > /dev/null || { echo "terraform init failed"; exit 1; }
# shellcheck disable=SC1090
. <(sh_fences "$STATE" 2)

block state-clear
run 'terraform apply -auto-approve -no-color | tail -1'
run 'terraform state show -no-color aws_secretsmanager_secret_version.db | grep secret_string'
run "grep -o '\"secret_string\": \"[^\"]*\"' terraform.tfstate"

fences hcl "$STATE" 2 > main.tf || exit 1
block state-wo
run "terraform apply -auto-approve -no-color | grep -E 'will be|Apply complete'"
run "grep -c 'Clinic-2019-Booking' terraform.tfstate terraform.tfstate.backup"
run 'aws secretsmanager get-secret-value --secret-id clinic/db --query SecretString --output text'
