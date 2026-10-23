#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Three morotos, as the prose asks: "the-execution-role" runs with checking on
# (INITIAL_NO_AUTH_ACTION_COUNT=3 and lesson 6's admin bootstrap); "who-can-
# invoke" and most of "secrets-in-environment" run with checking off, because
# moto 5.2.3 answers Lambda's GET requests with SignatureDoesNotMatch when its
# checking is on; the last part of "secrets-in-environment" runs with checking
# on again, for bia's refusal. with_key and with_session are the-execution-
# role's ```sh fence 2, defined in this shell as typed. The JSON files are the
# lesson's ```json fences, handler.py is who-can-invoke's ```sh fence 2 and then
# the schooling-example of "secrets-in-environment", requirements.txt is
# dependencies' ```sh fence 2, and pip-audit is installed by dependencies'
# ```sh fence 1, all read out of the lesson.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - commands that set a shell variable or the terminal's keys are run in this
#     script's own shell by `keep`, which is what typing them into one
#     terminal does;
#   - the second admin bootstrap, which the prose describes and does not show,
#     runs silently;
#   - the files the lesson asks the student to save are written from the
#     fences, and removed at the end.
#
# NOT PRODUCED HERE, and said so in the prose: Lambda invoking anything (moto
# needs Docker for that, and serves no function URL), the 403 an unsigned
# request to an AWS_IAM function URL gets, AWS's AccessDenied for assume-role
# after the trust policy names only Lambda (moto answers HTTP 500), bia reading
# the function configuration with her own key, IAM Access Analyzer policy
# generation, last-accessed details, and get-function's LastModified.
#
# pip-audit asks PyPI's vulnerability data, so its table is the day's answer.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }
FILES='export-trust.json write-exports.json lambda-trust.json read-db-secret.json handler.py function.zip requirements.txt'
cleanup() { moto_stop; cd ~/aws && rm -f $FILES; }

[ "$(sh_fences "$HERE/the-execution-role.md" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "the-execution-role fence 1 changed"; exit 1; }
[ "$(sh_fences "$HERE/who-can-invoke.md" 1)" = 'moto_server -p 4567' ] \
  || { echo "who-can-invoke fence 1 changed"; exit 1; }
fences json "$HERE/the-execution-role.md" 1 > export-trust.json || exit 1
fences json "$HERE/the-execution-role.md" 2 > write-exports.json || exit 1
fences json "$HERE/the-execution-role.md" 3 > lambda-trust.json || exit 1
fences json "$HERE/secrets-in-environment.md" 1 > read-db-secret.json || exit 1
eval "$(sh_fences "$HERE/the-execution-role.md" 2)"

bootstrap() {
  run 'aws iam create-user --user-name admin --query User.Arn --output text'
  run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
  keep 'key=$(aws iam create-access-key --user-name admin)'
  run 'aws iam list-users'
  keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
  run 'aws sts get-caller-identity --query Arn --output text'
}

# ---- the-execution-role: checking on -----------------------------------------
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap cleanup EXIT
block bootstrap
bootstrap

block setup
run 'aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run "printf 'patient,diagnosis\\nMaria Souza,asthma\\n' | aws s3 cp - s3://clinic-records/patients.csv"

block role
run 'aws iam create-role --role-name export-fn --assume-role-policy-document file://export-trust.json --query Role.Arn --output text'
run 'aws iam attach-role-policy --role-name export-fn --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/export-fn --role-session-name daily-export)'
keep 'with_session "$r" aws sts get-caller-identity --query Arn --output text'
keep 'with_session "$r" aws s3 cp s3://clinic-records/patients.csv -'
keep 'with_session "$r" aws iam list-users --query "Users[].UserName" --output text'

block tight
run 'aws iam detach-role-policy --role-name export-fn --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
run 'aws iam put-role-policy --role-name export-fn --policy-name write-exports --policy-document file://write-exports.json'
keep 'r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/export-fn --role-session-name daily-export)'
keep "printf 'date,time\\n2026-10-23,09:00\\n' | with_session \"\$r\" aws s3 cp - s3://clinic-exports/2026-10-23.csv"
keep 'with_session "$r" aws s3 cp s3://clinic-records/patients.csv -'
keep 'with_session "$r" aws iam list-users --query "Users[].UserName" --output text'

block trust
run 'aws iam update-assume-role-policy --role-name export-fn --policy-document file://lambda-trust.json'
run 'aws iam get-role --role-name export-fn --query "Role.AssumeRolePolicyDocument.Statement[].Principal"'

# ---- who-can-invoke: checking off --------------------------------------------
unset AWS_SESSION_TOKEN
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
moto_fresh
trap cleanup EXIT
bash -e <(sh_fences "$HERE/who-can-invoke.md" 2) || exit 1

block create
run 'aws iam create-role --role-name export-fn --assume-role-policy-document file://lambda-trust.json --query Role.Arn --output text'
run 'python3 -m zipfile -c function.zip handler.py'
run 'aws lambda create-function --function-name daily-export --runtime python3.12 --handler handler.handler --role arn:aws:iam::123456789012:role/export-fn --zip-file fileb://function.zip --query "[FunctionName,Runtime,State]" --output text'

block url
run 'aws lambda create-function-url-config --function-name daily-export --auth-type NONE --query "[FunctionUrl,AuthType]" --output text'
run "aws lambda add-permission --function-name daily-export --statement-id anyone --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE --query Statement --output text"
run 'aws lambda get-policy --function-name daily-export --query Policy --output text | jq .'

block close
run 'aws lambda remove-permission --function-name daily-export --statement-id anyone'
run 'aws lambda update-function-url-config --function-name daily-export --auth-type AWS_IAM --query AuthType --output text'
run 'aws lambda get-policy --function-name daily-export'

block from-uploads
run 'aws lambda add-permission --function-name daily-export --statement-id from-uploads --action lambda:InvokeFunction --principal s3.amazonaws.com --source-arn arn:aws:s3:::clinic-uploads --source-account 123456789012 --query Statement --output text | jq .'
run 'aws lambda remove-permission --function-name daily-export --statement-id from-uploads' >/dev/null

# ---- secrets-in-environment: checking off ------------------------------------
block env
run 'aws lambda update-function-configuration --function-name daily-export --environment "Variables={DB_PASSWORD=Clinic-2026-pass}" --query LastUpdateStatus --output text'
run 'aws lambda get-function-configuration --function-name daily-export --query Environment'

block readonly
run "aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id \$(aws iam get-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --query Policy.DefaultVersionId --output text) --query \"PolicyVersion.Document.Statement[].Action[]\" --output json | jq -r '.[] | select(startswith(\"lambda:\") or startswith(\"secretsmanager:\"))'"

block secret
run 'aws secretsmanager create-secret --name clinic/db --secret-string Clinic-2026-pass --query ARN --output text'
run 'aws lambda update-function-configuration --function-name daily-export --environment "Variables={DB_SECRET=clinic/db}" --query Environment'

block role-policy
run 'aws iam put-role-policy --role-name export-fn --policy-name read-db-secret --policy-document file://read-db-secret.json'

example "$HERE/secrets-in-environment.md" handler.py > handler.py || exit 1
block run
run 'python3 -m zipfile -c function.zip handler.py'
run 'aws lambda update-function-code --function-name daily-export --zip-file fileb://function.zip --query LastUpdateStatus --output text'
run "DB_SECRET=clinic/db python3 -c 'from handler import handler; print(handler({}, None))'"

# ---- bia: checking on again ---------------------------------------------------
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap cleanup EXIT
bootstrap > /dev/null
block bia
run 'aws secretsmanager create-secret --name clinic/db --secret-string Clinic-2026-pass --query Name --output text'
run 'aws iam create-user --user-name bia --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess'
keep 'bia=$(aws iam create-access-key --user-name bia)'
keep 'with_key "$bia" aws secretsmanager list-secrets --query "SecretList[].Name" --output text'
keep 'with_key "$bia" aws secretsmanager get-secret-value --secret-id clinic/db --query SecretString --output text'

# ---- dependencies --------------------------------------------------------------
bash -e <(sh_fences "$HERE/dependencies.md" 1) >/dev/null 2>&1 || { echo "pip-audit install failed"; exit 1; }
bash -e <(sh_fences "$HERE/dependencies.md" 2) || exit 1
block audit
run '~/aws/tools/bin/pip-audit --version'
run '~/aws/tools/bin/pip-audit --no-deps --disable-pip -r requirements.txt'

block fixed
run "sed -i 's/requests==2.19.1/requests==2.34.2/' requirements.txt"
run '~/aws/tools/bin/pip-audit --no-deps --disable-pip -r requirements.txt'
