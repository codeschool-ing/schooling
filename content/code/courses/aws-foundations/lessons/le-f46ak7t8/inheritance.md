---
title: Inherited down the tree: allowed at every level, denied at none
version: 1
---

**A request passes the SCPs only if every level between its account and the root allows it, and
no level denies it.** The wrong picture is inheritance as in a file system, where a setting on a
folder is copied into each file below it and the file can override it. An SCP is never copied and
never overridden. Each level of the path is a separate filter, and the request walks through them
all: the root, each OU on the way down, and the account itself.

The two halves of the rule work differently, and they give the two ways of writing SCPs.

## A deny anywhere wins: the deny list

**Keep `FullAWSAccess` everywhere and add policies that deny.** Every level allows everything, so the
allow half of the rule is always met; the guardrails are `Deny` statements, and a deny attached at
any level, the root or the account, stops the request. This is the **deny list**, and it is the
strategy AWS describes first and most companies use. It has one property that matters on a busy
day: a new AWS service is allowed the day it launches, and nobody has to remember to add it.

The shop uses a deny list for everything except its sandbox. The next section writes its four
denies.

## An allow at every level: the allow list

**Replace `FullAWSAccess` at a level with a policy that allows only some services**, and from then
on only those services pass that level. This is the **allow list**. Its strength is that whatever
is not on the list is refused, a new service included; its cost is exactly the same fact, since
every service somebody legitimately needs has to be added first.

The allow has to be present **at every level of the path**. An account whose own SCPs allow
everything still loses whatever its OU's allow list leaves out, and an account under an OU that
allows everything is still limited by an allow list attached to the account itself. The levels do
not add up; they intersect.

The shop's `Sandbox` OU gets one, so that experiments stay with cheap services that are easy to
clear out. Make a directory for SCP files with `mkdir -p ~/aws/scp`, and save this one there as
`scp/sandbox-allow-list.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SandboxMayUseOnlyThese",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "lambda:*",
        "dynamodb:*",
        "cloudwatch:*",
        "logs:*",
        "iam:*",
        "sts:*"
      ],
      "Resource": "*"
    }
  ]
}
```

Then create it, attach it to `Sandbox`, and only then take `FullAWSAccess` off. A `policy` function,
like lesson 3's two, finds a policy's id by its name:

```
ana@laptop:~/aws$ policy() { aws organizations list-policies --filter SERVICE_CONTROL_POLICY --query "Policies[?Name=='$1'].Id" --output text; }
ana@laptop:~/aws$ aws organizations create-policy --name sandbox-allow-list --type SERVICE_CONTROL_POLICY --description "What the sandbox may use" --content file://scp/sandbox-allow-list.json --query Policy.PolicySummary.Id --output text
p-18q5xsw4
ana@laptop:~/aws$ aws organizations attach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox
ana@laptop:~/aws$ aws organizations detach-policy --policy-id p-FullAWSAccess --target-id $sandbox
ana@laptop:~/aws$ for t in $root $sandbox $(account sandbox); do echo "$t: $(aws organizations list-policies-for-target --target-id $t --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text)"; done
r-ucqy: FullAWSAccess
ou-ucqy-bqcc9il2: sandbox-allow-list
798632694501: FullAWSAccess
```

The root and the `sandbox` account still carry `FullAWSAccess`; the OU between them carries only
the allow list, so **the account gets the allow list**. A database in `sandbox`, `rds:*`, is now
refused at the OU however the account's own IAM is written, and so is any service AWS launches next
year.

The figure draws the tree as it stands at the end of this lesson, with the next section's four
guardrails already on it, and follows three requests down it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l04-inheritance\" aria-label=\"The SCPs on the two paths of the shop's tree after this lesson. The root carries FullAWSAccess, deny-leaving, sa-east-1-only and protect-security-services. On the left path, Workloads carries FullAWSAccess and protect-deployer, Prod and the account shop-prod carry FullAWSAccess. On the right path, Sandbox carries only sandbox-allow-list, and the account sandbox carries FullAWSAccess. A request for EC2 in us-east-1 from shop-prod is denied at the root. A request for RDS in sa-east-1 from sandbox passes the root and is not allowed at Sandbox, so it is refused there.\"><defs><marker id=\"l04-inheritance-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"230.0\" y=\"16.0\" width=\"260.0\" height=\"86.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Root</text><text x=\"360.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">deny-leaving</text><text x=\"360.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sa-east-1-only</text><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">protect-security-services</text><rect x=\"80.0\" y=\"140.0\" width=\"220.0\" height=\"56.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Workloads</text><text x=\"190.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><text x=\"190.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">protect-deployer</text><rect x=\"80.0\" y=\"226.0\" width=\"220.0\" height=\"41.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Prod</text><text x=\"190.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><rect x=\"80.0\" y=\"297.0\" width=\"220.0\" height=\"41.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"190.0\" y=\"311.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"190.0\" y=\"328.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><rect x=\"420.0\" y=\"140.0\" width=\"220.0\" height=\"41.0\" rx=\"10\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Sandbox</text><text x=\"530.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sandbox-allow-list</text><rect x=\"420.0\" y=\"211.0\" width=\"220.0\" height=\"41.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sandbox</text><text x=\"530.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">FullAWSAccess</text><path d=\"M300.0 102.0 L300.0 119.5 L190.0 119.5 L190.0 137.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M420.0 102.0 L420.0 119.5 L530.0 119.5 L530.0 137.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M190.0 196.0 L190.0 209.5 L190.0 209.5 L190.0 223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M190.0 267.0 L190.0 280.5 L190.0 280.5 L190.0 294.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><path d=\"M530.0 181.0 L530.0 194.5 L530.0 194.5 L530.0 208.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-inheritance-af-ah-paper-dim)\"></path><text x=\"190.0\" y=\"364.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">EC2 in us-east-1: denied at the root</text><text x=\"530.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">RDS in sa-east-1: not allowed at Sandbox</text><text x=\"530.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">EC2 in sa-east-1: allowed at every level</text><text x=\"360.0\" y=\"390.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the highlighted policies are the shop's; FullAWSAccess is AWS's</text></svg>", "caption": "Every level on the path is a filter. A deny at any of them, or a missing allow, refuses the request."}
```

## The order matters, and moto does not check it

**AWS refuses to leave a target with no SCP at all.** The API reference for `DetachPolicy` says every
root, OU and account must have at least one SCP attached, which is why the allow list went on
before `FullAWSAccess` came off; a target with nothing attached would allow nothing. The refusal is
a `ConstraintViolationException` whose reason is `MIN_POLICY_TYPE_ATTACHMENT_LIMIT_EXCEEDED`. moto
does not enforce it:

```
ana@laptop:~/aws$ aws organizations detach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox
ana@laptop:~/aws$ aws organizations list-policies-for-target --target-id $sandbox --filter SERVICE_CONTROL_POLICY --query "Policies[].Name"
[]
ana@laptop:~/aws$ aws organizations attach-policy --policy-id $(policy sandbox-allow-list) --target-id $sandbox
```

moto took the last policy off and the OU was left with an empty list. **In AWS that detach would
have failed**, and that part was not run here. The last command put the allow list back, so the
tree is as the shop wants it for the next section.
