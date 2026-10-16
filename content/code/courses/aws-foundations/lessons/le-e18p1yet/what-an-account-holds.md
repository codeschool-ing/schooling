---
title: What an account holds, and what it keeps apart
version: 1
---

**An AWS account is a container, not a login.** The wrong picture comes from every other website,
where an account is a person with a name and a password. In AWS the account is the box that
everything else sits in, and people are only one of the things inside it. It has a twelve-digit
number, an owner, a bill, and walls that nothing crosses unless somebody opens a door on purpose.

Five things live inside those walls, and each of them is a reason to have more than one account:

- **Identities stay in their account.** IAM's users, groups and roles exist in one account and mean
  nothing in another; a user `bia` here and a user `bia` there are two strangers who share a name.
- **Resources belong to exactly one account.** Every machine, bucket, network and queue has one
  owner, and the other accounts cannot see it, let alone change it.
- **Quotas are counted per account**, and for most services per region as well: how many networks,
  addresses or functions running at once you may have.
- **The bill is the account's.** What a resource costs is charged to the account that owns it, line
  by line.
- **The blast radius ends at the wall.** What a mistake, a leaked key or a runaway script can reach
  is, at most, the account it happened in.

## Asking which account you are in

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. Then, in the second, ask who you are and create two things with names:

```
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws sns create-topic --name shop-alerts
{
    "TopicArn": "arn:aws:sns:sa-east-1:123456789012:shop-alerts"
}
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
```

`sns create-topic` makes a notification channel, which this lesson needs only for its name; IAM's
`create-user` makes a user, and lesson 6 says what a user is for. Both answers carry the number
from the first command, `123456789012`, which is moto's default account.

## An ARN, taken apart

**Every resource in AWS has one full name, its ARN** (Amazon Resource Name), and it is the name a
policy, a log line and an error message use. It is six fields separated by colons, always in the
same order:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l02-arn\" aria-label=\"Three ARNs from the transcript, cut into their six fields: prefix, partition, service, region, account and resource. The topic arn:aws:sns:sa-east-1:123456789012:shop-alerts fills all six. The user arn:aws:iam::123456789012:user/bia leaves the region empty, because IAM is global inside an account. The bucket arn:aws:s3:::shop-assets leaves the region and the account empty, because a bucket name belongs to no account. The account column is highlighted: it says whose the resource is.\"><text x=\"76.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">prefix</text><text x=\"138.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">partition</text><text x=\"206.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">service</text><text x=\"304.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">region</text><text x=\"436.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">account</text><text x=\"591.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">resource</text><rect x=\"54.0\" y=\"57.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">arn</text><text x=\"107.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"116.0\" y=\"57.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"169.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"178.0\" y=\"57.0\" width=\"56.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sns</text><text x=\"243.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"252.0\" y=\"57.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1</text><text x=\"365.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"374.0\" y=\"57.0\" width=\"124.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"436.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">123456789012</text><text x=\"507.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"516.0\" y=\"57.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-alerts</text><rect x=\"54.0\" y=\"115.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">arn</text><text x=\"107.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"116.0\" y=\"115.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"169.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"178.0\" y=\"115.0\" width=\"56.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">iam</text><text x=\"243.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"252.0\" y=\"115.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"304.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">empty</text><text x=\"365.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"374.0\" y=\"115.0\" width=\"124.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"436.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">123456789012</text><text x=\"507.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"516.0\" y=\"115.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/bia</text><rect x=\"54.0\" y=\"173.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">arn</text><text x=\"107.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"116.0\" y=\"173.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"169.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"178.0\" y=\"173.0\" width=\"56.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">s3</text><text x=\"243.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"252.0\" y=\"173.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"304.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">empty</text><text x=\"365.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"374.0\" y=\"173.0\" width=\"124.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"436.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">empty</text><text x=\"507.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"516.0\" y=\"173.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-assets</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">IAM is global inside an account, so a user has no region</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a bucket name belongs to no account, so its ARN has none</text></svg>", "caption": "Six fields, always in this order. The fifth says whose a resource is."}
```

The first field is always `arn`. The second is the partition: `aws` everywhere you will work,
`aws-cn` in China and `aws-us-gov` in GovCloud, which are separate copies of AWS with accounts of
their own. Then the service, the region and the account, and last the resource, in a form each
service chooses.

**An empty field is information.** The user has no region, because IAM is global inside an
account: `bia` exists in São Paulo and in Virginia at once. A bucket's ARN, `arn:aws:s3:::shop-assets`,
has no region and no account either, which is the first hint of something the next section
measures: a bucket's name belongs to nobody's account.

One detail of moto's answer is moto's. For a user, AWS reports the caller as
`arn:aws:iam::<account>:user/<name>`, with `iam` as the service; moto writes `sts` and calls its
default user `moto`. For a role taken on with `assume-role`, which the next section does, AWS also
says `sts`, and the next transcript is right on both counts.

**Read the account out of an ARN before anything else.** When a policy, a log line or a bill names
a resource, the fifth field says whose it is, and a policy naming an account nobody recognises is
the first thing in it to question.

## Quotas are counted per account

**A quota is a limit AWS sets on how much of something one account may have**, in most cases per
region. The service that keeps them is Service Quotas, and moto carries its list:

```
ana@laptop:~/aws$ aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE --query "Quota.[QuotaName,Value,Adjustable,GlobalQuota]" --output text
VPCs per Region	5.0	True	False
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-546fc35409a21e400	172.31.0.0/16	True
ana@laptop:~/aws$ for n in 1 2 3 4 5; do aws ec2 create-vpc --cidr-block 10.$n.0.0/16 --query Vpc.VpcId --output text; done
vpc-09904342f704201c3
vpc-d877b106d3b8c910b
vpc-01df613edaab9b4b0
vpc-595183274a283a4e6
vpc-ed78599abbf31f591
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "length(Vpcs)"
6
```

Five VPCs per region, adjustable, and not global, so the count starts again in every region. The
account already had one VPC, the default VPC AWS makes in every region of a new account, and
the loop asked for five more. moto made all five and now holds six.

**AWS would have refused the fifth one.** The default VPC counts, so default plus four is the
quota, and the next `create-vpc` answers with the error code `VpcLimitExceeded`. moto stores the
quota's value and does not count against it, so **that refusal was not run here**; it is AWS's
documented behaviour. The value can be raised, by a request to Service Quotas for one quota in one
region of one account. Another account starts again from the default, which is the whole point of
the next section.

## The root user, and everybody else

**Every account has exactly one root user**, the identity that opened it. It signs in with the
account's e-mail address, may do anything in the account including closing it, and cannot be
limited by the account's own IAM policies. Lesson 1, in "A real account", said how to protect it;
everyone who works in the account day to day is an IAM identity created inside it instead, and
lesson 6 sorts those out.

What matters here is the count. **Ten accounts are ten root users and ten e-mail addresses**, each
of them unique across all of AWS, which is why the shop gives every account an address of the form
`aws+<account>@example.com`: one mailbox, a different address per account. An account made inside
an organisation, as in the next section, starts with a root user that has no password at all, and
the organisation's management account can remove the root user's credentials from its member
accounts altogether. Lesson 5 puts that on the list of what a landing zone settles.
