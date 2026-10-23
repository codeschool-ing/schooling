---
title: What a company can actually control
version: 1
---

**A company cannot configure an account it does not own.** Every control in this section works on
one of three things the clinic does own: its own tenants, its own network and devices, and its own
buckets. Shadow storage is fought from those three, and the first of them matters most, because a
rule against personal accounts without a company service as easy to use only moves the file to a
place the rule cannot see.

## 1. A company service, set up narrowly

bia used her own Drive because it was the quickest way to send a large file. The clinic's answer is
a company account that is just as quick, with its sharing set the way the clinic wants:

- **links open to the organisation by default**, so the person sharing has to choose to go wider;
- **external sharing limited to named guests, or to listed partner domains** such as the
  accountant's;
- **an expiry on any open link**, where the service allows one, so a link sent in March is dead by
  April;
- **a report of what is shared outside**, read by somebody on a schedule.

All four are settings of the tenant's admin console in Microsoft 365 and Google Workspace, as the
table in the section before described. **None of them was run here**: they are taken from each
provider's documentation.

## 2. Seeing and steering from the network

A file uploaded to a personal Dropbox leaves through the company's network or from a company
laptop, and that is where it can be seen.

- **A CASB**, a cloud access security broker, reads the company's proxy and firewall logs and lists
  every cloud service people use, with how much they upload to each. It is how shadow storage is
  found in the first place: the inventory of services nobody approved.
- **Tenant restrictions** let the company's network allow sign-in to the company's own Microsoft or
  Google tenant and refuse sign-in to personal accounts of the same service. The address is the
  same, `onedrive.live.com` or `drive.google.com`, so blocking the service would block the company
  too; what is checked is which account is signing in.

::: track security
- **DLP**, data loss prevention, is the `defense-hardening` course's lesson 9: content inspection
  that recognises a CPF number or a medical term in an upload and stops it. Here it is the same
  control, pointed at cloud storage instead of USB sticks.
:::

::: track *
- **DLP**, data loss prevention, inspects what is being uploaded and recognises, for instance, a
  CPF number or a medical term, then blocks the upload or asks for a reason. It is the same control
  that watches USB sticks and e-mail, pointed at cloud storage.
:::

None of these sees a phone on its own mobile data. **That is the honest limit**, and the reason the
first section of this lesson comes first.

## 3. The clinic's own buckets

For S3, the control sits in the bucket policy, and AWS gives it two condition keys made for
presigned URLs. **`s3:authType`** is `REST-QUERY-STRING` when a request is signed in the address,
which is what a presigned URL is. **`s3:signatureAge`** is how old the signature is, in
milliseconds. So the clinic can forbid links outright on `clinic-records`, where no file should ever
leave by link. On `clinic-results` it can allow them only while they are ten minutes old:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NoLinksToRecords",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::clinic-records/*",
      "Condition": { "StringEquals": { "s3:authType": "REST-QUERY-STRING" } }
    }
  ]
}
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ResultLinksLiveTenMinutes",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::clinic-results/*",
      "Condition": { "NumericGreaterThan": { "s3:signatureAge": "600000" } }
    }
  ]
}
```

**A `Deny` with a condition is how a guardrail is written**, because no link anybody makes can
outlast it: the signer's own `--expires-in` is a promise, and this is the bucket's. Neither policy
was run here, since moto stores conditions and ignores them; the two keys and their meanings are
from AWS's documentation of S3's condition keys.

## When somebody leaves

The day dani left in March, somebody was meant to close her access to the clinic's AWS account,
and lesson 6 finds what was missed. **For a file she put in her own Dropbox, there is nothing to close.** The best the
clinic can do is ask, and record that it asked. That is why every control above prevents rather than
cleans up: shadow storage is the one exposure in this course whose fix cannot be proved by asking
again, because the clinic has nowhere to ask.
