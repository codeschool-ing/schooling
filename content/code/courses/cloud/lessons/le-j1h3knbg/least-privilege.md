---
title: Least privilege, and how access grows
version: 1
---

**Least privilege** means that every identity can do what its job needs and nothing next to it. The
principle is easy to agree with. What makes it hard is the order people work in: the usual way is to
start broad so that things work, meaning to trim later. Later rarely comes, because a policy that
allows too much produces no error, no ticket and no complaint. The only moment anybody notices is the
day somebody else uses it.

So the order is the other way round. Start from nothing, which the implicit deny already gives you,
and add the actions the job turns out to need. A refused request during development is cheap: it
names the action it wanted, and adding it is one line.

## A policy to read with suspicion

This is a policy written for a nightly job whose whole task is to upload a backup file to one bucket.
It works; the job has never failed.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    }
  ]
}
```

Everything wrong with it is visible in four lines:

- `"Action": "s3:*"` allows every S3 operation, not only uploading: deleting objects, deleting
  buckets, and rewriting a bucket's policy so that anybody on the internet can read it.
- `"Resource": "*"` applies that to every bucket in the account, not the one the backups go to. The
  reports, the customers' uploads and the logs are all in scope.
- `"Action": "iam:*"` is the worst line, and it is not about storage at all. **An identity that can
  change IAM can give itself anything**: it can attach an administrator policy to its own role or
  create a new user with keys. `iam:*` is administrator access under a different name.
- There is no condition anywhere, so none of this depends on where the request comes from or when.

What the job needs is one action on one prefix of one bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::example-backups/nightly/*"
    }
  ]
}
```

If the credentials of this job leak, the person holding them can write files under `nightly/` in one
bucket. That is still a problem, and it is a much smaller one than the first policy's.

## What to look for

When you read somebody else's policy, the lines to stop at are few:

- a `*` alone in `Action` or in `Resource`;
- a whole service, `s3:*` or `ec2:*`, where the job does one thing in it;
- anything in `iam:` given to an identity whose job is not managing identities;
- a wildcard in the middle of a name, such as `s3:Get*`. It looks narrow, since it reads like
  "only reading". It also matches `s3:GetBucketPolicy` and every other `Get` action S3 has, including
  ones the provider adds next year: a wildcard matches actions that did not exist when it was written.

## Access that grew and was never removed

Most excess access was not written in one go. It accumulated. Somebody moved from the payments team
to the reports team and kept both groups. An incident at two in the morning needed a broad grant for
an hour, and the grant is still there two years later. A service was retired and its role kept every
permission, waiting for somebody to find its credentials.

**Nothing expires unless somebody makes it expire**, so the answer is a habit: a review, on a
calendar. Providers help with the evidence. AWS shows, for each identity, when each service was last
used by it, and a permission unused for months is a question to ask its owner. Some providers go
further and can draft a narrower policy from the calls an identity actually made. Either way, the
review is a person deciding, and the auditing section at the end of this lesson says what it looks at.
