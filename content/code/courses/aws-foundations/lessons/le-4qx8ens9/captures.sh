#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Recorded in the lab lesson 1 built, with moto's permission checking OFF (the
# default), as the lesson says. The two trust policies are read out of the
# lesson's ```json fences (groups-and-roles fence 1, federation fence 1) and
# the SAML metadata is made by federation's ```sh fence 1, as it stands.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the files the lesson asks the student to save are written by the script,
#     from the fences, before the command that reads them;
#   - they are removed at the end, so the shared lab home is left as it was.
#
# NOT PRODUCED HERE, and said so in the prose: anything about a real root user;
# AWS refusing a group as a principal; AWS checking a web identity token and a
# SAML metadata document; the trust policy turning an ARN into an id when the
# user is deleted.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
FILES='deployer-trust.json deployer-github.json idp.key idp.crt idp-metadata.xml blank.xml'
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

block summary
run 'aws iam get-account-summary --query "SummaryMap.{AccountMFAEnabled:AccountMFAEnabled,AccountAccessKeysPresent:AccountAccessKeysPresent,Users:Users,GroupsPerUserQuota:GroupsPerUserQuota}"'

block user-bia
run 'aws iam create-user --user-name bia'

block users
run 'aws iam create-user --user-name caio --query "User.[UserName,UserId,Arn]" --output text'
run 'aws iam create-user --user-name dani --query "User.[UserName,UserId,Arn]" --output text'

block credentials
run "aws iam create-login-profile --user-name bia --password 'Lab-only-pass-2026' --password-reset-required"
run 'aws iam create-access-key --user-name bia --query "AccessKey.[AccessKeyId,Status]" --output text'

block groups
run 'for g in developers data finance; do aws iam create-group --group-name $g --query Group.Arn --output text; done'
run 'aws iam add-user-to-group --group-name developers --user-name bia'
run 'aws iam add-user-to-group --group-name data --user-name caio'
run 'aws iam add-user-to-group --group-name finance --user-name dani'
run 'aws iam get-group --group-name developers --query "Users[].UserName"'
run 'aws iam list-groups-for-user --user-name caio --query "Groups[].GroupName"'

block group-principal
run "aws iam create-role --role-name grouptest --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:group/developers\"},\"Action\":\"sts:AssumeRole\"}]}' --query Role.Arn"
run 'aws iam delete-role --role-name grouptest'

fences json "$HERE/groups-and-roles.md" 1 > deployer-trust.json || exit 1
block role
run 'aws iam create-role --role-name deployer --assume-role-policy-document file://deployer-trust.json'

block role-key
run 'aws iam create-access-key --user-name deployer'

block session
run 'aws sts assume-role --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name bia-deploy --query "{User:AssumedRoleUser,Key:Credentials.AccessKeyId,Expires:Credentials.Expiration}"'

block oidc
run 'aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com'
run 'aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com'

fences json "$HERE/federation.md" 1 > deployer-github.json || exit 1
block trust-github
run 'aws iam update-assume-role-policy --role-name deployer --policy-document file://deployer-github.json'
run 'aws iam get-role --role-name deployer --query "Role.AssumeRolePolicyDocument.Statement[0].Principal"'

block web-identity
run 'aws sts assume-role-with-web-identity --no-sign-request --role-arn arn:aws:iam::123456789012:role/deployer --role-session-name run-1207 --web-identity-token not-a-real-token --query "{User:AssumedRoleUser,Key:Credentials.AccessKeyId}"'

block saml-short
run "aws iam create-saml-provider --name shop-idp --saml-metadata-document '<EntityDescriptor entityID=\"https://idp.shop.example.com/saml\"/>'"

sh_fences "$HERE/federation.md" 1 > "$LAB_ROOT/scratch/l06-saml.sh" || exit 1
bash -e "$LAB_ROOT/scratch/l06-saml.sh" || { echo "the saml fence failed"; exit 1; }
rm -f "$LAB_ROOT/scratch/l06-saml.sh"
block saml
run 'wc -c idp-metadata.xml'
run 'aws iam create-saml-provider --name shop-idp --saml-metadata-document file://idp-metadata.xml'
run "printf '%1000s' '' > blank.xml; aws iam create-saml-provider --name blank --saml-metadata-document file://blank.xml"
run 'aws iam list-saml-providers --query "SAMLProviderList[].Arn"'

block listing
run 'aws iam list-users --query "Users[].[UserName,UserId]" --output text'
run 'aws iam list-roles --query "Roles[].[RoleName,RoleId,Arn]" --output text'
run 'aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[].Arn" --output text'
