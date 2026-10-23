---
title: Three kinds of key, and which one you can see
version: 1
---

**In AWS, every key that encrypts your data at rest is one of three kinds. What tells them apart is
what you can see and control: nothing, a little, or everything.** All three are held
by AWS's Key Management Service, KMS, in hardware AWS runs, and none of them ever leaves it in plain
form. What changes is whose policy decides who may use the key.

| kind | example | who writes its policy | can you disable or delete it? | is each use logged in your account? |
|---|---|---|---|---|
| AWS owned key | the key behind S3's `AES256`, the encryption of the last section | AWS, invisibly | no | no |
| AWS managed key | `aws/s3`, `aws/ebs`: made in your account the first time a service needs one | AWS; you can read it, not change it | no | yes |
| customer managed key | a key the clinic creates for its records | **the clinic** | yes | yes |

The table comes from KMS's documentation. Two consequences matter to a defender. **Only a customer
managed key lets you say who may decrypt** separately from who may read the bucket. And **only keys
in your account leave a trail** in your logs: every decryption with an AWS managed or customer
managed key is a CloudTrail event, which lesson 15 reads, while the AWS owned key works where you
cannot see it.

## A customer managed key, in your lab

Start moto empty and create the clinic's key. An alias is a readable name for it, `alias/` and
whatever you choose, so that nothing has to quote the key's id:

```
ana@laptop:~/aws$ k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)
ana@laptop:~/aws$ aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"
ana@laptop:~/aws$ aws kms describe-key --key-id alias/clinic-records --query "KeyMetadata.[KeyManager,KeyState,Origin]" --output text
CUSTOMER	Enabled	AWS_KMS
ana@laptop:~/aws$ aws kms list-aliases --query "Aliases[].AliasName"
[
    "alias/clinic-records",
    "alias/aws/acm",
    "alias/aws/dynamodb",
    "alias/aws/ebs",
    "alias/aws/elasticfilesystem",
    "alias/aws/es",
    "alias/aws/glue",
    "alias/aws/kinesisvideo",
    "alias/aws/lambda",
    "alias/aws/rds",
    "alias/aws/redshift",
    "alias/aws/s3",
    "alias/aws/secretsmanager",
    "alias/aws/ssm",
    "alias/aws/xray"
]
```

**`CUSTOMER` is the third row of the table**, `Enabled` is the key's state, and `AWS_KMS` says KMS
generated the key material itself rather than receiving it from you. Among the aliases, `alias/aws/`
followed by a service's name is how AWS managed keys are named. moto lists their names; in a real
account each appears the first time that service encrypts something for you.

## The key policy, which decides first

Every KMS key has a **key policy**, a resource policy attached to the key, and a new key gets this
one unless you write your own. `get-key-policy`, like most of the calls that administer a key, takes
the key's id or ARN and refuses its alias, in AWS as in moto; that is what `k` was kept for:

```
ana@laptop:~/aws$ aws kms get-key-policy --key-id "$k" --policy-name default --query Policy --output text
{"Version": "2012-10-17", "Id": "key-default-1", "Statement": [{"Sid": "Enable IAM User Permissions", "Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::123456789012:root"}, "Action": "kms:*", "Resource": "*"}]}
```

It allows `kms:*` to the principal `arn:aws:iam::123456789012:root`, and that principal does not
mean the root user. **It means the account**, and what it does is hand the decision to IAM: any user
or role whose identity policy allows a KMS action on this key may perform it. That is the default
because without it nobody could administer the key.

The rule underneath is the one that makes KMS different from almost every other service, and it is
from KMS's documentation: **no IAM policy grants use of a KMS key unless the key policy allows it**,
either directly or by delegating to the account as this one does. A key policy that names only the
clinic's records application, and no longer delegates to the account, is a key that an administrator
with `AdministratorAccess` cannot decrypt with. That is a strong control and a sharp edge: a key
policy that names nobody who can still change it is a key nobody can manage, and the way back that
KMS documents goes through AWS Support.
