---
title: Two locks on the same object
version: 1
---

**With a customer managed key, reading an object takes two permissions: `s3:GetObject` on the
bucket, and `kms:Decrypt` on the key.** They are written in different places, usually by different
people, and a request missing either one is refused. That is what a key buys a defender: a grant on
the bucket that is too broad no longer exposes the records by itself.

The clinic has exactly that too-broad grant. bia reads reports, and somebody gave her AWS's
`AmazonS3ReadOnlyAccess`, which allows reading **every** bucket in the account, `clinic-records`
included. Rewriting her policy is the right fix and lesson 6 is about it. This section shows the
second lock holding while the first one is wrong.

## Checking on

This needs moto to judge requests, so start it the way lesson 6 did. In the first terminal:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

In the second, the same three requests make `admin`, and the fourth proves the checking is on:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

And lesson 6's `with_key`, which runs one command with another user's key:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

## The bucket encrypts with the clinic's key by default

A **default encryption** setting on the bucket makes S3 encrypt every new object with the key it
names, whatever the uploader asked for. `BucketKeyEnabled` is the part that keeps the bill down, and
the next section says why. The record uploaded is `record.txt`, from the first section of this
lesson.

```
ana@laptop:~/aws$ k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)
ana@laptop:~/aws$ aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api put-bucket-encryption --bucket clinic-records --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/clinic-records"},"BucketKeyEnabled":true}]}'
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-records --key maria-souza.txt --body record.txt --query "[ServerSideEncryption,SSEKMSKeyId]" --output text
aws:kms	alias/clinic-records
```

The record went in as `aws:kms`, under `alias/clinic-records`, without the upload mentioning either.
**Setting the default on the bucket is what makes encryption a property of the place rather than a
habit of each person writing to it.**

## bia, with one lock open

bia gets her user, a key and the over-broad S3 policy:

```
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
```

Can she use the key? Encrypt a copy of the record with it as admin, and ask KMS to decrypt it with
bia's key:

```
ana@laptop:~/aws$ aws kms encrypt --key-id alias/clinic-records --plaintext fileb://record.txt --query CiphertextBlob --output text | base64 -d > record.enc
ana@laptop:~/aws$ with_key "$bia" aws kms decrypt --ciphertext-blob fileb://record.enc --query Plaintext --output text

aws: [ERROR]: An error occurred (403) when calling the Decrypt operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:iam::123456789012:user/bia is not authorized to perform: kms:Decrypt</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
```

**Refused, and for the right reason**: nothing gives bia `kms:Decrypt`. moto judged this exactly as
AWS would. Now the same record through S3:

```
ana@laptop:~/aws$ with_key "$bia" aws s3 cp s3://clinic-records/maria-souza.txt -
patient: Maria Souza
allergy: penicillin
```

**Here moto and AWS part ways.** moto served the record, because when S3 reads an object encrypted
with a KMS key moto does not check the reader's permission on the key. AWS does: S3 asks KMS to
decrypt on bia's behalf, KMS refuses, and bia gets `AccessDenied`. **That refusal is from the S3 and
KMS documentation and was not run here.** The decrypt request just above is the part of it moto
does judge, and it said no.

AWS goes one step further for anonymous requests. An object encrypted with a KMS key can only be read
by a request signed with AWS's Signature Version 4, so the public bucket policy of the first section
would not have exposed it: an anonymous request has no identity for KMS to authorise. moto serves it
anyway, so that too is from the documentation.

## What to take from it

The clinic still has to fix bia's policy; a second lock is not a reason to leave the first one
broken. But compare the two failures: **with S3's own key, one wrong policy exposed the records; with
the clinic's key, it took two**, written in two places, and the second is a key policy that very few
people ever touch. Defence in depth, from the `security-fundamentals` course, is that sentence.
