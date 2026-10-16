---
title: Reading one record
version: 1
---

A CloudTrail record is a JSON object, and five of its fields answer most questions. This one is abridged
from the format AWS documents, as the next section's made-up day writes it:

```json
{
  "eventTime": "2026-10-15T14:05:00Z",
  "eventSource": "s3.amazonaws.com",
  "eventName": "DeleteBucket",
  "awsRegion": "sa-east-1",
  "sourceIPAddress": "198.51.100.77",
  "userAgent": "aws-cli/2.37.4",
  "userIdentity": {
    "type": "AssumedRole",
    "arn": "arn:aws:sts::123456789012:assumed-role/shop-admin/bruno",
    "accountId": "123456789012",
    "sessionContext": {
      "sessionIssuer": { "type": "Role", "userName": "shop-admin", "arn": "arn:aws:iam::123456789012:role/shop-admin" }
    }
  },
  "requestParameters": { "bucketName": "shop-exports-old" },
  "readOnly": false
}
```

| field | answers |
|---|---|
| `eventTime` | when, always in UTC |
| `eventSource`, `eventName` | which service, which operation |
| `userIdentity` | who, and through which role |
| `sourceIPAddress`, `userAgent` | from where, and with what program |
| `requestParameters`, `errorCode` | on what, and whether it worked |

## Who, through a role

People in a well-run account do not have users with keys; they **assume roles**, as `aws-foundations`
and lesson 17 taught. So `userIdentity.type` is `AssumedRole`, and the identity has two parts. The
**role**, `shop-admin`, says what the caller was allowed to do. The **session name**, the last part of the
ARN, `bruno`, says who it was, provided the way people get into the account sets it to their own name,
which IAM Identity Center does and a shared script with a fixed session name does not. **An audit log
that says `assumed-role/admin/session` for everybody answers *who* with *somebody*.**

`readOnly` separates the reads from the changes, and is usually the first filter: an account makes
thousands of `Describe` calls a day and a handful of changes, and the question is nearly always about a
change. A record that failed carries `errorCode` and `errorMessage`, and **failures are evidence too**: a
burst of `AccessDenied` from one identity is somebody trying doors.
