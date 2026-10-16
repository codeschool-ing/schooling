---
title: A ceiling, never a grant
version: 1
---

**A service control policy sets the most that anybody in an account may do, and gives nobody
anything.** The wrong picture is the one the word "policy" suggests after a few weeks of IAM: attach
an SCP allowing S3 to an account and its developers can use S3. They cannot, not because of the
SCP. An SCP is a filter that every request in the account passes through on its way to IAM's
decision, and it can only take permissions away.

## Two filters in a row

A request from an identity in a member account is allowed only if **both** of these say yes:

- **the account's own IAM**, the policies attached to the user or role, which lessons 6 to 8 teach;
- **every SCP between the account and the root**, which this lesson teaches.

**What the identity can actually do is what is in both.** IAM grants; the SCPs set a ceiling over
the grant. A role with `AdministratorAccess` under an SCP that allows only EC2 and S3 can use EC2
and S3. A role allowed only `s3:GetObject` under an SCP that allows everything can still only read
objects. And an explicit `Deny` in either filter ends the question, whatever the other says.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l04-filter\" aria-label=\"Two overlapping circles. The left one is what the role's IAM policies allow: ec2, s3 and rds. The right one is what the SCPs above the account allow: ec2, s3 and lambda. Only the overlap, ec2 and s3, is what the role can do. rds is granted by IAM and cut by the SCPs; lambda is allowed by the SCPs and granted by nobody, so it is refused as well.\"><circle cx=\"285.0\" cy=\"160.0\" r=\"120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"435.0\" cy=\"160.0\" r=\"120\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"215.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">what the role's IAM allows</text><text x=\"505.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">what the SCPs allow</text><text x=\"225.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rds:*</text><text x=\"225.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">cut by an SCP</text><text x=\"495.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">lambda:*</text><text x=\"495.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">granted by nobody</text><text x=\"360.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ec2:*</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">s3:*</text><text x=\"360.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">only the overlap reaches the account; a Deny in either takes an action out of it</text></svg>", "caption": "IAM grants, the SCPs set the ceiling, and the role gets what is in both."}
```

**The filter covers every identity in a member account, its root user included.** That is the
property nothing in the account can give itself: an administrator of `shop-prod` can change any IAM
policy in `shop-prod`, and no SCP. Two things are outside the filter. **The management account is
never affected by an SCP**, attached anywhere, which is lesson 3's reason for it to run nothing. And
**service-linked roles**, the roles AWS services create in an account to act for themselves, are
not restricted by SCPs either.

## Turning them on, and the policy that is already there

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. Then build a small part of lesson 3's tree: `shop-prod` in `Workloads/Prod`, and
`sandbox` in `Sandbox`. The ids go into variables as they are made, and lesson 3's `account`
function comes back for the account numbers:

```
ana@laptop:~/aws$ account() { aws organizations list-accounts --query "Accounts[?Name=='$1'].Id" --output text; }
ana@laptop:~/aws$ aws organizations create-organization --query Organization.Id --output text
o-vpkre95at2
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ workloads=$(aws organizations create-organizational-unit --parent-id $root --name Workloads --query OrganizationalUnit.Id --output text)
ana@laptop:~/aws$ prod=$(aws organizations create-organizational-unit --parent-id $workloads --name Prod --query OrganizationalUnit.Id --output text)
ana@laptop:~/aws$ sandbox=$(aws organizations create-organizational-unit --parent-id $root --name Sandbox --query OrganizationalUnit.Id --output text)
ana@laptop:~/aws$ for a in shop-prod sandbox; do aws organizations create-account --email aws+$a@example.com --account-name $a --query "CreateAccountStatus.[AccountId,AccountName]" --output text; done
896527596556	shop-prod
798632694501	sandbox
ana@laptop:~/aws$ aws organizations move-account --account-id $(account shop-prod) --source-parent-id $root --destination-parent-id $prod
ana@laptop:~/aws$ aws organizations move-account --account-id $(account sandbox) --source-parent-id $root --destination-parent-id $sandbox
```

Now the policy type itself. Lesson 3 found the root's list empty in moto; in AWS the type is enabled
when an organisation is created with all features, so this first command is only needed here:

```
ana@laptop:~/aws$ aws organizations list-roots --query "Roots[0].PolicyTypes"
[]
ana@laptop:~/aws$ aws organizations enable-policy-type --root-id $root --policy-type SERVICE_CONTROL_POLICY --query Root.PolicyTypes
[
    {
        "Type": "SERVICE_CONTROL_POLICY",
        "Status": "ENABLED"
    }
]
ana@laptop:~/aws$ aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query "Policies[].[Id,Name,AwsManaged]" --output text
p-FullAWSAccess	FullAWSAccess	True
ana@laptop:~/aws$ aws organizations describe-policy --policy-id p-FullAWSAccess --query Policy.Content --output text
{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Action": "*", "Resource": "*"}]}
ana@laptop:~/aws$ for t in $root $workloads $prod $(account shop-prod); do echo "$t: $(aws organizations list-policies-for-target --target-id $t --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text)"; done
r-ucqy: FullAWSAccess
ou-ucqy-v4g2cy3n: FullAWSAccess
ou-ucqy-7pqpa5j0: FullAWSAccess
896527596556: FullAWSAccess
```

**One SCP exists before anybody writes one: `FullAWSAccess`**, managed by AWS, allowing every action
on every resource. It is attached to the root, to each OU and to each account, as the loop shows
level by level, and new OUs and accounts get it too. **That is why turning SCPs on changes
nothing**: the ceiling starts at the top of the room. Every guardrail after this point is written
against it, and the next section says the two ways to do that.
