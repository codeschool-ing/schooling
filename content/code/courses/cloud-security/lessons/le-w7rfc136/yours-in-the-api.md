---
title: Your half, read back from the API
version: 1
---

**A new bucket comes with a handful of security settings, and every one of them is yours: to choose,
to check and to prove.** This section asks moto for each of them on an empty bucket, sets them, and
asks again. Start moto in the first terminal, empty, and read `env.sh` in both.

The clinic is about to keep its patients' records in a bucket of their own:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
```

## Four questions, asked before anything is set

Four settings decide most of what can go wrong with stored data. Ask for each:

```
ana@laptop:~/aws$ aws s3api get-bucket-encryption --bucket clinic-records

aws: [ERROR]: An error occurred (ServerSideEncryptionConfigurationNotFoundError) when calling the GetBucketEncryption operation: The server side encryption configuration was not found
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records

aws: [ERROR]: An error occurred (NoSuchPublicAccessBlockConfiguration) when calling the GetPublicAccessBlock operation: The public access block configuration was not found
ana@laptop:~/aws$ aws s3api get-bucket-ownership-controls --bucket clinic-records

aws: [ERROR]: An error occurred (OwnershipControlsNotFoundError) when calling the GetBucketOwnershipControls operation: The bucket ownership controls were not found
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket clinic-records
```

| setting | what it decides | what moto answered |
|---|---|---|
| default encryption | whether objects are encrypted at rest when they arrive | none set |
| Block Public Access | whether a policy or an ACL can make the bucket public | none set |
| object ownership | whether ACLs are in play at all, or the bucket's owner owns every object | none set |
| versioning | whether an overwritten or deleted object can be brought back | nothing printed: never switched on |

**Three errors and one silence, and none of them is a fault.** Each is the API saying "you have not
decided this yet". The point of reading them is that **the provider will not decide them for you
unless it says so in writing**, and the only way to know what your bucket is doing is to ask it.

## What AWS decides for you now, and moto does not

The answers above are moto's, and they are what AWS itself answered for years. They are not what a
bucket created in a real account today would say. AWS changed two defaults in 2023, and both are in
its documentation rather than in this lab:

- since **January 2023**, every new object is encrypted at rest with keys S3 manages (`SSE-S3`), so
  `get-bucket-encryption` on a new bucket reports `AES256`;
- since **April 2023**, a new bucket has all four Block Public Access switches on and object ownership
  set to `BucketOwnerEnforced`, which switches ACLs off.

**Not run here**: moto 5.2.3 applies neither. Notice what the changes did not move. The settings are
still yours: a default is a decision taken for you, and you may undo it with one request. The second
change also applied only to buckets created after it, so every bucket older than April 2023 kept the
public access settings it had. **A default protects the buckets nobody thought about; an inventory is
what finds the ones somebody changed.**

## Deciding them

Set the four, each with one request:

```
ana@laptop:~/aws$ aws s3api put-bucket-encryption --bucket clinic-records --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api put-bucket-ownership-controls --bucket clinic-records --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket clinic-records --versioning-configuration Status=Enabled
```

None of them printed anything, which is how most writes to this API succeed. So ask again, the same
four questions, and keep the answers:

```
ana@laptop:~/aws$ aws s3api get-bucket-encryption --bucket clinic-records --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault"
{
    "SSEAlgorithm": "AES256"
}
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
ana@laptop:~/aws$ aws s3api get-bucket-ownership-controls --bucket clinic-records --query "OwnershipControls.Rules[0].ObjectOwnership" --output text
BucketOwnerEnforced
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket clinic-records --query Status --output text
Enabled
```

**That transcript is the evidence for your half of the line**: four settings, read back from the
system that enforces them, at a time you can name. It is worth more than a document saying the
settings were meant to be like this, and lesson 16 turns the same questions into a program that asks
them of every bucket at once.

One warning carries through the rest of the course. **Stored is not the same as enforced**, and this
lab is the clearest case of it: moto now reports Block Public Access fully on, and lesson 9 shows it
serving a public object anyway. AWS enforces what it reports. Your evidence is only as good as the
system answering, and that is why each lesson says which of moto's answers AWS would contradict.
