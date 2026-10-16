---
title: Permission sets, users, groups and assignments, built in moto
version: 1
---

**Everything an administrator does in Identity Center is an API call, and moto answers most of
them.** This section builds the shop's arrangement from the command line: two accounts, two
permission sets, two people in two groups, and three assignments. It also measures the one step
moto leaves out, which is the role an assignment should create.

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. Nothing here needs moto's permission checking. Ask first whether there is an Identity
Center at all:

```
ana@laptop:~/aws$ aws sso-admin list-instances --query "Instances[].[InstanceArn,IdentityStoreId,Status]" --output text
arn:aws:sso:::instance/ssoins-o3rwaaubjxq19hji	d-2mpgvds33k	ACTIVE
```

**moto has one already, before anything was created.** In AWS, Identity Center is enabled once, in
the management account of the organisation, and that makes an **organisation instance**: the
`ssoins-` ARN that every command below names, and an **identity store**, the `d-` id, which is the
Identity Center directory of the previous section. There are also account instances, which serve
applications and cannot give access to AWS accounts; this course does not use them.

## Two accounts to give access to

Assignments point at accounts of the organisation, so make the organisation and the two accounts the
shop's people work in. Lesson 3 built the whole tree; this lesson needs two leaves of it:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-3bdzmumold
ana@laptop:~/aws$ aws organizations create-account --account-name shop-prod --email aws+shop-prod@example.com --query CreateAccountStatus.[State,AccountId] --output text
SUCCEEDED	834307267662
ana@laptop:~/aws$ aws organizations create-account --account-name shop-staging --email aws+shop-staging@example.com --query CreateAccountStatus.[State,AccountId] --output text
SUCCEEDED	132607488945
ana@laptop:~/aws$ PROD=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-prod\`].Id" --output text)
ana@laptop:~/aws$ STAGING=$(aws organizations list-accounts --query "Accounts[?Name==\`shop-staging\`].Id" --output text)
ana@laptop:~/aws$ echo $PROD $STAGING
834307267662 132607488945
```

The ids moto invents will differ in your run. **The variables carry them**, so every later command
can be typed exactly as it is printed here. Keep the instance and the store in two more:

```
ana@laptop:~/aws$ INSTANCE=$(aws sso-admin list-instances --query "Instances[0].InstanceArn" --output text)
ana@laptop:~/aws$ STORE=$(aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text)
```

## A permission set is a role, written once

The shop needs two kinds of access. `ReadOnly` is for looking at production: AWS's managed
`ReadOnlyAccess`, plus one refusal written inline, because the backups hold customer data and
reading everything should not include them. Save the refusal as `~/aws/no-backups.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::shop-backups/*"
    }
  ]
}
```

```
ana@laptop:~/aws$ READONLY=$(aws sso-admin create-permission-set --instance-arn $INSTANCE --name ReadOnly --session-duration PT4H --description "Read everything, change nothing" --query PermissionSet.PermissionSetArn --output text)
ana@laptop:~/aws$ echo $READONLY
arn:aws:sso:::instance/ssoins-o3rwaaubjxq19hji/ps-4vulirahzinwsp7f
ana@laptop:~/aws$ aws sso-admin attach-managed-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --managed-policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ aws sso-admin put-inline-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --inline-policy file://no-backups.json
ana@laptop:~/aws$ aws sso-admin describe-permission-set --instance-arn $INSTANCE --permission-set-arn $READONLY --query "PermissionSet.[Name,SessionDuration]" --output text
ReadOnly	PT4H
```

**`--session-duration` is how long the session lasts once opened**, written as an ISO 8601
duration: `PT4H` is four hours, and AWS accepts from one hour to twelve. A permission set carries
the same three kinds of policy a role does, as lesson 7 described them: AWS-managed ones like
`ReadOnlyAccess`, customer-managed ones referenced by name, and one inline policy. The second
permission set is `Developer`, AWS's `PowerUserAccess`, for eight hours in staging:

```
ana@laptop:~/aws$ DEVELOPER=$(aws sso-admin create-permission-set --instance-arn $INSTANCE --name Developer --session-duration PT8H --query PermissionSet.PermissionSetArn --output text)
ana@laptop:~/aws$ aws sso-admin attach-managed-policy-to-permission-set --instance-arn $INSTANCE --permission-set-arn $DEVELOPER --managed-policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

`PowerUserAccess` allows everything except managing IAM and the organisation, which is the usual
line between building in an account and governing it.

## People and groups in the identity store

The identity store is a separate API, `identitystore`, and it knows nothing of accounts or
policies: only users, groups and who belongs to which. **Assign to groups, never to people one by
one**, so that a new developer is one membership rather than three assignments:

```
ana@laptop:~/aws$ BIA=$(aws identitystore create-user --identity-store-id $STORE --user-name bia --display-name "Bia" --name GivenName=Bia,FamilyName=Lima --emails Value=bia@example.com,Type=work,Primary=true --query UserId --output text)
ana@laptop:~/aws$ CAIO=$(aws identitystore create-user --identity-store-id $STORE --user-name caio --display-name "Caio" --name GivenName=Caio,FamilyName=Souza --emails Value=caio@example.com,Type=work,Primary=true --query UserId --output text)
ana@laptop:~/aws$ DEVS=$(aws identitystore create-group --identity-store-id $STORE --display-name developers --query GroupId --output text)
ana@laptop:~/aws$ DATA=$(aws identitystore create-group --identity-store-id $STORE --display-name data --query GroupId --output text)
ana@laptop:~/aws$ aws identitystore create-group-membership --identity-store-id $STORE --group-id $DEVS --member-id UserId=$BIA --query MembershipId --output text
492337fd-2fa7-45a1-8ba3-42c28d572501
ana@laptop:~/aws$ aws identitystore create-group-membership --identity-store-id $STORE --group-id $DATA --member-id UserId=$CAIO --query MembershipId --output text
0d28d709-e5ee-4cb5-bae4-d1355bd8570f
ana@laptop:~/aws$ aws identitystore list-users --identity-store-id $STORE --query "Users[].[UserName,UserId]" --output text
bia	25741175-c2a9-4054-83e8-0354a8048314
caio	aa4a644c-4e4e-4278-aae3-5b7c94f2b655
ana@laptop:~/aws$ aws identitystore list-groups --identity-store-id $STORE --query "Groups[].[DisplayName,GroupId]" --output text
developers	67306502-6c80-4049-951f-a3687c3539c9
data	cdcd7a46-ca7b-4c2a-a37b-31a63fa15b16
```

With an external identity provider and SCIM, none of these commands would be typed: the users,
the groups and the memberships would arrive from Google. Everything after this point is the same
either way.

## Three assignments

An assignment is the triple from the previous section: **a principal, a permission set, an
account**. The developers get `Developer` in staging and `ReadOnly` in production; the data group
gets `ReadOnly` in production:

```
ana@laptop:~/aws$ aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $STAGING --permission-set-arn $DEVELOPER --principal-type GROUP --principal-id $DEVS --query AccountAssignmentCreationStatus.Status --output text
SUCCEEDED
ana@laptop:~/aws$ aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $PROD --permission-set-arn $READONLY --principal-type GROUP --principal-id $DEVS --query AccountAssignmentCreationStatus.Status --output text
SUCCEEDED
ana@laptop:~/aws$ aws sso-admin create-account-assignment --instance-arn $INSTANCE --target-type AWS_ACCOUNT --target-id $PROD --permission-set-arn $READONLY --principal-type GROUP --principal-id $DATA --query AccountAssignmentCreationStatus.Status --output text
SUCCEEDED
ana@laptop:~/aws$ aws sso-admin list-account-assignments --instance-arn $INSTANCE --account-id $PROD --permission-set-arn $READONLY --query "AccountAssignments[].[PrincipalType,PrincipalId]" --output text
GROUP	67306502-6c80-4049-951f-a3687c3539c9
GROUP	cdcd7a46-ca7b-4c2a-a37b-31a63fa15b16
```

In AWS this call is asynchronous: it answers `IN_PROGRESS`, and `describe-account-assignment-creation-status`
reports `SUCCEEDED` once the role exists in the account. moto answers `SUCCEEDED` at once. The
listing names the two groups by their ids, the same ones `list-groups` printed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l11-assignments\" aria-label=\"The three assignments as a grid of groups against accounts. Developers, with Bia in it: ReadOnly in shop-prod and Developer in shop-staging. Data, with Caio in it: ReadOnly in shop-prod and nothing in shop-staging. Each filled cell is one assignment, and one role Identity Center creates in that account.\"><text x=\"140.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">group</text><rect x=\"265.0\" y=\"24.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><rect x=\"485.0\" y=\"24.0\" width=\"190.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><rect x=\"40.0\" y=\"82.0\" width=\"200.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">developers</text><text x=\"140.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bia</text><rect x=\"40.0\" y=\"162.0\" width=\"200.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">data</text><text x=\"140.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">caio</text><rect x=\"265.0\" y=\"82.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ReadOnly</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one assignment</text><rect x=\"485.0\" y=\"82.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Developer</text><text x=\"580.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one assignment</text><rect x=\"265.0\" y=\"162.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ReadOnly</text><text x=\"360.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one assignment</text><rect x=\"485.0\" y=\"162.0\" width=\"190.0\" height=\"56.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"580.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">no access</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">each filled cell: a group, a permission set, an account, and one role there</text></svg>", "caption": "An assignment is a cell of this grid. A new developer joins a row, and gets every cell in it."}
```

## The step moto leaves out

If the assignment worked as it does in AWS, `shop-prod` now holds a role called
`AWSReservedSSO_ReadOnly_…`. Look inside the account, through the role that lesson 3 showed moto
makes in every new account. The `--query` turns the three credentials `assume-role` returns into
three `NAME=value` words, and `env` runs `list-roles` with them:

```
ana@laptop:~/aws$ env $(aws sts assume-role --role-arn arn:aws:iam::$PROD:role/OrganizationAccountAccessRole --role-session-name ana --query "Credentials.[join(\`=\`,[\`AWS_ACCESS_KEY_ID\`,AccessKeyId]),join(\`=\`,[\`AWS_SECRET_ACCESS_KEY\`,SecretAccessKey]),join(\`=\`,[\`AWS_SESSION_TOKEN\`,SessionToken])]" --output text) aws iam list-roles --query "Roles[].RoleName" --output text
OrganizationAccountAccessRole
ana@laptop:~/aws$ aws sso-admin list-permission-sets-provisioned-to-account --instance-arn $INSTANCE --account-id $PROD
{
    "PermissionSets": []
}
```

**moto records the assignments and provisions nothing.** The account holds only the role moto made
when the account was created, and `list-permission-sets-provisioned-to-account` answers an empty
list where AWS would name `ReadOnly`. So the lab can build and inspect the whole administrative
side of Identity Center, and cannot show a person using it: the role, the portal and the sign-in
are AWS's documented behaviour, described in the previous section and the next one.
