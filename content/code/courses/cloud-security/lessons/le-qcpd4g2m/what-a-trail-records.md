---
title: What a trail records, and what it leaves out
version: 1
---

**CloudTrail writes one record for each call made to the AWS API: who made it, from where, when,
what they asked for and whether it was allowed.** Since lesson 1, every change to the clinic's
account has been one such call. So the trail is the account's memory of who changed what, and the
only one there is: lesson 1 said you cannot tap the wire, and a server that was deleted cannot be
examined afterwards.

The wrong belief is that "CloudTrail is on" means everything is recorded. Three things limit what a
trail holds, and an investigation finds out about all three at the worst moment.

## Management events and data events

| | what it covers | example | recorded by default |
|---|---|---|---|
| **management event** | a change to, or a read of, the configuration of a resource | `CreateBucket`, `PutBucketPolicy`, `AttachUserPolicy`, `StopLogging` | **yes** |
| **data event** | an operation on the data inside a resource | `GetObject` and `PutObject` on S3, `Invoke` on Lambda | **no**: you choose them, resource by resource, and pay per event |

**The question after an exposure is almost always a data-event question.** Who made the bucket public
is a management event, and it is there. Who downloaded the file while it was public is a data event,
and it is there only if somebody chose, beforehand, to record reads of that bucket. A trail switched
on afterwards records nothing about the days before.

## Without a trail, ninety days of one kind

Every account has *event history* with no setup at all: the last 90 days of management events, in
one region at a time, searchable in the console or with `aws cloudtrail lookup-events`. It has no
data events, it cannot be kept longer, and it lives in the same account as the people it records.
A **trail** is the configuration that writes records as files into an S3 bucket you choose, for as
long as you keep them, including the data events you selected.

## The fields of one record

A record is a JSON object. These are the fields this lesson reads, from AWS's description of the
record format:

| field | what it holds |
|---|---|
| `eventTime` | when the call was made, **always in UTC** |
| `eventSource`, `eventName` | the service and the operation: `s3.amazonaws.com`, `PutBucketPolicy` |
| `userIdentity` | who made it: the type (an IAM user, an assumed role, an AWS service, an anonymous caller), the ARN, the access key used |
| `sourceIPAddress` | the address the call came from, or the name of the AWS service that made it |
| `userAgent` | the program that made the call: the AWS CLI, an SDK, the console |
| `requestParameters` | what was asked for: the bucket, the key, the policy |
| `errorCode`, `errorMessage` | present only when the call failed, such as `AccessDenied` |
| `eventCategory` | `Management` or `Data` |

**A refused call is recorded too**, with its `errorCode`. That is easy to miss and it is often the
first sign of trouble: somebody holding a key, trying things it does not allow.

## What no trail records

A trail records calls to the AWS API, and nothing that happens without one. **Commands run inside an
instance, queries sent to a database, requests to the clinic's own booking application: none of
them is an AWS API call**, and each needs its own logs, from the operating system, the database or
the application. Network traffic is VPC flow logs, which lesson 8 met. And the content of a request
is not recorded either: a `PutObject` record names the object, never what was in it.
