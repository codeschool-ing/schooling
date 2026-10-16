---
title: Block Public Access and Object Ownership
version: 1
---

**Block Public Access is a set of four switches that override every policy and ACL that would make a
bucket public.** A bucket policy is easy to get wrong in one line, and an ACL can be set on one object
by anybody allowed to write it; Block Public Access sits above both, so that a mistake in either does
not reach the internet. The common belief is that a bucket is private because nobody made it public.
A bucket is private because something refuses to let it be made public, and this is that something.

The four switches, as AWS documents them:

| switch | what it does |
|---|---|
| `BlockPublicAcls` | refuses any request that would set a public ACL on the bucket or an object |
| `IgnorePublicAcls` | makes S3 ignore public ACLs that already exist |
| `BlockPublicPolicy` | refuses a bucket policy that grants public access |
| `RestrictPublicBuckets` | if a public policy exists anyway, only AWS services and the account's own principals can use it |

**The pairs split the work in time.** `BlockPublicAcls` and `BlockPublicPolicy` stop a public grant
from being written; `IgnorePublicAcls` and `RestrictPublicBuckets` neutralise one that was written
before the switches were on. All four on is the setting for a bucket that must never be public, which
for Quitanda is every bucket.

## The bucket and the account

The switches exist twice, once per bucket and once for the whole account, and the stricter of the two
wins. **The account-level setting is the one that protects against the next bucket**, the one
somebody creates next year without thinking about it. Since April 2023 AWS also turns all four on for
every new bucket by default, and moto, which imitates an older S3, does not:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket quitanda-curated-prod

aws: [ERROR]: An error occurred (NoSuchPublicAccessBlockConfiguration) when calling the GetPublicAccessBlock operation: The public access block configuration was not found
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket quitanda-curated-prod --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket quitanda-curated-prod
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

**A new bucket in moto has no configuration at all**, which is the state an S3 bucket created before
2023 would be in. Setting all four and reading them back works as on AWS.

The account-level switches belong to a different API, S3 Control, whose address carries the account
number as the first part of the host name: `123456789012.localhost` in this lab. Some systems already
resolve every name ending in `.localhost` to this computer; if `getent hosts 123456789012.localhost`
prints nothing, add the name to `/etc/hosts` once, which needs `sudo`:

```
ana@laptop:~/aws$ getent hosts 123456789012.localhost
ana@laptop:~/aws$ echo '127.0.0.1 123456789012.localhost' | sudo tee -a /etc/hosts
127.0.0.1 123456789012.localhost
ana@laptop:~/aws$ getent hosts 123456789012.localhost
127.0.0.1       123456789012.localhost
ana@laptop:~/aws$ aws s3control put-public-access-block --account-id 123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3control get-public-access-block --account-id 123456789012
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

The line in `/etc/hosts` is harmless to leave, and `sudo sed -i '/123456789012.localhost/d'
/etc/hosts` removes it.

## What moto does with the switches

**moto stores all four and enforces none.** With every switch on, a policy that makes the bucket
public is accepted, and a request with no credentials at all reads an object:

```
ana@laptop:~/aws$ aws s3 cp daily.csv s3://quitanda-curated-prod/reports/daily.csv
upload: ./daily.csv to s3://quitanda-curated-prod/reports/daily.csv
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-curated-prod --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::quitanda-curated-prod/*"}]}'
ana@laptop:~/aws$ curl -s -w '%{http_code}\n' http://localhost:4567/quitanda-curated-prod/reports/daily.csv
day,orders,total_cents
2026-10-15,412,5108840
200
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-curated-prod
```

**On AWS the `put-bucket-policy` would have failed with `AccessDenied`**, because `BlockPublicPolicy`
refuses a public policy, and the anonymous `curl` would have been refused even if the policy had got
in, because of `RestrictPublicBuckets`. moto did evaluate the policy, which is why `curl` got the
object, and ignored the switches that should have stopped both. A test against moto shows that the
configuration was written. It cannot show that it works.

## Object Ownership, and the end of ACLs

ACLs are the older of S3's two permission systems, a list of grants on each bucket and each object.
**Object Ownership set to `BucketOwnerEnforced` turns them off**: the bucket owner owns every object,
and S3 refuses any request that tries to set an ACL other than the private one. It has been the
default for new buckets since April 2023, together with Block Public Access, and AWS recommends it
for every bucket that does not need ACLs, which is almost every bucket.

```
ana@laptop:~/aws$ aws s3api put-bucket-ownership-controls --bucket quitanda-curated-prod --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'
ana@laptop:~/aws$ aws s3api get-bucket-ownership-controls --bucket quitanda-curated-prod
{
    "OwnershipControls": {
        "Rules": [
            {
                "ObjectOwnership": "BucketOwnerEnforced"
            }
        ]
    }
}
ana@laptop:~/aws$ aws s3api put-object-acl --bucket quitanda-curated-prod --key reports/daily.csv --acl public-read
ana@laptop:~/aws$ aws s3api get-object-acl --bucket quitanda-curated-prod --key reports/daily.csv --query 'Grants[].[Grantee.URI,Permission]' --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
```

**moto recorded `BucketOwnerEnforced` and then accepted a `public-read` ACL on an object.** S3 would
answer `AccessControlListNotSupported`. With ACLs off, the bucket policy is the only place access is
granted, which is what makes the next section's policies the whole story.
