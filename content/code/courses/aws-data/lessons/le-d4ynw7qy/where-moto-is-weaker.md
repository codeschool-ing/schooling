---
title: Where moto's lock is weaker than S3's
version: 1
---

**moto refuses the deletes a lock forbids, and it lets you take the lock off.** The previous section
showed the half moto gets right. This one shows the half it does not, because a lock tested only
against moto can look like a guarantee and be nothing of the kind, and because the steps below are
exactly the ones S3 exists to refuse.

In the same archive bucket, lock September's invoice in compliance mode until October 2027, and then
try to undo the lock:

```
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --body nf.csv --object-lock-mode COMPLIANCE --object-lock-retain-until-date 2027-10-16T00:00:00Z --query VersionId --output text
e8fceec3-e2e9-4235-b19a-07c2db180b2c
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "COMPLIANCE",
    "2027-10-16T00:00:00+00:00"
]
ana@laptop:~/aws$ aws s3api put-object-retention --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --version-id e8fceec3-e2e9-4235-b19a-07c2db180b2c --retention Mode=GOVERNANCE,RetainUntilDate=2026-10-17T00:00:00Z
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "GOVERNANCE",
    "2026-10-17T00:00:00+00:00"
]
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key invoices/2026-09/nf.csv --version-id e8fceec3-e2e9-4235-b19a-07c2db180b2c --bypass-governance-retention
{
    "VersionId": "e8fceec3-e2e9-4235-b19a-07c2db180b2c"
}
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-archive-prod --prefix invoices/2026-09/ --query 'Versions'
null
```

**moto changed a compliance retention into a governance one, a year shorter, and then let the version
be deleted with the bypass**; the empty listing at the end says that no version of the invoice is
left. Every one of those three steps is refused by S3. A compliance retention
can be extended and never shortened, its mode cannot be changed, and no permission, the root user's
included, makes a locked version deletable before its date. Those three requests are what a lock
exists to stop, sent by whoever holds Quitanda's keys, and S3 stops them at the first one.

The same holds for the bucket's versioning:

```
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-archive-prod --versioning-configuration Status=Suspended
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-archive-prod
{
    "Status": "Suspended"
}
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-11/nf.csv --body nf.csv --query VersionId --output text
None
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-12/nf.csv --body nf.csv --query VersionId --output text
None
```

**moto suspended versioning on a bucket with Object Lock.** S3 refuses this as well, since a lock
without versions would protect nothing. The two writes that followed came back with no version
id at all, which the command line prints as `None`; on S3 the suspension would have been refused and
both would have got a version of their own.

## So what does a moto test prove?

That the requests are well formed: the bucket was created with the lock, the default retention was
written the right way, the delete without a bypass was refused. It proves nothing about whether a
lock can be undone, because moto allows what S3 forbids. **Test a lock against moto for its shape
and believe AWS's documentation for its strength.** A real check of compliance mode needs a real
account, and costs a year of storage for the version you lock, since nothing can remove it sooner.

## MFA delete, described and not run

Before Object Lock existed, a bucket's last defence was MFA delete, and it is still a setting of
versioning. With it on, two things need a code from the root user's MFA device in the request
itself: deleting a version for good, and changing the bucket's versioning state. It can only be
turned on by the root user, only through the API or the command line, never the console, with the
code passed as `--mfa` on `put-bucket-versioning`.

It was not run here: it needs the root user's MFA device, which is exactly the thing this course
never has. It is also rarely the right choice now. It ties every permanent delete to one physical
device held by one person, and AWS's documentation says a bucket with MFA delete cannot use a
life-cycle configuration, so the rule of the section on costs could not exist beside it. Object Lock in governance mode,
with the bypass permission held by a single role, does the same job without the device.
