---
title: A second account, and what it cannot see
version: 1
---

**Two accounts are two separate AWS environments that happen to share a bill.** The usual wrong
picture is a folder: one big AWS with a section per team, where somebody with the right key sees
all of it. A second account is not a folder. It has its own identities, its own networks and its
own quotas, and from inside it the first account does not exist. This section makes one in moto and
looks around.

## Making the second account

An account is created from another account that runs an organisation, and lesson 3 is about
what that tree is. Here it only has to exist, with one member account in it, `shop-prod`:

```
ana@laptop:~/aws$ aws organizations create-organization --query "Organization.[Id,MasterAccountId]" --output text
o-6v58xbpx3x	123456789012
ana@laptop:~/aws$ aws organizations create-account --email aws+shop-prod@example.com --account-name shop-prod --query "CreateAccountStatus.[State,AccountId]" --output text
SUCCEEDED	218935875641
ana@laptop:~/aws$ aws organizations list-accounts --query "Accounts[].[Id,Name,Email]" --output text
123456789012	master	master@example.com
218935875641	shop-prod	aws+shop-prod@example.com
```

The account that created the organisation is its management account, here moto's default
`123456789012`, which moto lists by the name `master`. The new account got a number of its own,
`218935875641`. Yours will be a different twelve digits, since moto invents them, so use yours
wherever the lesson shows this one. **moto answers `SUCCEEDED` at once. AWS creates an account in
the background** and answers `IN_PROGRESS`; `describe-create-account-status` is how you wait
for it. That part was not run here.

## Working inside it

Nothing you hold is a credential of `shop-prod`: the `test` keys in `env.sh` belong to the
management account. What the new account does have is a role, **`OrganizationAccountAccessRole`**,
which AWS creates in every account an organisation makes and which the management account is
allowed to take on. Taking on a role is `sts assume-role`, and it returns temporary credentials that
act inside the other account. Lesson 9 opens that up. The command line will do it for you if a
profile says which role to take:

```
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_arn arn:aws:iam::218935875641:role/OrganizationAccountAccessRole
ana@laptop:~/aws$ aws configure set profile.shop-prod.credential_source Environment
ana@laptop:~/aws$ aws configure set profile.shop-prod.role_session_name ana
ana@laptop:~/aws$ cat ~/.aws/config
[profile shop-prod]
role_arn = arn:aws:iam::218935875641:role/OrganizationAccountAccessRole
credential_source = Environment
role_session_name = ana
ana@laptop:~/aws$ aws --profile shop-prod sts get-caller-identity
{
    "UserId": "AROATF6MYLA4XZJERJXRZ:ana",
    "Account": "218935875641",
    "Arn": "arn:aws:sts::218935875641:assumed-role/OrganizationAccountAccessRole/ana"
}
```

The three `configure set` lines wrote the profile into `~/.aws/config`. `credential_source =
Environment` says the keys to start from are the ones in the environment, the ones `env.sh` sets,
and `role_session_name` puts your name into the session. **`--profile shop-prod` on any command
now runs it inside the other account**: the command line calls `assume-role` first and uses what
comes back. The answer to "who am I" changed account, and its ARN says `assumed-role`. Lesson 25
says more about profiles. The profile names this run's account number, so after moto restarts it
points at an account that is gone. Lesson 3 writes it again.

## Looking around from inside

```
ana@laptop:~/aws$ aws --profile shop-prod ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault,OwnerId]" --output text
vpc-39203323c199f8aeb	172.31.0.0/16	True	218935875641
ana@laptop:~/aws$ aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[].[VpcId,CidrBlock,IsDefault,OwnerId]" --output text
vpc-546fc35409a21e400	172.31.0.0/16	True	123456789012
ana@laptop:~/aws$ aws --profile shop-prod sns list-topics --query "Topics[].TopicArn"
[]
ana@laptop:~/aws$ aws --profile shop-prod iam list-users --query "Users[].UserName"
[]
```

**Each account has its own default VPC, and both use `172.31.0.0/16`.** The two networks have the
same addresses and different ids, and the last column says who owns each. Nothing joins them: an
address in one has no meaning in the other until somebody connects the two on purpose, which
lessons 19 and 20 do. The same addresses on both sides is also why such a connection has to be
planned, and why the shop gives its production network `10.20.0.0/16` rather than the default.

`shop-prod` sees **no topic and no user**. The `shop-alerts` topic and the user `bia` from the
section before are still there, in the management account; from here they do not exist. And
`shop-prod` holds one VPC, so the six VPCs the management account holds used none of its quota.

## The names that cross the walls

**One kind of name is not the account's to own: an S3 bucket's.** Bucket names live in one
namespace shared by every account of AWS, so a name taken anywhere is taken everywhere:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1
{
    "Location": "/shop-assets"
}
ana@laptop:~/aws$ aws --profile shop-prod s3api list-buckets --query "Buckets[].Name"
[]
ana@laptop:~/aws$ aws --profile shop-prod s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1

aws: [ERROR]: An error occurred (BucketAlreadyExists) when calling the CreateBucket operation: The requested bucket name is not available. The bucket namespace is shared by all users of the system. Please select a different name and try again
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1

aws: [ERROR]: An error occurred (BucketAlreadyOwnedByYou) when calling the CreateBucket operation: Your previous request to create the named bucket succeeded and you already own it.
ana@laptop:~/aws$ aws --profile shop-prod s3api create-bucket --bucket 218935875641-shop-assets --create-bucket-configuration LocationConstraint=sa-east-1
{
    "Location": "/218935875641-shop-assets"
}
```

From inside `shop-prod` there are no buckets at all, and still `shop-assets` cannot be created
there. **The two refusals say different things.** `BucketAlreadyExists` means another account has
the name; `BucketAlreadyOwnedByYou` means you have it already. Neither says which account owns the
bucket, and that is on purpose: a stranger may not learn whose a name is. moto enforces this the
way AWS does, which makes it one of the few cross-account rules you can watch fail in the lab.

**The shop's fix is the account number in the name**, `218935875641-shop-assets`, which nobody else
can be using, since nobody else has that account. A bucket's name is also part of its address on
the internet. That is why it must be unique, and why it cannot be renamed: a bucket that needs a
new name is a new bucket and a copy.

A few other names are global in the same way, and moto does not enforce these. One is the account
alias that replaces the twelve digits in the console's sign-in address. The other is the root
user's e-mail address, which the section before said is unique across AWS. In moto, two accounts
can set the same alias and two accounts can be created with the same address. In AWS the second
alias is refused, and the second account fails with the reason `EMAIL_ALREADY_EXISTS`. **Those refusals were
not run here**, since moto lets both through.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l02-two-accounts\" aria-label=\"Two accounts side by side, with what the transcripts showed inside each. The management account, 123456789012, holds the user bia, the topic shop-alerts, a default VPC 172.31.0.0/16 and six VPCs in sa-east-1. The member account shop-prod, 218935875641, holds no user, no topic, its own default VPC with the same range 172.31.0.0/16, and one VPC. Above both, one namespace for all of AWS: the bucket name shop-assets belongs to the management account, so shop-prod was refused it with BucketAlreadyExists, and took 218935875641-shop-assets instead.\"><defs><marker id=\"l02-two-accounts-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-two-accounts-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"100.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">S3 bucket names: one namespace for every account of AWS</text><rect x=\"70.0\" y=\"62.0\" width=\"180.0\" height=\"36.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-assets</text><rect x=\"430.0\" y=\"62.0\" width=\"240.0\" height=\"36.0\" rx=\"17\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">218935875641-shop-assets</text><rect x=\"20.0\" y=\"160.0\" width=\"320.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">123456789012</text><text x=\"324.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">management account</text><rect x=\"34.0\" y=\"204.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IAM users</text><text x=\"314.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bia</text><rect x=\"34.0\" y=\"248.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SNS topics</text><text x=\"314.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-alerts</text><rect x=\"34.0\" y=\"292.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"308.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">default VPC</text><text x=\"314.0\" y=\"308.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.0.0/16</text><rect x=\"34.0\" y=\"336.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"352.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPCs in sa-east-1</text><text x=\"314.0\" y=\"352.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6</text><rect x=\"380.0\" y=\"160.0\" width=\"320.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"396.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">218935875641</text><text x=\"684.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">shop-prod</text><rect x=\"394.0\" y=\"204.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IAM users</text><text x=\"674.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">none</text><rect x=\"394.0\" y=\"248.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"264.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SNS topics</text><text x=\"674.0\" y=\"264.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">none</text><rect x=\"394.0\" y=\"292.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"308.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">default VPC</text><text x=\"674.0\" y=\"308.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.0.0/16</text><rect x=\"394.0\" y=\"336.0\" width=\"292.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"352.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VPCs in sa-east-1</text><text x=\"674.0\" y=\"352.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><path d=\"M160.0 100.0 L160.0 120.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M160.0 120.0 L160.0 157.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-two-accounts-af-ah-phosphor)\"></path><path d=\"M550.0 100.0 L550.0 120.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550.0 120.0 L550.0 157.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-two-accounts-af-ah-phosphor)\"></path><path d=\"M470.0 158.0 L435.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M435.0 120.0 L254.0 90.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l02-two-accounts-af-ah-amber)\"></path><text x=\"330.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">BucketAlreadyExists</text></svg>", "caption": "Inside its walls an account sees only its own. A bucket name is the exception."}
```

## What moto leaves out

`shop-prod`'s role works in moto because moto checks no permission yet: lesson 7 turns that on. In
AWS the role also arrives with the `AdministratorAccess` policy attached, and in moto it arrives
with none. Lesson 3 looks at that difference, and lesson 9 at roles themselves. Nothing above
cost anything, in moto or in AWS: **an account is free**. What it costs is the work of keeping
it in order, the subject of the next section and of lessons 3 to 5.
