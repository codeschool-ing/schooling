---
title: A trail of your own, and what moto does with it
version: 1
---

**A trail is three decisions: where the records go, which events they include, and whether it is
switched on.** This section makes all three for the clinic. moto accepts the whole configuration and
answers every question about it; what it does not do is write a single record. The end of the
section shows that plainly, rather than letting a quiet bucket pass for a quiet account.

Start moto with its checking on, as lesson 6 did, because the next section but one depends on a
refusal:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

The same three requests make `admin`, and the terminal moves onto admin's key:

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

## Where the records go

A bucket of their own, `clinic-trail`. CloudTrail writes into it as the service
`cloudtrail.amazonaws.com`, so the bucket's policy has to let the service check the bucket and write
under `AWSLogs/` with the account's number. This is the policy AWS's documentation gives, with the
clinic's names in it; save it as `trail-bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::clinic-trail",
      "Condition": {
        "StringEquals": { "aws:SourceArn": "arn:aws:cloudtrail:sa-east-1:123456789012:trail/clinic-trail" }
      }
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::clinic-trail/AWSLogs/123456789012/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control",
          "aws:SourceArn": "arn:aws:cloudtrail:sa-east-1:123456789012:trail/clinic-trail"
        }
      }
    }
  ]
}
```

The `aws:SourceArn` condition is lesson 13's confused deputy again: the service may write here on
behalf of this one trail, and not on behalf of a trail in somebody else's account that names your
bucket.

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-trail --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-trail
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-trail --policy file://trail-bucket-policy.json
```

Without that policy AWS refuses to create the trail, with `InsufficientS3BucketPolicyException`.
moto creates it either way; that refusal was not run here.

## Which events, and switching it on

Two flags at creation matter. `--is-multi-region-trail` records every region into the one trail, so a
resource started in a region nobody watches still leaves a record: lesson 1's 38 default networks are
the reason. `--enable-log-file-validation` makes CloudTrail write a signed *digest* file every hour,
which the section after next uses.

```
ana@laptop:~/aws$ aws cloudtrail create-trail --name clinic-trail --s3-bucket-name clinic-trail --is-multi-region-trail --enable-log-file-validation
{
    "Name": "clinic-trail",
    "S3BucketName": "clinic-trail",
    "IncludeGlobalServiceEvents": true,
    "IsMultiRegionTrail": true,
    "TrailARN": "arn:aws:cloudtrail:sa-east-1:123456789012:trail/clinic-trail",
    "LogFileValidationEnabled": true,
    "IsOrganizationTrail": false
}
```

Management events alone would answer who made a bucket public and not who read it while it was. The
data events worth paying for are the two buckets holding patients' data. Save the selectors as
`selectors.json`:

```json
[
  {
    "Name": "management",
    "FieldSelectors": [
      { "Field": "eventCategory", "Equals": ["Management"] }
    ]
  },
  {
    "Name": "patient-data",
    "FieldSelectors": [
      { "Field": "eventCategory", "Equals": ["Data"] },
      { "Field": "resources.type", "Equals": ["AWS::S3::Object"] },
      { "Field": "resources.ARN", "StartsWith": ["arn:aws:s3:::clinic-records/", "arn:aws:s3:::clinic-exports/"] }
    ]
  }
]
```

```
ana@laptop:~/aws$ aws cloudtrail put-event-selectors --trail-name clinic-trail --advanced-event-selectors file://selectors.json --query "AdvancedEventSelectors[].Name"
[
    "management",
    "patient-data"
]
ana@laptop:~/aws$ aws cloudtrail start-logging --name clinic-trail
```

## The status, and the bucket

```
ana@laptop:~/aws$ aws cloudtrail get-trail-status --name clinic-trail
{
    "IsLogging": true,
    "LatestDeliveryTime": "2026-10-23T04:05:05-03:00",
    "StartLoggingTime": "2026-10-23T04:05:05-03:00",
    "LatestDeliveryAttemptTime": "2026-10-23T04:05:05Z",
    "LatestNotificationAttemptTime": "",
    "LatestNotificationAttemptSucceeded": "",
    "LatestDeliveryAttemptSucceeded": "",
    "TimeLoggingStarted": "2026-10-23T04:05:05Z",
    "TimeLoggingStopped": ""
}
```

**`IsLogging` is `true`, and moto even reports a delivery time. Now look in the bucket**, and ask
the account's own event history while you are at it:

```
ana@laptop:~/aws$ aws s3 ls s3://clinic-trail --recursive
ana@laptop:~/aws$ aws cloudtrail lookup-events --max-results 5 2>&1 | head -2

aws: [ERROR]: An error occurred (500) when calling the LookupEvents operation (reached max retries: 2): <!doctype html>
```

The bucket is empty and the history answers with an internal error. **moto keeps a trail's
configuration and records no events at all.** On AWS, within minutes of `start-logging`, the bucket
would hold compressed files under `AWSLogs/123456789012/CloudTrail/sa-east-1/` and a folder per day,
and `lookup-events` would list the calls you just made, `StartLogging` among them. Neither was run
here.

The lesson in moto's gap is one you need on AWS too: **a status that says logging is not evidence
that records exist.** The check that counts is the one you just made, opening the bucket and finding
files from today. The next section reads records, and since moto writes none, they come from a file
the lesson gives you.
