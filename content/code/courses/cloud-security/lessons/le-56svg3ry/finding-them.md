---
title: Finding them before somebody else does
version: 1
---

**The path in the last section needed three things: a user nobody removed, a key nobody
deactivated, and a permission that writes to IAM. Each has its own record, and a review reads all
three.** None of them needs a special tool; the AWS command line and `jq` are enough for an account
the clinic's size.

## The users and their keys

The **credential report** is one CSV row per IAM user: whether it has a password, whether it has
MFA, and for each of its two possible access keys whether it is active, when it was last rotated and
when it was last used. AWS builds it on request, so the first call asks for it and the second reads
it. `cut` keeps five of its twenty-two columns:

```
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
STARTED
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,8,9,10,11
user,mfa_active,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date
admin,false,true,2026-10-23T03:46:27+00:00,2026-10-23T03:46:38+00:00
caio,false,false,N/A,N/A
bia,false,false,N/A,N/A
dani,false,true,2026-10-23T03:46:34+00:00,2026-10-23T03:46:36+00:00
```

Read dani's row. **No MFA, an active key, used today.** In the lab the key is a minute old; in the
clinic's account `access_key_1_last_rotated` would say February. Of a key that old, on a person who
left, the question is not whether it is dangerous but why it still exists. AWS adds a
first row for the account's root user, `<root_account>`, which moto leaves out.

`get-access-key-last-used` answers the same question for one key, with the service and region of
its last request:

```
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId)
{
    "UserName": "dani",
    "AccessKeyLastUsed": {
        "LastUsedDate": "2026-10-23T03:46:36.900016+00:00",
        "ServiceName": "iam",
        "Region": "sa-east-1"
    }
}
```

**A key used today by somebody who left is an incident, not a finding.** Lesson 15's records would
say what the key did; this lesson's job is to close the path, and the order of the next section
matters for exactly that reason.

## The permissions that write to IAM

Which actions belong on the list? Guessing is how a list misses one, so take it from AWS. When AWS
learns that an access key has been exposed, it attaches a managed policy to the user, the
**compromised-key quarantine policy**, which denies the actions a stolen key would reach for first.
Its third version is in moto's copy of the managed policies, and its first statement is a long
list:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" | jq -r ".[]" | grep -c .
98
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSCompromisedKeyQuarantineV3 --version-id v3 --query "PolicyVersion.Document.Statement[0].Action" | jq -r ".[] | select(startswith(\"iam:\"))"
iam:AddUserToGroup
iam:AttachGroupPolicy
iam:AttachRolePolicy
iam:AttachUserPolicy
iam:ChangePassword
iam:CreateAccessKey
iam:CreateInstanceProfile
iam:CreateLoginProfile
iam:CreatePolicyVersion
iam:CreateRole
iam:CreateUser
iam:DetachUserPolicy
iam:PassRole
iam:PutGroupPolicy
iam:PutRolePolicy
iam:PutUserPermissionsBoundary
iam:PutUserPolicy
iam:SetDefaultPolicyVersion
iam:UpdateAccessKey
iam:UpdateAccountPasswordPolicy
iam:UpdateAssumeRolePolicy
iam:UpdateLoginProfile
iam:UpdateUser
iam:DeleteRole
iam:DeleteAccessKey
iam:ListUsers
```

Ninety-eight actions across many services, and the IAM part of them is the list a review should look
for. Most of them grant permissions, create a new way in, or change who may assume a role; a few, such
as `iam:ListUsers`, are there because the first thing a stolen key does is look around.
`iam:AttachUserPolicy`, dani's action, is on it.

This script walks every user, reads every inline and attached policy, and prints each `Allow` of a
risky action, or of a wildcard that includes them all. Its list is a subset of the quarantine
policy's, kept short enough to read:

```sh
cat > iam-writers.sh <<'EOF'
#!/usr/bin/env bash
# Every IAM user, and every Allow on it that can change who may do what.
# Run it with a key that may read IAM. Prints: user, policy, action.
risky='["*", "iam:*", "iam:AttachUserPolicy", "iam:PutUserPolicy",
  "iam:AttachGroupPolicy", "iam:PutGroupPolicy", "iam:AddUserToGroup",
  "iam:AttachRolePolicy", "iam:PutRolePolicy", "iam:UpdateAssumeRolePolicy",
  "iam:CreatePolicyVersion", "iam:SetDefaultPolicyVersion", "iam:PassRole",
  "iam:CreateAccessKey", "iam:CreateLoginProfile", "iam:UpdateLoginProfile"]'

flag() { # USER POLICY, with the policy document on stdin
  jq -r --arg u "$1" --arg p "$2" --argjson risky "$risky" '
    [.Statement] | flatten | .[] | select(.Effect == "Allow")
    | [.Action] | flatten | .[] | select(. as $a | $risky | index($a))
    | "\($u)\t\($p)\t\(.)"'
}

for u in $(aws iam list-users --query "Users[].UserName" --output text); do
  for p in $(aws iam list-user-policies --user-name "$u" --query PolicyNames --output text); do
    aws iam get-user-policy --user-name "$u" --policy-name "$p" \
      --query PolicyDocument | flag "$u" "inline:$p"
  done
  for a in $(aws iam list-attached-user-policies --user-name "$u" \
      --query "AttachedPolicies[].PolicyArn" --output text); do
    v=$(aws iam get-policy --policy-arn "$a" --query Policy.DefaultVersionId --output text)
    aws iam get-policy-version --policy-arn "$a" --version-id "$v" \
      --query PolicyVersion.Document | flag "$u" "${a##*/}"
  done
done
EOF
```

```
ana@laptop:~/aws$ bash iam-writers.sh
admin	AdministratorAccess	*
dani	inline:manage-users	iam:AttachUserPolicy
dani	AdministratorAccess	*
```

Three rows. `admin` holds `AdministratorAccess` by design: it is the account's administrator, and a
review expects to find it, once, with MFA. dani's two rows are the path, the inline policy that
opened it and the managed policy it was used to attach.

**The script is honest about what it can see, so read its limits before trusting a clean run:**

- it reads users only. Groups pass their policies to every member, and a role's policies are what a
  function or a pipeline holds; both need the same loop;
- it matches exact strings. `iam:Put*` or `iam:Attach*` grant the same actions and print nothing;
- it ignores `NotAction`, which allows everything except a list. AWS's `PowerUserAccess`, caio's
  policy, is written that way, excluding `iam:*`; a `NotAction` that excluded something else would
  allow IAM and go unreported;
- it ignores the `Resource`. An `iam:PassRole` limited to one harmless role is printed as loudly as
  one on `*`.

That is the honest argument for a real tool, lesson 16's subject: the rules above are tedious to get
right and easy to get almost right. The argument for writing this one first is that you now know
what such a tool is checking, and can read its findings instead of trusting them.
