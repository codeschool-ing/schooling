---
title: Managed policies, AWS's and the shop's own
version: 1
---

**A managed policy is a policy that exists on its own, with an ARN, and is attached to as many
users, groups and roles as need it.** There are two owners. **AWS-managed** policies are written and
edited by AWS and are the same in every account. **Customer-managed** policies are written by you
and live in one account. Both are attached rather than embedded, both keep versions, and changing
one changes the permissions of everything it is attached to, at once.

## AWS-managed: a library someone else maintains

The variable `MOTO_IAM_LOAD_MANAGED_POLICIES=true` in `env.sh` is what makes moto carry AWS's
library. It is large:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "length(Policies)"
1544
```

**The ARN of an AWS-managed policy has `aws` where the account would be**, which is how a policy in
any account can name it. `ReadOnlyAccess` is a common choice for an auditor or a dashboard, and its
default version says how often AWS edits these:

```
ana@laptop:~/aws$ aws iam get-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --query "Policy.[DefaultVersionId,CreateDate,UpdateDate]" --output text
v188	2015-02-06T18:39:48+00:00	2026-07-21T18:42:30+00:00
```

**Version 188**, from a policy created in 2015 and last changed in July 2026. Every new AWS service
adds lines to it, and the accounts that attached it receive them without doing anything. Its
default version, summarised:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id v188 --query "PolicyVersion.Document.Statement[].{Sid:Sid,Actions:length(Action),Resource:Resource}" --output table
-----------------------------------------------------------------
|                       GetPolicyVersion                        |
+---------+-----------+-----------------------------------------+
| Actions | Resource  |                   Sid                   |
+---------+-----------+-----------------------------------------+
|  1510   |  *        |  ReadOnlyActionsGroup1                  |
|  1403   |  *        |  ReadOnlyActionsGroup2                  |
|  1      |  *        |  S3ExpressReadOnlySessionObjectAccess   |
+---------+-----------+-----------------------------------------+
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id v188 --query "PolicyVersion.Document.Statement[1].Action[?starts_with(@, \`s3:\`)]"
[
    "s3:DescribeJob",
    "s3:Get*",
    "s3:List*"
]
```

Nearly three thousand action patterns, on every resource. **"Read-only" is a promise about writing,
not about reading**. The S3 lines are `s3:Get*` and `s3:List*`, so whoever holds this policy reads
every object in every bucket of the account, the backups included. An AWS-managed policy is a
starting point written for everybody, and it fits nobody exactly.

## Customer-managed: the shop's own

bia's policy from the first section becomes a customer-managed policy, attached to her user. Every
command below runs as `admin`, the terminal's identity since the previous section. First the
buckets and an object to read, then the policy:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-assets
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/shop-backups
ana@laptop:~/aws$ aws s3api put-object --bucket shop-assets --key logo.txt --body logo.txt --query ETag --output text
"98d8d6a239ae64c6f2fc402b7a7847d8"
ana@laptop:~/aws$ aws iam create-policy --policy-name shop-assets-rw --policy-document file://shop-assets-rw.json
{
    "Policy": {
        "PolicyName": "shop-assets-rw",
        "PolicyId": "ANY1RC7G7SWA55JH6P6JQ",
        "Arn": "arn:aws:iam::123456789012:policy/shop-assets-rw",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "IsAttachable": true,
        "CreateDate": "2026-10-16T16:23:27.399209+00:00",
        "UpdateDate": "2026-10-16T16:23:27.399211+00:00"
    }
}
```

**The ARN has the shop's account in it**, `123456789012`, and `DefaultVersionId` is `v1`. Now bia,
her policy and a key for her, kept in the variable `bia` for `with_key`:

```
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
```

Then bia, one command at a time. **What the policy names works, and everything else is refused**:

```
ana@laptop:~/aws$ with_key "$bia" aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ with_key "$bia" aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
logo.txt
ana@laptop:~/aws$ with_key "$bia" aws s3 cp s3://shop-assets/logo.txt -
logo
ana@laptop:~/aws$ with_key "$bia" aws s3api put-object --bucket shop-assets --key banner.txt --body logo.txt --query ETag --output text
"98d8d6a239ae64c6f2fc402b7a7847d8"
ana@laptop:~/aws$ with_key "$bia" aws s3api list-objects-v2 --bucket shop-backups

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListObjectsV2 operation: Access Denied
ana@laptop:~/aws$ with_key "$bia" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ with_key "$bia" aws s3api delete-object --bucket shop-assets --key logo.txt

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ with_key "$bia" aws iam list-users

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:iam::123456789012:user/bia is not authorized to perform: iam:ListUsers
```

**Read the refusals, because they are not alike.** IAM names the user and the action, which is
exactly what the person debugging needs. S3 says `Access Denied` and nothing else, for listing
`shop-backups`, for listing the buckets and for deleting the logo alike. The policy never mentioned
`s3:ListAllMyBuckets` or `s3:DeleteObject`, so nothing allowed them. `sts get-caller-identity`
answers for anybody, which AWS documents and moto copies: it reveals only who you are.

`aws s3 ls s3://shop-assets` would be the obvious listing command. It is not used here because
**moto answers it with `SignatureDoesNotMatch` whoever signs it**, admin included: the `/` delimiter
the command sends trips moto's signature check. `s3api list-objects-v2` sends none and is judged
normally:

```
ana@laptop:~/aws$ aws s3 ls s3://shop-assets

aws: [ERROR]: An error occurred (SignatureDoesNotMatch) when calling the ListObjectsV2 operation: The request signature we calculated does not match the signature you provided. Check your key and signing method.
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket shop-assets --query "Contents[].Key" --output text
banner.txt	logo.txt
```

Against AWS both work.

## Versions, and the limit of five

Editing a customer-managed policy does not overwrite it. **Each edit is a new version**, and one
version at a time is the default, the one AWS reads. The shop's policy gets four more versions,
here identical to the first, and then a sixth is attempted:

```
ana@laptop:~/aws$ for i in 2 3 4 5; do aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json --query "PolicyVersion.[VersionId,IsDefaultVersion]" --output text; done
v2	False
v3	False
v4	False
v5	False
ana@laptop:~/aws$ aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json

aws: [ERROR]: An error occurred (LimitExceeded) when calling the CreatePolicyVersion operation: A managed policy can have up to 5 versions. Before you create a new version, you must delete an existing version.
ana@laptop:~/aws$ aws iam delete-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v1

aws: [ERROR]: An error occurred (DeleteConflict) when calling the DeletePolicyVersion operation: Cannot delete the default version of a policy.
```

**A managed policy keeps five versions at most**, and moto enforces it as AWS does. The default
cannot be deleted, so the way through is to delete an old one, which makes room for `v6`. Then
`set-default-policy-version` moves the default back and forth:

```
ana@laptop:~/aws$ aws iam delete-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v2
ana@laptop:~/aws$ aws iam create-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --policy-document file://shop-assets-rw.json --set-as-default --query "PolicyVersion.[VersionId,IsDefaultVersion]" --output text
v6	True
ana@laptop:~/aws$ aws iam set-default-policy-version --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --version-id v1
ana@laptop:~/aws$ aws iam list-policy-versions --policy-arn arn:aws:iam::123456789012:policy/shop-assets-rw --query "Versions[].[VersionId,IsDefaultVersion]" --output text
v1	True
v3	False
v4	False
v5	False
v6	False
```

**That is the point of versions: a bad edit is undone by moving the default back**, with no
document to reconstruct and nothing detached. `--set-as-default` on `create-policy-version` makes
the new version the live one in the same call. Without it a new version waits, unused.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l07-three-kinds\" aria-label=\"Where each kind of policy lives. On the left, outside the shop's account, AWS's library: the AWS-managed policy ReadOnlyAccess, at version v188 and edited by AWS, attached to the user caio inside the shop's account. Inside the account 123456789012, the customer-managed policy shop-assets-rw, with up to five versions and one default, attached at once to the user bia, the group developers and the role deployer. At the bottom right, the user edu with an inline policy embedded in it, which has no ARN and is deleted with edu.\"><defs><marker id=\"l07-three-kinds-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-three-kinds-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"120.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">AWS-managed</text><rect x=\"40.0\" y=\"70.0\" width=\"160.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ReadOnlyAccess</text><text x=\"120.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">v188, edited by AWS</text><text x=\"120.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the same in every account</text><rect x=\"250.0\" y=\"20.0\" width=\"450.0\" height=\"290.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">account 123456789012</text><text x=\"365.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">customer-managed</text><rect x=\"280.0\" y=\"72.0\" width=\"170.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-assets-rw</text><text x=\"365.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 versions at most, 1 default</text><rect x=\"530.0\" y=\"55.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user/bia</text><path d=\"M452.0 105.0 L528.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-amber)\"></path><rect x=\"530.0\" y=\"95.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group/developers</text><path d=\"M452.0 105.0 L528.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-amber)\"></path><rect x=\"530.0\" y=\"135.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">role/deployer</text><path d=\"M452.0 105.0 L528.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-amber)\"></path><rect x=\"280.0\" y=\"175.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user/caio</text><path d=\"M120.0 127.0 L120.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 160.0 L120.0 190.0 L250.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M250.0 190.0 L278.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-three-kinds-af-ah-paper-dim)\"></path><text x=\"185.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">attached</text><rect x=\"470.0\" y=\"205.0\" width=\"210.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/edu</text><rect x=\"490.0\" y=\"236.0\" width=\"170.0\" height=\"46.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"575.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">inline policy, no ARN</text><text x=\"575.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">deleted with edu</text></svg>", "caption": "An AWS-managed policy is shared by every account, a customer-managed one by everything it is attached to, and an inline one by nothing."}
```
