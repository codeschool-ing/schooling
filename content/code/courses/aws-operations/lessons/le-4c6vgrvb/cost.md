---
title: What a key costs
version: 1
---

KMS is priced by keys and by requests:

```
ana@laptop:~/aws$ python3 price.py awskms Keys
awskms, sa-east-1, published 2026-09-11
  sa-east-1-KMS-Keys                       1.000000 USD per Keys       $1 per customer managed KMS key version in South America (Sao Paulo)
ana@laptop:~/aws$ python3 price.py awskms "kms requests"
awskms, sa-east-1, published 2026-09-11
  Global-KMS-Requests                      0.000000 USD per Requests   $0.00 per request - Monthly Global Free Tier for KMS requests
  sa-east-1-KMS-Requests                   0.000003 USD per Requests   $0.03 per 10000 KMS requests in South America (Sao Paulo)
```

**One customer managed key is 1 USD a month**, and the line says per **key version**: each rotation adds
a version. AWS documents that the first and second rotations each add a month's fee and later ones add
nothing, so a key rotated every year costs 1, then 2, then 3 USD a month, and stays at 3. AWS managed
keys, `aws/ssm` and the rest, have no monthly fee.

**Requests are 3 cents per 10,000**, after a free allowance that AWS documents as 20,000 a month across
the account; the `Global-` line shows its price, nothing, and not its size. Asymmetric keys and the
generation of key pairs have dearer lines of their own.

## Where the requests come from

The fee for keys is small and fixed. The requests are where a KMS bill grows, and they grow with
**how often something asks KMS for a data key**:

| what happens | requests to KMS |
|---|---|
| `envelope.py seal` on a file | 1, whatever the size |
| reading a `SecureString` | 1 per read, which is lesson 17's cache again |
| S3 writing an object with SSE-KMS | 1 per object, unless the bucket uses an **S3 Bucket Key** |
| S3 reading an object with SSE-KMS | 1 per object, unless the bucket uses an S3 Bucket Key |

An S3 bucket receiving 10 million small objects a month with SSE-KMS makes 10 million requests to
write them: **30 USD a month**, and 3 USD more for every million objects read. With an **S3 Bucket Key**, S3
asks KMS for a key for the bucket and derives the object keys from it for a while, which AWS documents
as cutting the requests by up to 99%: the same month becomes cents. It is one setting on the bucket,
and it is the first thing to look at when a KMS line on the bill is larger than the keys explain.
