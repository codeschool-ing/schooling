---
title: The fix, and the proof that it holds
version: 1
---

**Fixing an exposed bucket is three things in order: take the grant away, put the guardrail on so it
cannot come back, and ask again as the stranger.** The first is what people do. The second is what
stops the next person. The third is the only one that tells you the first two worked.

The wrong idea is that the fix is deleting the bucket, or the file. Somebody needed that file shared,
which is how the grant got there; take the sharing away without giving them a better way and the
grant is back next week, in a bucket you have not heard of. So each fix below comes with the way the
work should have been done.

## Take the grants away

The letter and the report each lose their grant:

```
ana@laptop:~/aws$ aws s3api put-object-acl --bucket clinic-referrals --key referral-0412.txt --acl private
ana@laptop:~/aws$ aws s3api put-object-acl --bucket clinic-reports --key report-2026-09.csv --acl private
```

**The hospital still needs its letter.** A link that works for one recipient, for a few days, is a
presigned URL, and lesson 10 makes one. bia's report goes to people inside the clinic, who have
their own credentials and need no grant to every AWS account in the world.

## Put the guardrails on

The reports bucket gets the four switches, and every bucket gets `BucketOwnerEnforced`, so that no
ACL is ever consulted again:

```
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-reports --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ for b in clinic-referrals clinic-reports clinic-records; do aws s3api put-bucket-ownership-controls --bucket "$b" --ownership-controls "Rules=[{ObjectOwnership=BucketOwnerEnforced}]"; done
```

On a real account the order matters: AWS refuses `BucketOwnerEnforced` on a bucket whose bucket ACL
still grants access to anybody but its owner, by its documentation, so the grants come off first, as
here. On AWS, the account-level switches of the last section would go on too.

## Ask again

```
ana@laptop:~/aws$ python3 public_buckets.py
clinic-referrals
    nothing found
clinic-reports
    nothing found
clinic-records
    nothing found
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt
403
```

**Nothing found, three times, and the letter refused to a request with no identity.** That last part
is the proof, and in this lab it is carried by the grant being gone: moto would still have served
the letter if its ACL were public, guardrail or not. On AWS, the guardrail would hold even if
somebody put the grant back, and the same command, run tomorrow, is how you would know.

## A bucket that must be public

Some content is meant for everybody: the clinic's website, its opening hours, a leaflet. AWS's
documented pattern keeps even that bucket private. **A CloudFront distribution reads the bucket
through an origin access control**, and the bucket policy allows that one distribution and nobody
else. The public gets the files through CloudFront; nobody can ask the bucket directly; and the
account-level guardrail stays on for every bucket without an exception to remember. That pattern
was not run here, since moto does not serve CloudFront.

Run the checker on a schedule, not once. A finding that appears on Tuesday was a change somebody made
on Monday, and lesson 15 is about finding out who.
