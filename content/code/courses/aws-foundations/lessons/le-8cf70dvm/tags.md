---
title: Tags, and the step that makes them count
version: 1
---

**A tag is a key and a value written on a resource, and it is the only way a bill can say whose a
cost was.** The bill knows the account, the service, the region and the usage type of every line.
It does not know that a machine belongs to the web team or to the staging copy of the shop, unless
the machine says so in a tag. The usual mistake is to think that tagging is the whole job. **A tag
on a resource does not appear in a cost report until somebody activates it in Billing**, and from
then on it labels new charges only.

## Tagging in the lab

This course's tags are the shop's: `project=shop`, `env=prod` or `staging`, and `team=web`, `data`
or `finance`. A bucket takes its tags as one set. An instance can take them in the command that
creates it, which is the habit worth having: a resource tagged a day late was untagged for a day.
The second instance below is started without tags, on purpose:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --output text
/shop-assets
ana@laptop:~/aws$ aws s3api put-bucket-tagging --bucket shop-assets --tagging 'TagSet=[{Key=project,Value=shop},{Key=env,Value=prod},{Key=team,Value=web}]'
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-logs --create-bucket-configuration LocationConstraint=sa-east-1 --output text
/shop-logs
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type m7i.large --tag-specifications 'ResourceType=instance,Tags=[{Key=project,Value=shop},{Key=env,Value=prod},{Key=team,Value=web}]' --query 'Instances[0].InstanceId' --output text
i-eb1bd5fa0d8d0a621
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.medium --query 'Instances[0].InstanceId' --output text
i-5ef280fe00c97d2e5
```

moto invents instance ids, and yours differ from the two above. Use your own in the commands that
follow. The **Resource Groups Tagging API** answers one question across every service, which
resources carry a tag:

```
ana@laptop:~/aws$ aws resourcegroupstaggingapi get-resources --tag-filters Key=team,Values=web --query 'ResourceTagMappingList[].ResourceARN'
[
    "arn:aws:s3:::shop-assets",
    "arn:aws:ec2:sa-east-1:123456789012:instance/i-eb1bd5fa0d8d0a621"
]
ana@laptop:~/aws$ aws resourcegroupstaggingapi get-resources --query 'ResourceTagMappingList[].ResourceARN'
[
    "arn:aws:s3:::shop-assets",
    "arn:aws:ec2:sa-east-1:123456789012:instance/i-eb1bd5fa0d8d0a621"
]
ana@laptop:~/aws$ aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId, InstanceType, Tags[?Key==`team`].Value | [0]]' --output text
i-eb1bd5fa0d8d0a621	m7i.large	web
i-5ef280fe00c97d2e5	t3.medium	None
```

The second command asked for every resource, with no filter, and still printed only the two tagged
ones. **That is how the API is documented to behave: it lists resources that carry tags or once did,
and a resource that was never tagged is invisible to it.** The untagged instance and the bucket
`shop-logs` exist and are missing from that list. They are exactly the resources a cost report
cannot attribute. Finding them takes asking each service, as the third command does for EC2: the
`t3.medium` has no `team`, and the text output says `None`. AWS Config's `required-tags` rule does
the same check continuously, and `aws-operations` lesson 21 covers Config.

Tag the stray instance and ask again:

```
ana@laptop:~/aws$ aws ec2 create-tags --resources i-5ef280fe00c97d2e5 --tags Key=project,Value=shop Key=env,Value=staging Key=team,Value=data
ana@laptop:~/aws$ aws resourcegroupstaggingapi get-resources --tag-filters Key=team --query 'ResourceTagMappingList[].[ResourceARN, Tags[?Key==`team`].Value | [0]]' --output text
arn:aws:s3:::shop-assets	web
arn:aws:ec2:sa-east-1:123456789012:instance/i-eb1bd5fa0d8d0a621	web
arn:aws:ec2:sa-east-1:123456789012:instance/i-5ef280fe00c97d2e5	data
```

## Tag policies: the spelling, not the presence

Tags are free text and case-sensitive, so `team=web`, `Team=web` and `team=Web` are three different
groups in a report. A report of three groups for one team is wrong in a way nobody notices. A **tag
policy** is a policy type of AWS Organizations, like the SCPs of lesson 4, that fixes how a key is
spelt and which values it may take. This one says `team` is written in lower case and holds one of
three values. `enforced_for` asks AWS to refuse a tagging operation on an EC2 instance that breaks
it:

```sh
cat > tag-policy.json <<'EOF'
{
  "tags": {
    "team": {
      "tag_key": {"@@assign": "team"},
      "tag_value": {"@@assign": ["web", "data", "finance"]},
      "enforced_for": {"@@assign": ["ec2:instance"]}
    }
  }
}
EOF
```

Turn on the policy type at the root of a new organisation, create the policy and attach it, then
start an instance tagged `team=marketing`:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --query Organization.Id --output text
o-6yu81updtn
ana@laptop:~/aws$ aws organizations list-roots --query 'Roots[0].Id' --output text
r-k1uz
ana@laptop:~/aws$ aws organizations enable-policy-type --root-id r-k1uz --policy-type TAG_POLICY --query Root.PolicyTypes --output text
ENABLED	TAG_POLICY
ana@laptop:~/aws$ aws organizations create-policy --name team-values --type TAG_POLICY --description 'team is web, data or finance' --content file://tag-policy.json --query Policy.PolicySummary.Id --output text
p-rgyicmvp
ana@laptop:~/aws$ aws organizations attach-policy --policy-id p-rgyicmvp --target-id r-k1uz
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.medium --tag-specifications 'ResourceType=instance,Tags=[{Key=team,Value=marketing}]' --query 'Instances[0].Tags' --output text
team	marketing
```

**moto stored the policy, attached it and then ignored it**: the last command started an instance
with a value the policy does not allow. Against AWS, the policy refuses a request that writes
`team=marketing` onto an instance in an account it covers. That part was not run. What a tag policy
does not do, even in AWS, is **require** a tag. AWS's documentation says it does not report
resources with no tags as non-compliant, so the untagged `t3.medium` above would have passed it. To
refuse a resource created without `team`, an SCP denies the creating action when the request has no
such tag. It uses the `aws:RequestTag/team` condition key, and lesson 4 writes SCPs.

## Activating a tag for cost allocation

Billing keeps its own list of tag keys, and **a key is only used to split costs once it is
activated** there. That happens in the **management account** of an organisation, because the
consolidated bill belongs to that account (lesson 3). AWS's documentation gives the timing. A newly
used key can take up to 24 hours to appear in that list, and up to 24 hours more after activation
before it appears in reports. The Cost Explorer API has an operation for each half, listing the keys
and changing their status, and moto has neither:

```
ana@laptop:~/aws$ aws ce list-cost-allocation-tags 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the ListCostAllocationTags operation (reached max retries: 2): <!doctype html>
```

Against AWS,
`aws ce update-cost-allocation-tags-status --cost-allocation-tags-status TagKey=team,Status=Active`
is the activation; it was not run. Two kinds of key end up in that list. **User-defined** keys are
the ones you wrote, such as `team`. **AWS-generated** keys are written by AWS, such as
`aws:createdBy`, which records the identity that created a resource. They have to be activated too.

**Activation is not retroactive.** A key activated on 20 October splits the costs from then on, and
the first nineteen days of the month stay in one undivided heap. AWS added a **backfill** request in
2024, which applies the current activation to up to twelve earlier months. It fixes only the
forgotten activation: usage that happened while a resource carried no tag has no tag to backfill.
**The tag has to be on the resource when the cost happens.** That is why tagging at creation is the
habit, and why the flow below has two gates rather than one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l13-flow\" aria-label=\"From an hour of use to a line in a report, through two gates. On the left, two resources: an m7i.large tagged team=web and a t3.medium with no tag. Each hour of use becomes a line on the bill carrying the tags the resource had at that hour: the first line carries team=web, the second none. Gate one, between them: the tag must be on the resource when the cost happens. Gate two, before the report: the key team must be activated in Billing, in the management account. On the right, the report grouped by team: team$web holds the first line, and team$, the untagged remainder, holds the second.\"><defs><marker id=\"l13-flow-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">an hour of use</text><rect x=\"20.0\" y=\"48.0\" width=\"190.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a line on the bill</text><rect x=\"265.0\" y=\"48.0\" width=\"190.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a report, grouped by team</text><rect x=\"510.0\" y=\"48.0\" width=\"190.0\" height=\"170.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"35.0\" y=\"71.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">m7i.large</text><text x=\"115.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">team=web</text><rect x=\"280.0\" y=\"71.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 hour, m7i.large</text><text x=\"360.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">tags: team=web</text><path d=\"M197.0 95.0 L277.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><rect x=\"525.0\" y=\"71.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">team$web</text><text x=\"605.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the web team</text><path d=\"M442.0 95.0 L522.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><rect x=\"35.0\" y=\"146.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">t3.medium</text><text x=\"115.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no tag</text><rect x=\"280.0\" y=\"146.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 hour, t3.medium</text><text x=\"360.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">tags: -</text><path d=\"M197.0 170.0 L277.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><rect x=\"525.0\" y=\"146.0\" width=\"160.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">team$</text><text x=\"605.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the untagged remainder</text><path d=\"M442.0 170.0 L522.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-flow-af-ah-paper-dim)\"></path><path d=\"M237.0 48.0 L237.0 218.0\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"237.0\" cy=\"252.0\" r=\"13\" fill=\"var(--amber)\"></circle><text x=\"237.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--ink)\">1</text><text x=\"237.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the tag is on</text><text x=\"237.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the resource at</text><text x=\"237.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the hour of use</text><path d=\"M482.0 48.0 L482.0 218.0\" stroke=\"var(--amber)\" stroke-width=\"2.5\" fill=\"none\" stroke-dasharray=\"3 3\"></path><circle cx=\"482.0\" cy=\"252.0\" r=\"13\" fill=\"var(--amber)\"></circle><text x=\"482.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--ink)\">2</text><text x=\"482.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the key is</text><text x=\"482.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">activated in</text><text x=\"482.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Billing</text></svg>", "caption": "A cost reaches a report under a tag only if the tag was there at the hour, and the key was activated."}
```
