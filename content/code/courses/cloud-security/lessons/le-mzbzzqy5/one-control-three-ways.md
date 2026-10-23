---
title: One control, written three ways
version: 1
---

**A security decision is made once, in a sentence. Enforcing it on three providers means writing it three times, in three
mechanisms at three levels, and checking each time that it holds.** The clinic's sentence is: *no patient file is ever readable by the public.* This section
writes it for each provider, runs the AWS half in your lab, and says what each half rests on.

## AWS: switches on the bucket and on the account

Start moto in the first terminal, without a count, and read `env.sh` in both. A new bucket, and the
question of whether anything blocks public access on it:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records

aws: [ERROR]: An error occurred (NoSuchPublicAccessBlockConfiguration) when calling the GetPublicAccessBlock operation: The public access block configuration was not found
```

**moto answers that no configuration exists.** AWS would not, for a bucket created since April 2023:
it switches all four settings on for every new bucket, and lesson 9 tells the story of why. That
difference is what moto lacks, not what AWS lacks, and it was not run. Set the four switches
explicitly, which is what the clinic's infrastructure code should do anyway rather than trust a
default:

```
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

The bucket's switches protect one bucket. The sentence says *ever*, so it belongs one level up, on
the **account**, where the same four switches cover every bucket that exists or will. That setting
lives in a different API, S3 Control, which addresses the account by putting its number in front of
the host name:

```
ana@laptop:~/aws$ aws s3control put-public-access-block --account-id 123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws: [ERROR]: Could not connect to the endpoint URL: "http://123456789012.localhost:4567/v20180820/configuration/publicAccessBlock"
```

`123456789012.localhost` is a name your computer does not resolve, so the request never reached moto.
On AWS the same command reaches `123456789012.s3-control.sa-east-1.amazonaws.com` and sets the account's
switches. **It was not run here**, and the lab cannot show it, which is why the lab works with the
bucket's switches.

Above the account sits the guardrail that keeps the switches on: a service control policy that
refuses anybody, except a named security role, the permission to change them. Written for the
clinic's organisation, it would read:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["s3:PutAccountPublicAccessBlock", "s3:PutBucketPublicAccessBlock"],
      "Resource": "*",
      "Condition": {
        "ArnNotLike": { "aws:PrincipalArn": "arn:aws:iam::*:role/security-admin" }
      }
    }
  ]
}
```

It was not run: moto stores service control policies and enforces none, and its condition would be
ignored as well. Two facts from AWS's documentation decide whether it would hold. It applies to the
member accounts below where it is attached, **never to the management account**; and it grants
nothing, so the `security-admin` role still needs an ordinary permission to change the switches.

## Azure and Google Cloud

| | the setting that makes the sentence true | the guardrail that keeps it true |
|---|---|---|
| Azure | `allowBlobPublicAccess` set to false on every storage account | an **Azure Policy** assignment on the management group, with the built-in definition that requires storage accounts to disallow public access, and a `Deny` effect |
| Google Cloud | **public access prevention** enforced on every bucket | the **Organization Policy** constraint `storage.publicAccessPrevention`, enforced on the organisation |

None of this was run. Read each row for where the guardrail sits: on Azure at a management group, so
every subscription below inherits it; on Google Cloud at the organisation, so every folder and project
does. **On AWS, at an OU or the root, with the management account outside its reach.** Three places,
three ways to be exempt, and an audit of the sentence has to visit all three.

## Proving the sentence

A setting proves that somebody set it. The sentence is about what a stranger can read, so it is
proved the way lesson 1 proved a fix: by asking as the stranger. For the clinic that is one anonymous
request per provider for an object that should be private, run on a schedule, with a failure going
to somebody's phone. **The three mechanisms differ; the evidence that they work is the same: a stranger refused.** The
words of the refusal differ too: S3 answers `403`, and Azure's documentation says an anonymous request
for a private container is answered as though it did not exist.
