---
title: Four guardrails, written out
version: 1
---

**A guardrail is a deny that no administrator in the account can lift.** The shop writes SCPs for
that reason alone. The accounts' own administrators, `AdministratorAccess` and the
`OrganizationAccountAccessRole` included, can do anything IAM allows, and these four things should
not be among them. Each is a policy file, created once in the management account and attached to
the branch it protects. Save each one in `~/aws/scp/`, the directory from the section before,
under the name given above it.

## Nobody leaves the organisation

`scp/deny-leaving.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeavingTheOrganisation",
      "Effect": "Deny",
      "Action": "organizations:LeaveOrganization",
      "Resource": "*"
    }
  ]
}
```

**An account that leaves walks out of every rule attached to the tree**, the other three in this
section among them. Lesson 3 said a created account cannot leave until it has a payment method and
a support plan. This policy keeps it from leaving even then, until the management account removes it.

## Nothing outside São Paulo

`scp/sa-east-1-only.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideSaoPaulo",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "sts:*",
        "organizations:*",
        "cloudfront:*",
        "route53:*",
        "budgets:*",
        "ce:*",
        "health:*",
        "support:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["sa-east-1"]
        }
      }
    }
  ]
}
```

`aws:RequestedRegion` is the region a request is sent to, and the condition makes the deny apply to
every request that is not for `sa-east-1`. **`NotAction` is the half that people get wrong.** It
means "every action except these", and the exceptions are the **global services**. IAM, STS,
Organizations, CloudFront, Route 53 and the billing services answer from one place, normally
`us-east-1`, whatever region the caller works in. Deny them outside São Paulo and the shop could no
longer create a user or read its own bill. The list above is shorter than the one in AWS's own
example of this policy, which carries more global services. A company copies AWS's list and removes
what it does not use, never the other way round.

**The shop's reason is the data, and the bill.** Nothing it runs should be anywhere else, so a
machine started in Virginia by mistake, or by somebody who stole a key, is refused rather than
found on the invoice a month later.

## Nobody switches off the cameras

`scp/protect-security-services.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProtectCloudTrail",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail",
        "cloudtrail:PutEventSelectors"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ProtectGuardDuty",
      "Effect": "Deny",
      "Action": [
        "guardduty:DeleteDetector",
        "guardduty:UpdateDetector",
        "guardduty:DisassociateFromAdministratorAccount"
      ],
      "Resource": "*"
    }
  ]
}
```

**CloudTrail records every API call in an account, and GuardDuty watches those records and the
network for signs of an intruder.** The first thing an intruder with an administrator's key does
is turn both off, and the first thing an engineer debugging a noisy alert does is the same. Neither
should be able to. Lesson 5 places both services, and the account their records go to.

## Nobody but the platform touches the deployer

`scp/protect-deployer.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProtectTheDeployerRole",
      "Effect": "Deny",
      "Action": [
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:UpdateAssumeRolePolicy",
        "iam:DeleteRole"
      ],
      "Resource": "arn:aws:iam::*:role/deployer",
      "Condition": {
        "ArnNotLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:role/OrganizationAccountAccessRole"
        }
      }
    }
  ]
}
```

`deployer` is the role the shop's pipeline uses to release software. So **whoever can change its
permissions or its trust policy can make the pipeline do anything**, or make anybody the pipeline.
`aws:PrincipalArn` is the ARN of the identity making the request, and the condition excludes one:
the role the management account comes in through. Everyone else, administrators of `shop-prod`
included, is refused. The `*` in the account field makes one policy work in every account of the
branch it is attached to.

## Creating and attaching them

With the four files saved, create the policies and attach them, finding each id with the
`policy` function from the section before:

```
ana@laptop:~/aws$ for p in deny-leaving sa-east-1-only protect-security-services protect-deployer; do aws organizations create-policy --name $p --type SERVICE_CONTROL_POLICY --description "shop guardrail: $p" --content file://scp/$p.json --query Policy.PolicySummary.Id --output text; done
p-zwlh2zo3
p-44m2vi13
p-yj6ovjex
p-p6z711fr
ana@laptop:~/aws$ for p in deny-leaving sa-east-1-only protect-security-services; do aws organizations attach-policy --policy-id $(policy $p) --target-id $root; done
ana@laptop:~/aws$ aws organizations attach-policy --policy-id $(policy protect-deployer) --target-id $workloads
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id $root --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text
FullAWSAccess	deny-leaving	sa-east-1-only	protect-security-services
ana@laptop:~/aws$ aws organizations list-targets-for-policy --policy-id $(policy protect-deployer) --query "Targets[].[Name,Type]" --output text
Workloads	ORGANIZATIONAL_UNIT
```

The first three go on the root, so they cover every member account. The deployer's protection goes
on `Workloads`, where the deployer role lives. **The management account is untouched by all four**,
which is lesson 3's reason for it to run nothing.

## What moto does with them: nothing

The organisation now forbids every region but `sa-east-1` to `shop-prod`. Ask `shop-prod` for a
network in Virginia, through the profile from lesson 2, written again for this moto's account:

```
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_arn arn:aws:iam::$(account shop-prod):role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-prod.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_session_name ana
ana@laptop:~/aws$ aws --profile shop-prod ec2 create-vpc --cidr-block 10.99.0.0/16 --region us-east-1 --query Vpc.VpcId --output text
vpc-2c9aa2ce3234ff9c3
```

**moto made the VPC. AWS would have refused it**, and its documentation says how: the call fails
with `AccessDenied`, and the message says the request was denied by an explicit deny in a service
control policy. **That refusal was not run here.** moto stores SCPs, attaches them and lists them,
and decides nothing with them. This course also checked it with moto's permission checking switched
on, which lesson 7 explains. With an IAM policy allowing the call, the VPC in Virginia is
still created. Everything this lesson says about what an SCP refuses comes from AWS's
documentation, and the lab can only show you the shape.

moto checks none of the limits either. Tried for this course and not shown: it accepted a policy
that was not valid JSON, a sixth policy on one target and a policy of 9,771 characters. AWS refuses
all three, since an SCP must be valid policy language, a target takes at most five SCPs and a
policy at most 5,120 characters.

## The policies beside SCPs

Organizations has more policy types than SCPs, and two of them are worth recognising here.

**Resource control policies**, RCPs, arrived in 2024 as the other half of an SCP. An SCP limits what
the identities in an account may do. An RCP limits what may be done to the resources in an
account, by anybody, including identities from outside the organisation. The classic use is "no
bucket of ours may be read by an account that is not ours", which no SCP can say, since the reader
is not under the SCP. An RCP is a filter in the same way: it grants nothing.

**Declarative policies** set a configuration of a service across the organisation, starting with
EC2, such as refusing to make machine images public. The service enforces the setting itself, so it
holds even for a request no SCP anticipated. Both types appear in the CLI as values of
`--policy-type`, `RESOURCE_CONTROL_POLICY` and `DECLARATIVE_POLICY_EC2`. This course goes no
further with them.
