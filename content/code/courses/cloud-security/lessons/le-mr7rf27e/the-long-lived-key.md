---
title: The key that crosses the seam
version: 1
---

**The simplest way to let a job on one provider act on another is to create a user on the second,
give it an access key, and paste the key into the first. It works on the first try, it never stops
working, and that is the whole problem.** This section builds the clinic's version of it in your lab
and then reads it the way an auditor would.

## moto, with its checking on

Lesson 6 is about permissions, but this section already needs moto to tell one key from another.
Start it in the first terminal with a count of requests it lets through before it begins checking:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

The first three requests, sent with the `test` key, create an administrator and give it a key. The
fourth is refused, which proves the checking is on, and the `export` moves this terminal onto the
administrator's key for the rest of the lesson:

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

A short function runs one command with another key, without changing the terminal's own. Type it
once; the transcripts use it whenever a request is made as somebody else:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

## The arrangement, as caio built it

A bucket for the export, a user for the job, a policy that lets it read the bucket, and a key:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-exports --key 2026-10-23.csv --query ETag --output text
"d41d8cd98f00b204e9800998ecf8427e"
ana@laptop:~/aws$ aws iam create-user --user-name reports-sync --query User.Arn --output text
arn:aws:iam::123456789012:user/reports-sync
ana@laptop:~/aws$ aws iam put-user-policy --user-name reports-sync --policy-name read-exports --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject","s3:ListBucket"],"Resource":["arn:aws:s3:::clinic-exports","arn:aws:s3:::clinic-exports/*"]}]}'
ana@laptop:~/aws$ sync=$(aws iam create-access-key --user-name reports-sync)
```

That last line is the one that crosses the seam. **The JSON in `$sync` holds a secret access key,
and in the clinic it was pasted into the configuration of a scheduled job in Google Cloud.** From
there, every night, the job does this:

```
ana@laptop:~/aws$ with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text
2026-10-23.csv
```

Read the arrangement from AWS's side. There is a user called `reports-sync`, which is not a person.
It has one key, created once. It reads one bucket. **Nothing in AWS says where the key lives**: the
other half of the arrangement is in another provider's console, behind another provider's
permissions, and the people who can read it there are not people AWS knows about.

## Reading it as an auditor

Two questions find a key like this in any account. The first is the **credential report**, a table
AWS keeps of every IAM user and the state of their credentials. Ask for it, and read five of its
columns:

```
ana@laptop:~/aws$ aws iam generate-credential-report --query State --output text
STARTED
ana@laptop:~/aws$ aws iam get-credential-report --query Content --output text | base64 -d | cut -d, -f1,9,10,11,13
user,access_key_1_active,access_key_1_last_rotated,access_key_1_last_used_date,access_key_1_last_used_service
admin,true,2026-10-23T03:47:15+00:00,2026-10-23T03:47:23+00:00,not_supported
reports-sync,true,2026-10-23T03:47:20+00:00,2026-10-23T03:47:21+00:00,not_supported
```

On AWS the report takes a few seconds to build, and asking for it too early is refused with an error
saying it is not ready; moto builds it at once. In the service column moto writes `not_supported`, where AWS writes the name of the service the
key last called. The second question, the key's own record of its last use, names it in moto too:

```
ana@laptop:~/aws$ aws iam get-access-key-last-used --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)"
{
    "UserName": "reports-sync",
    "AccessKeyLastUsed": {
        "LastUsedDate": "2026-10-23T03:47:21.621049+00:00",
        "ServiceName": "s3",
        "Region": "sa-east-1"
    }
}
```

**A key that was last rotated the day it was created and is used every night is a key held by a
machine.** That alone is not a fault. What makes it one is everything the report cannot say:

- **it never expires.** An IAM user's access key is valid until somebody deactivates it. If the
  secret leaks from the job's configuration in 2028, it still works in 2028;
- **its owner is on the other side.** The AWS team sees a user they did not create and cannot
  inspect the place it is stored. The Google Cloud team sees a string they were handed and does not
  manage;
- **rotating it takes both sides at once.** A new key has to be created in AWS and pasted into the
  other provider before the old one is switched off. When that needs two teams, it does not happen,
  which is why keys of this kind are commonly found years old;
- **the trail splits.** AWS records that the key read the bucket, from an address that belongs to
  Google. Which job, in which project, run by whom, is in Google Cloud's logs, and the two records
  share nothing but a time.

The last row of that list is said from AWS's and Google's documentation: moto keeps no CloudTrail
records (lesson 15), so the address a request came from was not captured here.

## The two levers, tried where breaking things is free

An access key can be **deactivated**, which is reversible, or **deleted**, which is not. In a real
account the order is always the same: deactivate, wait to see whether anything breaks, then delete.
Try both here, where breaking the nightly job costs nothing:

```
ana@laptop:~/aws$ aws iam update-access-key --user-name reports-sync --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)" --status Inactive
ana@laptop:~/aws$ with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text
2026-10-23.csv
```

**This is a place where moto and AWS disagree.** The key was marked `Inactive`, and moto still
answered the request made with it. AWS refuses a request signed with an inactive key; its
documentation says so, and this was not run. Deletion is something moto does enforce:

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name reports-sync --access-key-id "$(echo "$sync" | jq -r .AccessKey.AccessKeyId)"
ana@laptop:~/aws$ with_key "$sync" aws s3api list-objects-v2 --bucket clinic-exports --query "Contents[].Key" --output text

aws: [ERROR]: An error occurred (InvalidAccessKeyId) when calling the ListObjectsV2 operation: The AWS Access Key Id you provided does not exist in our records.
```

`InvalidAccessKeyId`, *does not exist in our records*: **as far as the API is concerned, a deleted
key never existed.** The next section replaces
the key with something that does not need retiring at all.
