---
title: Reading the records of a bad afternoon
version: 1
---

**An investigation reads a trail with three questions, in this order: what changed, who changed it,
and what happened while it was changed.** The answers are filters over a file of records, and `jq`,
which lesson 1 installed, is enough to write them.

moto records nothing, so the records here are a file this lesson gives you. **They were written for
the course, not recorded by AWS**: six records in the format AWS documents for CloudTrail, abridged
to the fields the previous section's table named, about an afternoon at the clinic that lesson 1
would recognise. The addresses come from the ranges reserved for documentation. Save it as
`trail.json`:

```json
{
  "Records": [
    {
      "eventTime": "2026-10-14T12:02:11Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "PutBucketPolicy",
      "eventCategory": "Management",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "203.0.113.24",
      "userAgent": "aws-cli/2.37.4",
      "userIdentity": {
        "type": "IAMUser",
        "arn": "arn:aws:iam::123456789012:user/caio",
        "accountId": "123456789012",
        "accessKeyId": "AKIAEXAMPLECAIO00001",
        "userName": "caio"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "bucketPolicy": {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": "*",
              "Action": "s3:GetObject",
              "Resource": "arn:aws:s3:::clinic-exports/*"
            }
          ]
        }
      }
    },
    {
      "eventTime": "2026-10-14T12:40:05Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "GetObject",
      "eventCategory": "Data",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "198.51.100.77",
      "userAgent": "curl/8.5.0",
      "userIdentity": {
        "type": "AWSAccount",
        "accountId": "ANONYMOUS_PRINCIPAL"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "key": "2026-10-14.csv"
      }
    },
    {
      "eventTime": "2026-10-14T13:15:42Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "GetObject",
      "eventCategory": "Data",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "198.51.100.140",
      "userAgent": "python-requests/2.32.3",
      "userIdentity": {
        "type": "AWSAccount",
        "accountId": "ANONYMOUS_PRINCIPAL"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "key": "2026-10-13.csv"
      }
    },
    {
      "eventTime": "2026-10-14T14:03:09Z",
      "eventSource": "cloudtrail.amazonaws.com",
      "eventName": "StopLogging",
      "eventCategory": "Management",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "192.0.2.10",
      "userAgent": "aws-cli/2.31.0",
      "userIdentity": {
        "type": "IAMUser",
        "arn": "arn:aws:iam::123456789012:user/dani",
        "accountId": "123456789012",
        "accessKeyId": "AKIAEXAMPLEDANI00001",
        "userName": "dani"
      },
      "requestParameters": {
        "name": "clinic-trail"
      },
      "errorCode": "AccessDenied",
      "errorMessage": "User: arn:aws:iam::123456789012:user/dani is not authorized to perform: cloudtrail:StopLogging"
    },
    {
      "eventTime": "2026-10-14T15:30:27Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "DeleteBucketPolicy",
      "eventCategory": "Management",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "203.0.113.8",
      "userAgent": "aws-cli/2.37.4",
      "userIdentity": {
        "type": "IAMUser",
        "arn": "arn:aws:iam::123456789012:user/ana",
        "accountId": "123456789012",
        "accessKeyId": "AKIAEXAMPLEANA000001",
        "userName": "ana"
      },
      "requestParameters": {
        "bucketName": "clinic-exports"
      }
    },
    {
      "eventTime": "2026-10-14T15:31:02Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "GetObject",
      "eventCategory": "Data",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "198.51.100.77",
      "userAgent": "curl/8.5.0",
      "userIdentity": {
        "type": "AWSAccount",
        "accountId": "ANONYMOUS_PRINCIPAL"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "key": "2026-10-14.csv"
      },
      "errorCode": "AccessDenied",
      "errorMessage": "Access Denied"
    }
  ]
}
```

## What changed

Start with a count of what happened, which is the shape of the afternoon in one command:

```
ana@laptop:~/aws$ jq -r '.Records[] | .eventName' trail.json | sort | uniq -c
      1 DeleteBucketPolicy
      3 GetObject
      1 PutBucketPolicy
      1 StopLogging
```

## Who changed it

The change that matters is the policy on `clinic-exports`. Ask for the records that changed a
bucket's policy, and keep the fields that name a person:

```
ana@laptop:~/aws$ jq -c '.Records[] | select(.eventName | test("BucketPolicy")) | {eventTime, eventName, user: .userIdentity.userName, ip: .sourceIPAddress, bucket: .requestParameters.bucketName}' trail.json
{"eventTime":"2026-10-14T12:02:11Z","eventName":"PutBucketPolicy","user":"caio","ip":"203.0.113.24","bucket":"clinic-exports"}
{"eventTime":"2026-10-14T15:30:27Z","eventName":"DeleteBucketPolicy","user":"ana","ip":"203.0.113.8","bucket":"clinic-exports"}
```

**caio opened it at 12:02 and ana closed it at 15:30, in UTC.** The clinic is in São Paulo, three
hours behind, so the bucket was public from 09:02 to 12:30 local time. Every time a trail prints is
UTC, and a timeline that mixes it with a wall clock puts events in the wrong order.

The policy itself is in the record, under `requestParameters`. **The trail keeps what was asked for,
which is how you know the change was a public grant and not some other edit:**

```
ana@laptop:~/aws$ jq -c '.Records[] | select(.eventName == "PutBucketPolicy") | .requestParameters.bucketPolicy.Statement[] | {Principal, Action}' trail.json
{"Principal":"*","Action":"s3:GetObject"}
```

## What happened while it was changed

The reads that matter are the ones nobody signed. An anonymous caller has no ARN; CloudTrail records
it with the account `ANONYMOUS_PRINCIPAL`:

```
ana@laptop:~/aws$ jq -r '.Records[] | select(.userIdentity.accountId == "ANONYMOUS_PRINCIPAL") | [.eventTime, .sourceIPAddress, .requestParameters.key, (.errorCode // "served")] | @tsv' trail.json
2026-10-14T12:40:05Z	198.51.100.77	2026-10-14.csv	served
2026-10-14T13:15:42Z	198.51.100.140	2026-10-13.csv	served
2026-10-14T15:31:02Z	198.51.100.77	2026-10-14.csv	AccessDenied
```

**Two exports were served to two addresses nobody at the clinic knows, inside the window, and the
same address that came back after the fix was refused.** That is the evidence the incident report
needs: which files, which day's patients, how long they were exposed. The `soc-response` course's
lessons 20 and 21 turn exactly this into a report and an LGPD notification. Without the data events
the previous section paid for, the first query would still find caio's change, and this one would
find nothing at all.

## And what was refused

```
ana@laptop:~/aws$ jq -r '.Records[] | select(.errorCode) | [.eventTime, (.userIdentity.userName // .userIdentity.accountId), .eventName, .errorCode] | @tsv' trail.json
2026-10-14T14:03:09Z	dani	StopLogging	AccessDenied
2026-10-14T15:31:02Z	ANONYMOUS_PRINCIPAL	GetObject	AccessDenied
```

The second line is not about the bucket at all. **dani, who left in March, tried to stop the trail
from an address the clinic does not use, and was refused.** A refused `StopLogging` is one of the
records worth an alarm on its own, and the next section is about making sure the attempt stays
refused.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-timeline\" aria-label=\"A timeline of the afternoon in the lesson's sample records, in UTC, from 12:00 to 16:00. At 12:02 caio puts a bucket policy that makes clinic-exports public, and the exposure window opens. At 12:40 an anonymous caller at 198.51.100.77 is served 2026-10-14.csv, and at 13:15 another at 198.51.100.140 is served 2026-10-13.csv. At 14:03 dani's key tries StopLogging and is refused. At 15:30 ana deletes the bucket policy, and the window closes after 3 hours and 28 minutes. At 15:31 the first anonymous address comes back and is refused.\"><path d=\"M55.3 122.0 L610.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><path d=\"M55.3 116.0 L55.3 128.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M610.0 116.0 L610.0 128.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"332.7\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">public for 3 h 28 min</text><path d=\"M50.0 150.0 L690.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M50.0 146.0 L50.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"50.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M210.0 146.0 L210.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"210.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13:00</text><path d=\"M370.0 146.0 L370.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"370.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14:00</text><path d=\"M530.0 146.0 L530.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M690.0 146.0 L690.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"690.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16:00</text><text x=\"690.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">UTC</text><path d=\"M55.3 150.0 L55.3 112.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"55.3\" cy=\"150.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"59.3\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">caio makes it public</text><text x=\"59.3\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">PutBucketPolicy</text><path d=\"M156.7 150.0 L156.7 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"156.7\" cy=\"150.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"160.7\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">served to an anonymous caller</text><text x=\"160.7\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text><path d=\"M250.0 150.0 L250.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"250.0\" cy=\"150.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"254.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">served to another</text><text x=\"254.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.140</text><path d=\"M378.0 150.0 L378.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"378.0\" cy=\"150.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"382.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">dani's key, refused</text><text x=\"382.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">StopLogging</text><path d=\"M610.0 150.0 L610.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"610.0\" cy=\"150.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"606.0\" y=\"94.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ana closes it</text><text x=\"606.0\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DeleteBucketPolicy</text><path d=\"M612.7 150.0 L612.7 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"612.7\" cy=\"150.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"608.7\" y=\"196.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the first caller, refused</text><text x=\"608.7\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text></svg>", "caption": "The management events say when the window opened and closed; only the data events say what went through it."}
```
