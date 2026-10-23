#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moto's checking is ON, started as lesson 6 starts it, with the same
# three-request bootstrap. with_key and with_session are two-kinds' ```sh
# fence 1, defined in this shell as typed. The trust policy is two-kinds'
# ```json fence 1; the two role policies are secrets-manager's ```json fences 1
# and 2; booking.env is written by when-a-key-leaks' ```sh fence 1 and
# rewritten by rotating-a-key's ```sh fence 1; app.py is the example in
# in-the-application.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or the terminal's keys are run in this
#     script's own shell by `keep`, which is what typing them into one terminal
#     does;
#   - the quarantine policy is attached by hand, standing in for AWS, which
#     attaches it when it learns a key was exposed;
#   - the files the lesson asks the student to write are written from the
#     fences, and removed at the end.
#
# NOT PRODUCED HERE, and said so in the prose: AWS's own detection of an
# exposed key and its notice; GitHub secret scanning; a session expiring (the
# capture does not wait fifteen minutes); AWS refusing a deactivated key (moto
# accepted it); a narrow Resource on a secret being honoured (moto refused it,
# and the lab falls back to "*"); automatic rotation with a rotation function;
# the shorter AccessDeniedException message AWS prints for Secrets Manager.
#
# `lab.sh check` REPORTS TWO BLOCKS that are not drift: role-session (the
# session token and its expiry are new on every run) and create-secret (the
# six characters moto adds to a secret's ARN, and the version id, are random).
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }

FILES='trust-admin.json read-db-secret.json read-any-secret.json app.py'
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; cd ~/aws && rm -f $FILES && rm -rf booking' EXIT

block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'

eval "$(sh_fences "$HERE/two-kinds.md" 1)"
fences json "$HERE/two-kinds.md" 1 > trust-admin.json || exit 1

block user-key
run 'aws iam create-user --user-name caio --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/PowerUserAccess'
keep 'caio=$(aws iam create-access-key --user-name caio)'
keep 'echo "$caio" | jq ".AccessKey | {AccessKeyId, Status, CreateDate}"'

block role-session
run 'aws iam create-role --role-name booking-app --assume-role-policy-document file://trust-admin.json --query Role.Arn --output text'
keep 'session=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/booking-app --role-session-name booking --duration-seconds 900)'
keep 'echo "$session" | jq ".Credentials | {AccessKeyId, Expiration, SessionToken: (.SessionToken[:24] + \"...\")}"'
keep 'with_session "$session" aws sts get-caller-identity --query Arn --output text'

# ---- when-a-key-leaks -----------------------------------------------------------
eval "$(sh_fences "$HERE/when-a-key-leaks.md" 1)"
block grep
run "grep -rnoE 'A(KI|SI)A[A-Z0-9]{16}' booking"

block quarantine
run 'aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3'
keep 'with_key "$caio" aws s3 ls'
keep 'with_key "$caio" aws iam create-access-key --user-name caio'
keep 'with_key "$caio" aws secretsmanager list-secrets --query "length(SecretList)"'

# ---- rotating-a-key ---------------------------------------------------------------
block second-key
keep 'caio2=$(aws iam create-access-key --user-name caio)'
run 'aws iam list-access-keys --user-name caio --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text'
run 'aws iam create-access-key --user-name caio'

eval "$(sh_fences "$HERE/rotating-a-key.md" 1)"
block switch
keep 'grep -c "$(echo "$caio2" | jq -r .AccessKey.AccessKeyId)" booking/booking.env'
keep 'aws iam update-access-key --user-name caio --access-key-id $(echo "$caio" | jq -r .AccessKey.AccessKeyId) --status Inactive'
keep 'with_key "$caio" aws sts get-caller-identity --query Arn --output text'

block delete-old
keep 'aws iam delete-access-key --user-name caio --access-key-id $(echo "$caio" | jq -r .AccessKey.AccessKeyId)'
keep 'with_key "$caio" aws sts get-caller-identity --query Arn --output text'
run 'aws iam detach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3'
keep 'with_key "$caio2" aws s3 ls'
run 'aws iam list-access-keys --user-name caio --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text'

# ---- secrets-manager --------------------------------------------------------------
block create-secret
keep 'pw=$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)'
keep 'aws secretsmanager create-secret --name clinic/booking/db --secret-string "$pw" --query Name --output text'
run 'aws secretsmanager create-secret --name clinic/reports/db --secret-string "$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)" --query Name --output text'
run 'aws secretsmanager describe-secret --secret-id clinic/booking/db --query "[ARN,VersionIdsToStages]"'

fences json "$HERE/secrets-manager.md" 1 > read-db-secret.json || exit 1
fences json "$HERE/secrets-manager.md" 2 > read-any-secret.json || exit 1
block narrow
run 'aws iam put-role-policy --role-name booking-app --policy-name read-db-secret --policy-document file://read-db-secret.json'
keep 'session=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/booking-app --role-session-name booking)'
keep 'with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/booking/db --query "length(SecretString)"'

block wide
run 'aws iam put-role-policy --role-name booking-app --policy-name read-db-secret --policy-document file://read-any-secret.json'
keep 'with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/booking/db --query "length(SecretString)"'
keep 'with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/reports/db --query "length(SecretString)"'

block manual-rotation
keep 'new=$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)'
keep 'aws secretsmanager put-secret-value --secret-id clinic/booking/db --secret-string "$new" --query VersionStages --output text'
run 'aws secretsmanager list-secret-version-ids --secret-id clinic/booking/db --query "Versions[].VersionStages[]" --output text'
keep '[ "$(aws secretsmanager get-secret-value --secret-id clinic/booking/db --version-stage AWSPREVIOUS --query SecretString --output text)" = "$pw" ] && echo previous is the old password'
keep '[ "$(aws secretsmanager get-secret-value --secret-id clinic/booking/db --query SecretString --output text)" = "$new" ] && echo current is the new one'

# ---- in-the-application ------------------------------------------------------------
example "$HERE/in-the-application.md" app.py > app.py || exit 1
block app
keep 'with_session "$session" python3 app.py'
