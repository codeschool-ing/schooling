---
title: A guardrail that keeps new copies in Brazil
version: 1
---

**An inventory finds the copy after it exists. A guardrail refuses the request that would create it.
In AWS the guardrail for residency is a service control policy, an SCP, that denies every action
requested outside `sa-east-1`, attached by the organisation to the accounts that hold patient data.**
An SCP is a layer that can only take permissions away and never grants any, used here for
geography.

## The policy

It is a `Deny` with a condition on `aws:RequestedRegion`, the region a request is addressed to. Save
it as `only-sao-paulo.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideSaoPaulo",
      "Effect": "Deny",
      "NotAction": ["iam:*", "organizations:*", "sts:*", "support:*", "cloudfront:*", "route53:*", "budgets:*"],
      "Resource": "*",
      "Condition": {"StringNotEquals": {"aws:RequestedRegion": ["sa-east-1"]}}
    }
  ]
}
```

**`NotAction` is the part people get wrong.** Some AWS services are global: IAM, Organizations,
CloudFront, Route 53 and a few more answer from one place whatever region you work in, and their
requests do not carry `sa-east-1`. A plain `"Action": "*"` would deny them too, and the account
could no longer manage its own users. So the statement denies everything *except* the global
services, and only when the requested region is not São Paulo. AWS's documentation carries a longer
list of exceptions in its own example of this policy, and the list should be checked against it
before use.

## Attaching it

An SCP belongs to an organisation, so the clinic needs one, even with a single account. In the lab,
create it, switch SCPs on, and attach the policy at the root, which covers every account below it:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-7yfo4aeh7t
ana@laptop:~/aws$ root=$(aws organizations list-roots --query "Roots[0].Id" --output text)
ana@laptop:~/aws$ aws organizations enable-policy-type --root-id "$root" --policy-type SERVICE_CONTROL_POLICY --query "Root.PolicyTypes[].Status" --output text
ENABLED
ana@laptop:~/aws$ policy=$(aws organizations create-policy --name only-sao-paulo --type SERVICE_CONTROL_POLICY --description "Keep new resources in Brazil" --content file://only-sao-paulo.json --query Policy.PolicySummary.Id --output text)
ana@laptop:~/aws$ aws organizations attach-policy --policy-id "$policy" --target-id "$root"
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id "$root" --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text
FullAWSAccess	only-sao-paulo
```

Two policies sit on the root. `FullAWSAccess` is the one AWS attaches when SCPs are switched on,
and it allows everything; since an SCP can only limit, the pair reads as *everything is allowed,
except outside São Paulo*. Removing `FullAWSAccess` without putting an allow in its place would leave
every member account with nothing allowed at all, which is the opposite mistake.

Now ask for a bucket in Ireland:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-test-eu --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1 --query Location --output text
/clinic-test-eu
```

**moto created it.** This is the row of lesson 1's table that says SCPs are stored and never
enforced, and here is what it costs: the lab cannot show this guardrail working. Two things are true
of AWS instead, and both come from its documentation, **not run**:

- in a **member account** of the organisation, the same request is refused with `AccessDenied`,
  and the message names a service control policy as the reason;
- in the **management account**, the one that created the organisation, it succeeds, because **an
  SCP never applies to the management account**. That is AWS's design, not a gap in the lab, and it
  is why patient data belongs in a member account, with the management account kept for running the
  organisation and nothing else.

moto would not help with an identity policy carrying the same condition either: it ignores
conditions, so a `Deny` with `aws:RequestedRegion` would refuse every region, São Paulo included.
**The lab can check that the guardrail is written and attached. Only AWS can check that it bites**,
and a policy like this one is tested in a member account of a real organisation before anybody
relies on it.

## Where the guardrail stops

It controls where **new requests** go. It does not move the `clinic-backups-us` bucket that
already exists; the inventory found that, and somebody has to decide to move it or to record why it
stays. And it does not stop data leaving through the application: a booking system that e-mails a
patient's results to a foreign mail service has transferred data abroad without making a single
AWS request outside São Paulo. Residency is a property of every path the data takes, and a policy
on the API covers one of them.
