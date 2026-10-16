---
title: Resource policies, conditions, and the tools that check for real
version: 1
---

**A resource-based policy is attached to the thing being used rather than to the one using it.**
So it names a `Principal`: who, from where, may do what to this bucket, this queue, this key.
It is a granting layer like an identity policy, and an explicit `Deny` in it ends a request like a
`Deny` anywhere else. A role's trust policy, from lesson 6, is one of them: the resource is the
role, and the action is assuming it.

## A bucket policy, and moto not reading it

The shop wants `shop-assets` never to be deleted by accident, whoever holds the keys. A `Deny` for
every principal does that in AWS. Save it as `~/aws/keep-assets.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NobodyDeletesTheAssetsBucket",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:DeleteBucket",
      "Resource": "arn:aws:s3:::shop-assets"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket shop-assets --policy file://keep-assets.json
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket shop-assets --query Policy --output text
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NobodyDeletesTheAssetsBucket",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:DeleteBucket",
      "Resource": "arn:aws:s3:::shop-assets"
    }
  ]
}

ana@laptop:~/aws$ aws s3api delete-object --bucket shop-assets --key logo.png
ana@laptop:~/aws$ aws s3api delete-bucket --bucket shop-assets
ana@laptop:~/aws$ aws s3 ls
2026-10-16 13:39:04 shop-backups
```

The logo goes first, because a bucket with objects in it cannot be deleted in AWS or in moto, and the
bucket policy denies only the bucket's own deletion. **Then the bucket is gone. AWS would have
refused**, `admin` and its `AdministratorAccess` included,
because an explicit `Deny` anywhere ends the request, and a bucket policy is anywhere. moto judges a
bucket policy's `Deny` only on reading and writing objects, as lesson 19 shows, and never on the
bucket itself. That refusal was not run here.

**Across accounts, a resource policy is half of the answer.** Say the shop's `log-archive` account
owns `shop-logs`, and a role in `shop-prod` writes to it. The bucket policy has to allow that role,
**and** the role's own identity policy has to allow `s3:PutObject` on the bucket. Either one alone
is an implicit deny. Lesson 9 meets the same rule in roles, where the trust policy is the resource
side.

## Conditions

A condition narrows a statement to some requests. Inside `Condition`, each **operator** holds
**keys** and the values they must match. Several keys must all match, and several values for one
key are alternatives. Four keys come up in nearly every account:

| key | what it is | a typical use |
|---|---|---|
| `aws:SourceIp` | the public address the request came from | `IpAddress` with `203.0.113.0/24`: only from the office |
| `aws:MultiFactorAuthPresent` | whether the credentials were obtained with MFA | `BoolIfExists` with `false`, in a `Deny`: no sensitive action without MFA |
| `aws:PrincipalTag/team` | a tag on the calling user or role | `StringEquals` between `aws:ResourceTag/team` and `${aws:PrincipalTag/team}`: each team its own things |
| `aws:RequestedRegion` | the region the request is for | `StringNotEquals` with `sa-east-1`, in a `Deny`: nothing outside São Paulo |

Two of them have a trap that AWS's documentation spells out. **`aws:SourceIp` is absent when the
request arrives through a VPC endpoint**, which has its own key, so an `IpAddress` allow written for
the office fails from inside the VPC. **`aws:MultiFactorAuthPresent` is absent, not `false`, on a
request signed with a long-term access key**. That is why the deny uses `BoolIfExists`: a plain
`Bool` would not match the missing key, and the key that never had MFA would pass.

**moto treats every condition as met**, and that can err in either direction. A `Deny` limited to
other regions denied caio a request in `sa-east-1` itself:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name caio --policy-name only-sao-paulo --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"*","Resource":"*","Condition":{"StringNotEquals":{"aws:RequestedRegion":"sa-east-1"}}}]}'
ana@laptop:~/aws$ echo $AWS_DEFAULT_REGION
sa-east-1
ana@laptop:~/aws$ with_key "$caio" aws s3 ls

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
ana@laptop:~/aws$ aws iam delete-user-policy --user-name caio --policy-name only-sao-paulo
ana@laptop:~/aws$ with_key "$caio" aws s3 ls
2026-10-16 13:39:04 shop-backups
```

And an `Allow` that demands MFA let dani through with a plain access key:

```
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name buckets-with-mfa --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:ListAllMyBuckets","Resource":"*","Condition":{"Bool":{"aws:MultiFactorAuthPresent":"true"}}}]}'
ana@laptop:~/aws$ dani=$(aws iam create-access-key --user-name dani)
ana@laptop:~/aws$ with_key "$dani" aws s3 ls
2026-10-16 13:39:04 shop-backups
ana@laptop:~/aws$ aws iam list-mfa-devices --user-name dani
{
    "MFADevices": []
}
```

**AWS would have allowed the first and refused the second.** Neither of those was run against AWS.
The one condition moto does compare is `sts:ExternalId` in a role's trust policy, which lesson 9
measures.

## The tools that answer for real

Every limit of the lab in this lesson has the same remedy: ask AWS. Two tools exist for that, and
**neither runs in moto**, which answers both with HTTP 500, so nothing below was run here.

- **The IAM policy simulator**, `aws iam simulate-principal-policy`, takes a principal, a list of
  actions and optionally resources and context keys, and says for each action whether it would be
  allowed, and which statement decided. It reads the principal's real policies, boundaries
  included, without making the request.
- **IAM Access Analyzer** does three jobs. `aws accessanalyzer validate-policy` checks a document
  against AWS's grammar and best practice before it is saved, and would have flagged lesson 7's
  `Principal` in an identity policy. An analyzer created for the account or the organisation lists
  every resource whose policy lets somebody **outside** it in, such as a bucket shared with another
  account. And it reports access that was granted and never used, which is where a least privilege
  that survives an audit starts.

**Run the validator on every policy before it reaches an account**, and the external-access
analyzer on every account the organisation owns. In this course, a policy that moto obeyed has
passed one test, and it is the weakest of the three.
