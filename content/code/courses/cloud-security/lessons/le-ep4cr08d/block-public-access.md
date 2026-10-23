---
title: Block Public Access: four switches above every grant
version: 1
---

**Block Public Access is a layer above the policies and the ACLs: when it is on, a public grant is
refused when somebody tries to write it, and ignored if it was already there.** It does not decide
who may read a bucket. It decides that nobody may make it public, whoever they are and whatever they
write, until the switch is turned off.

That is the difference between a guardrail and a rule. A rule is something people should follow;
lesson 1's quick fix broke one without noticing. A guardrail makes the quick fix fail.

## The four switches

| switch | what it does, by AWS's documentation |
|---|---|
| `BlockPublicAcls` | refuses any request that would add a public ACL, to the bucket or an object |
| `IgnorePublicAcls` | ignores the public ACLs already in place: they stay written and grant nothing |
| `BlockPublicPolicy` | refuses a bucket policy that grants public access |
| `RestrictPublicBuckets` | limits a bucket with a public policy to AWS services and the bucket owner's own account |

Two are about **new** grants and two about **existing** ones, and that is why there are four. A
bucket switched to `BlockPublicAcls` alone keeps answering everybody through the grant it already
had; `IgnorePublicAcls` is what closes that. **Turn on all four**, which is what AWS has done for
every new bucket since April 2023.

They exist at two levels. On a bucket, they protect that bucket. On the **account**, through the S3
Control API, they protect every bucket in it, including the ones created next year by somebody who
never heard of this lesson, and a bucket's own setting cannot loosen the account's. The account
level is the one worth having; the bucket level is for the account that cannot have it yet.

## In the lab, and where moto stops

Switch all four on for the referrals bucket, and read them back:

```
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-referrals --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-referrals
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

Now ask, as the stranger, for the letter whose ACL still says `AllUsers`, and then try to write that
grant again:

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt
200
ana@laptop:~/aws$ aws s3api put-object-acl --bucket clinic-referrals --key referral-0412.txt --acl public-read
ana@laptop:~/aws$ aws s3api get-object-acl --bucket clinic-referrals --key referral-0412.txt --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
```

**moto served the letter and accepted the new grant. AWS would have done neither.** By its
documentation, `IgnorePublicAcls` makes the existing grant count for nothing, so the anonymous
request is refused, and `BlockPublicAcls` refuses the `put-object-acl` with `AccessDenied`. moto
stores Block Public Access and enforces none of it, as lesson 1's table says, and those two answers
are AWS's documentation, not a run.

That is worth seeing for itself: **a guardrail you have only read back is not a guardrail you have
tested.** On a real account, the anonymous request above is the test, and it is the same command.

## Two more settings that close the same door

**Object Ownership set to `BucketOwnerEnforced` disables ACLs altogether.** The bucket owner owns
every object, and no ACL, public or not, is consulted at all; access comes from policies alone. It
removes three of the four routes of the last section in one setting, and it is the default for new
buckets since April 2023 too. moto stores this one as well and still applies the ACLs.

The account-level switches are set with `aws s3control put-public-access-block --account-id …`.
**That command was not run here**: the AWS command line sends S3 Control requests to an address
that starts with the account id, which a lab on `localhost` does not answer. On a real account it is
the first setting to check.
