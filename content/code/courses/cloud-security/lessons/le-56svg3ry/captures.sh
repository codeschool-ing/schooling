#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto's checking is ON, started as the-escalation-path's ```sh fence 1 says,
# with the three-request bootstrap. with_key is that section's ```sh fence 2,
# defined in this shell as typed. manage-users.json is its ```json fence 1, and
# iam-writers.sh is finding-them's ```sh fence 1.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or the terminal's keys are run in this
#     script's own shell by `keep`, which is what typing them into one terminal
#     does;
#   - the files the lesson asks the student to save are written from the
#     fences, and removed at the end;
#   - "seven months ago" is the story: in the lab dani's key is a minute old, and
#     the prose says so beside the credential report.
#
# NOT PRODUCED HERE, and said so in the prose: Access Advisor's last-accessed
# report (moto: HTTP 500) and IAM Access Analyzer; IAM Identity Center and any
# identity provider; AWS refusing a deactivated key (moto still accepted it);
# conditions, permission boundaries and service control policies being
# enforced; revoking a role's active sessions.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

PATHSEC=$HERE/the-escalation-path.md
[ "$(sh_fences "$PATHSEC" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "the-escalation-path fence 1 changed"; exit 1; }
FILES='manage-users.json iam-writers.sh'
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
run 'aws sts get-caller-identity --query Arn --output text'

eval "$(sh_fences "$PATHSEC" 2)"
fences json "$PATHSEC" 1 > manage-users.json || exit 1

block account
run 'aws iam create-user --user-name caio --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/PowerUserAccess'
run 'aws iam create-user --user-name bia --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess'
run 'aws iam create-user --user-name dani --query User.Arn --output text'
run 'aws iam put-user-policy --user-name dani --policy-name manage-users --policy-document file://manage-users.json'
keep 'dani=$(aws iam create-access-key --user-name dani)'

block denied
keep 'with_key "$dani" aws iam list-users --query "Users[].UserName" --output text'

block escalate
keep 'with_key "$dani" aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'

block now-admin
keep 'with_key "$dani" aws iam list-users --query "Users[].UserName" --output text'

# ---- finding-them --------------------------------------------------------------
block report
run 'aws iam generate-credential-report --query State --output text'
run 'aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,8,9,10,11'

block last-used
keep 'aws iam get-access-key-last-used --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId)'

block quarantine
run 'aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" | jq -r ".[]" | grep -c .'
run 'aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" | jq -r ".[] | select(startswith(\"iam:\"))"'

sh_fences "$HERE/finding-them.md" 1 > "$HOME/aws/iam-writers.sh.fence" || exit 1
bash -e "$HOME/aws/iam-writers.sh.fence" || exit 1
rm -f "$HOME/aws/iam-writers.sh.fence"

block audit
run 'bash iam-writers.sh'

# ---- closing-it ----------------------------------------------------------------
block deactivate
keep 'aws iam update-access-key --user-name dani --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId) --status Inactive'
run 'aws iam list-access-keys --user-name dani --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text'
keep 'with_key "$dani" aws iam list-users --query "Users[].UserName" --output text'

block delete-key
keep 'aws iam delete-access-key --user-name dani --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId)'
keep 'with_key "$dani" aws iam list-users --query "Users[].UserName" --output text'

block delete-user
run 'aws iam detach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
run 'aws iam delete-user --user-name dani'
run 'aws iam delete-user-policy --user-name dani --policy-name manage-users'
run 'aws iam delete-user --user-name dani'
run 'bash iam-writers.sh'
run 'aws iam list-users --query "Users[].UserName" --output text'
