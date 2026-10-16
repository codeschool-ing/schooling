---
title: Permission boundaries, session policies and delegation
version: 1
---

**A permission boundary is a managed policy set on a user or a role as a ceiling: the identity
can do only what its own policies allow and the boundary allows, both at once.** It is the
intersection, never the sum. The wrong picture is the boundary as one more policy that adds
permissions. A boundary of `s3:*` on a user with no policies gives that user nothing at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l08-boundary\" aria-label=\"A permission boundary as an intersection. The identity policies of a role allow S3 and IAM; its permission boundary allows S3 and CloudWatch Logs. Only the overlap, S3, is allowed: s3:GetObject works. iam:ListUsers is in the identity policies and not in the boundary, so it is denied. logs:PutLogEvents is in the boundary and in no policy, so it is denied too: a boundary grants nothing.\"><rect x=\"60.0\" y=\"30.0\" width=\"360.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><rect x=\"300.0\" y=\"60.0\" width=\"360.0\" height=\"170.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><rect x=\"300.0\" y=\"60.0\" width=\"120.0\" height=\"140.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">identity policies</text><text x=\"180.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allow S3 and IAM</text><text x=\"180.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">iam:ListUsers</text><text x=\"180.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">denied: outside the boundary</text><text x=\"550.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">permission boundary</text><text x=\"550.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">allows S3 and Logs</text><text x=\"550.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logs:PutLogEvents</text><text x=\"550.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">denied: no policy grants it</text><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">allowed</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3:GetObject</text></svg>", "caption": "What a boundary leaves is the overlap. It removes what lies outside it and adds nothing."}
```

## A boundary in moto, and moto ignoring it

The boundary is an ordinary customer-managed policy. Here it allows S3 and nothing else:

```
ana@laptop:~/aws$ aws iam create-policy --policy-name s3-only-boundary --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}' --query Policy.Arn --output text
arn:aws:iam::123456789012:policy/s3-only-boundary
ana@laptop:~/aws$ aws iam create-user --user-name dani --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary --query User.PermissionsBoundary
null
ana@laptop:~/aws$ aws iam put-user-permissions-boundary --user-name dani --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**On a user, moto does not even keep it.** `create-user --permissions-boundary` succeeds and the
answer carries no boundary. `put-user-permissions-boundary`, the command that sets one on an
existing user, is not implemented: moto answers HTTP 500 and the command line prints moto's error
page. On a role, moto stores the boundary, so the measurement is made with a role. It is called
`app-admin`, holds `AdministratorAccess`, has the S3-only boundary, and trusts `admin`:

```
ana@laptop:~/aws$ aws iam create-role --role-name app-admin --permissions-boundary arn:aws:iam::123456789012:policy/s3-only-boundary --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::123456789012:user/admin"},"Action":"sts:AssumeRole"}]}' --query Role.PermissionsBoundary
{
    "PermissionsBoundaryType": "PermissionsBoundaryPolicy",
    "PermissionsBoundaryArn": "arn:aws:iam::123456789012:policy/s3-only-boundary"
}
ana@laptop:~/aws$ aws iam attach-role-policy --role-name app-admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/app-admin --role-session-name try-boundary)
ana@laptop:~/aws$ with_session "$r" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/app-admin/try-boundary
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text
admin	caio	dani
ana@laptop:~/aws$ with_session "$r" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
logo.png
```

**The session listed every user. AWS would have refused it**: `iam:ListUsers` is allowed by
`AdministratorAccess` and not by the boundary, so the intersection does not contain it. The
answer would be an `AccessDenied` naming the boundary as the reason. The S3 call would have
worked in both. That refusal was not run here, since moto stores boundaries and never applies them.
It is AWS's documented behaviour, and the reason the figure above is drawn as an intersection.

## Session policies, tested

A session policy is a policy passed to `assume-role` with `--policy`, and it limits that one
session the same way a boundary limits an identity. It is how one role is handed out more narrowly
for one job, without making a second role. **Tested here with a `Deny` on every IAM action, moto
ignored it too**:

```
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/app-admin --role-session-name narrowed --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"iam:*","Resource":"*"}]}')
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text
admin	caio	dani
```

AWS would refuse that `list-users` twice over, once for the boundary and once for the session
policy. **Neither layer was run here**; both are taught from AWS's documentation.

## Delegation: letting a team make roles safely

Boundaries exist for one problem above all. The shop's developers need to create roles for their
own applications. But **whoever can create a role and attach `AdministratorAccess` to it can make
themselves an administrator**: create the role, trust yourself, assume it. Refusing developers
`iam:CreateRole` makes the platform team a queue for every new service.

The pattern AWS documents is to let them create roles **only with the boundary attached**, and to
deny them any way of loosening it. The condition key `iam:PermissionsBoundary` is the boundary
named in the request. Save this as `~/aws/delegate-roles.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CreateAppRolesOnlyWithTheBoundary",
      "Effect": "Allow",
      "Action": ["iam:CreateRole", "iam:AttachRolePolicy", "iam:PutRolePolicy"],
      "Resource": "arn:aws:iam::123456789012:role/app-*",
      "Condition": {
        "StringEquals": {
          "iam:PermissionsBoundary": "arn:aws:iam::123456789012:policy/app-boundary"
        }
      }
    },
    {
      "Sid": "NeverLoosenTheBoundary",
      "Effect": "Deny",
      "Action": ["iam:DeleteRolePermissionsBoundary", "iam:CreatePolicyVersion", "iam:DeletePolicy", "iam:SetDefaultPolicyVersion"],
      "Resource": [
        "arn:aws:iam::123456789012:role/app-*",
        "arn:aws:iam::123456789012:policy/app-boundary"
      ]
    }
  ]
}
```

**The first statement makes the boundary the price of a new role**: a `CreateRole` that does not
name `app-boundary` has no `Allow`, and is refused. The second keeps the price from being taken
back: no removing the boundary from a role, and no editing or deleting the boundary itself. Whatever
a developer attaches to an `app-` role afterwards, even `AdministratorAccess`, the boundary caps.

moto cannot judge this policy, and in the lab it errs the other way. It compares IAM calls with the
resource `*` rather than with the role's ARN, so a statement scoped to `role/app-*` never matches
there. It also treats the condition as met. With the boundary, the policy and bia created, and the
policy attached to her, bia is refused the one call that AWS would allow:

```
ana@laptop:~/aws$ aws iam create-policy --policy-name app-boundary --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:*","logs:*"],"Resource":"*"}]}' --query Policy.Arn --output text
arn:aws:iam::123456789012:policy/app-boundary
ana@laptop:~/aws$ aws iam create-policy --policy-name delegate-roles --policy-document file://delegate-roles.json --query Policy.Arn --output text
arn:aws:iam::123456789012:policy/delegate-roles
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::123456789012:policy/delegate-roles
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
ana@laptop:~/aws$ with_key "$bia" aws iam create-role --role-name app-web --permissions-boundary arn:aws:iam::123456789012:policy/app-boundary --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws: [ERROR]: An error occurred (AccessDenied) when calling the CreateRole operation: User: arn:aws:iam::123456789012:user/bia is not authorized to perform: iam:CreateRole
```

**A refusal in moto is not proof that a policy is wrong, any more than a success is proof that it is
right.** For this pattern, the checks that count are the ones the last section names, run against
AWS.
