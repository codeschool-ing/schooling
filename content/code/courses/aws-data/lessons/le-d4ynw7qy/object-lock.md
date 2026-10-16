---
title: Object Lock, retention and legal hold
version: 1
---

**Object Lock makes a version impossible to delete or overwrite until a date, for everybody,
including the account that owns it.** Versioning protects against accidents, because the marker can
be removed; it protects nothing against somebody who means it, because whoever may delete a marker
may also delete the versions. Object Lock is for the second case: a ransomware attack with stolen
keys, an employee covering something up, a rule that says invoices are kept for years. The last
case is the reason Quitanda has an archive bucket at all.

The lock lives on each version, as two separate things:

- **a retention period**, a date until which the version cannot be deleted or overwritten, in one of
  two modes, governance or compliance;
- **a legal hold**, an on-off switch with no date, which holds the version until somebody switches
  it off.

## A bucket that can lock

Object Lock has to be turned on when the bucket is created, and it turns versioning on with it. The
`aws s3 mb` of the earlier lessons has no option for it, so this is `s3api create-bucket`, which also
needs the region spelled out:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket quitanda-archive-prod --create-bucket-configuration LocationConstraint=sa-east-1 --object-lock-enabled-for-bucket
{
    "Location": "/quitanda-archive-prod"
}
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket quitanda-archive-prod
{
    "Status": "Enabled"
}
ana@laptop:~/aws$ aws s3api get-object-lock-configuration --bucket quitanda-archive-prod
{
    "ObjectLockConfiguration": {
        "ObjectLockEnabled": "Enabled"
    }
}
```

**The bucket was created versioned**, and `get-object-lock-configuration` confirms the lock is
enabled, with no default yet. A default retention applies to every version written from then on
unless the request says otherwise. Quitanda's invoices get one year in compliance mode:

```
ana@laptop:~/aws$ aws s3api put-object-lock-configuration --bucket quitanda-archive-prod --object-lock-configuration '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"COMPLIANCE","Years":1}}}'
ana@laptop:~/aws$ aws s3api get-object-lock-configuration --bucket quitanda-archive-prod
{
    "ObjectLockConfiguration": {
        "ObjectLockEnabled": "Enabled",
        "Rule": {
            "DefaultRetention": {
                "Mode": "COMPLIANCE",
                "Days": 0,
                "Years": 1
            }
        }
    }
}
```

## Compliance: nobody, for any reason

The invoice for October went in with no lock options on the request, and the default gave it one:

```
ana@laptop:~/aws$ printf 'invoice,total_cents\nnf-2026-10-0001,4590\n' > nf.csv && aws s3api put-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv --body nf.csv --query VersionId --output text
337702ea-3c36-4ad8-b8cc-c80abafdfcbc
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "COMPLIANCE",
    "2027-10-16T16:11:31+00:00"
]
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv --version-id 337702ea-3c36-4ad8-b8cc-c80abafdfcbc

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key invoices/2026-10/nf.csv
{
    "DeleteMarker": true,
    "VersionId": "a67d44d8-66ad-4ea5-9935-c366bcba79ad"
}
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-archive-prod --query '{versions: Versions[].[VersionId,IsLatest], markers: DeleteMarkers[].[VersionId,IsLatest]}'
{
    "versions": [
        [
            "337702ea-3c36-4ad8-b8cc-c80abafdfcbc",
            false
        ]
    ],
    "markers": [
        [
            "a67d44d8-66ad-4ea5-9935-c366bcba79ad",
            true
        ]
    ]
}
```

**The version cannot be deleted, and the key can.** `delete-object` with the version id was refused
with `AccessDenied`. `delete-object` without one succeeded, because in a versioned bucket that only
adds a delete marker; the locked version is still there underneath, which `list-object-versions`
shows. A lock protects versions, not keys: the invoice can be hidden, and it cannot be destroyed.

On AWS a compliance-mode retention cannot be shortened, cannot be switched to governance, and cannot
be lifted by any user, the account's root included, until its date passes. The only way to be rid
of it sooner is to close the AWS account. The next section shows that moto is not that strict.

## Governance: nobody without a permission

Governance mode refuses the same deletes unless the request carries
`--bypass-governance-retention`, and on AWS the bypass works only for an identity whose policy allows
`s3:BypassGovernanceRetention`. Write a version with a governance retention set on the request,
which overrides the bucket's default:

```
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --body nf.csv --object-lock-mode GOVERNANCE --object-lock-retain-until-date 2026-11-16T00:00:00Z --query VersionId --output text
6f7e8dae-f86b-4b68-a228-443c24541a9b
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --query '[ObjectLockMode,ObjectLockRetainUntilDate]'
[
    "GOVERNANCE",
    "2026-11-16T00:00:00+00:00"
]
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --version-id 6f7e8dae-f86b-4b68-a228-443c24541a9b

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key drafts/nf-draft.csv --version-id 6f7e8dae-f86b-4b68-a228-443c24541a9b --bypass-governance-retention
{
    "VersionId": "6f7e8dae-f86b-4b68-a228-443c24541a9b"
}
```

**Refused without the bypass, accepted with it.** In moto anybody may bypass, since no policy is
evaluated; on AWS the second delete would have needed that permission, which Quitanda grants to
nobody except a break-glass role. Governance is the mode to try a lock out in, and to use where a
small number of people must be able to correct a mistake. It is not protection against those people.

## Legal hold

```
ana@laptop:~/aws$ aws s3api put-object --bucket quitanda-archive-prod --key disputes/c-17/order.csv --body nf.csv --object-lock-mode GOVERNANCE --object-lock-retain-until-date 2026-10-17T00:00:00Z --query VersionId --output text
b8a79e2e-6826-4e41-a7d0-4a871ec8c76e
ana@laptop:~/aws$ aws s3api put-object-legal-hold --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e --legal-hold Status=ON
ana@laptop:~/aws$ aws s3api get-object-legal-hold --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e
{
    "LegalHold": {
        "Status": "ON"
    }
}
ana@laptop:~/aws$ aws s3api delete-object --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e --bypass-governance-retention

aws: [ERROR]: An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
ana@laptop:~/aws$ aws s3api get-object-retention --bucket quitanda-archive-prod --key disputes/c-17/order.csv --version-id b8a79e2e-6826-4e41-a7d0-4a871ec8c76e

aws: [ERROR]: An error occurred (500) when calling the GetObjectRetention operation (reached max retries: 2): Internal Server Error
```

**The hold refused the delete even with the bypass.** A legal hold has nothing to do with the modes
or the dates, and governance's bypass does not reach it; only switching the hold off, which needs
`s3:PutObjectLegalHold`, makes the version deletable again. It is the tool for "keep everything about
this customer until the court says otherwise", where nobody knows the end date.

A note on reading a retention back, which the last command above shows: `get-object-retention`
answers moto 5.2.3 with an internal server error, a defect of the imitation, so this lesson reads
`ObjectLockMode` and `ObjectLockRetainUntilDate` from `head-object`, which carries the same two
values.
