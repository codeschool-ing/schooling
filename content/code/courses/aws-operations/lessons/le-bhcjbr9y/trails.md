---
title: Event history, and a trail of your own
version: 1
---

Every request to an AWS API, from the console, the command line, an SDK or another AWS service, is an
**event**, and CloudTrail records it: who asked, from where, for what, and what the answer was. That is
the record lesson 13's timeline would have wanted, and the one that answers the question every incident
asks sooner or later: **who did this?**

CloudTrail keeps two things that are easy to confuse:

| | event history | a trail |
|---|---|---|
| what it holds | management events, the last 90 days | whatever its selectors choose, for as long as the bucket keeps it |
| where | inside CloudTrail, searchable by one attribute at a time | files in an S3 bucket, and optionally a CloudWatch Logs group |
| set up | nothing; always on | created by the team |
| costs | nothing | the first copy of management events free; data events and further copies priced |

**Event history is not an audit log**: ninety days is shorter than most of the questions people ask, and
nobody controls it. A trail is the audit log. It writes a file every few minutes to a bucket, and the
bucket's lifecycle and object lock decide how long the evidence lives.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"An API request from the console, the command line or an SDK becomes one CloudTrail event. The event goes to four places: the event history, kept 90 days and searched by one attribute; a trail to S3, as files with hourly digests; a trail to CloudWatch Logs, where a metric filter feeds an alarm; and EventBridge, where a rule matches the event by name. The first two are read after the fact; the last two act as it happens.\"><defs><marker id=\"trl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"120\" width=\"130\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">an API request</text><text x=\"85.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">console, CLI, SDK</text><path d=\"M152 144 L198 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"200\" y=\"112\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260.0\" y=\"135.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CloudTrail</text><text x=\"260.0\" y=\"152.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one event</text><rect x=\"400\" y=\"20\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"500.0\" y=\"36.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">event history</text><text x=\"500.0\" y=\"51.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">90 days, one attribute</text><path d=\"M322 144 L398 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"400\" y=\"88\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"104.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">trail to S3</text><text x=\"500.0\" y=\"119.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">files and hourly digests</text><path d=\"M322 144 L398 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"400\" y=\"156\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">trail to CloudWatch Logs</text><text x=\"500.0\" y=\"187.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">metric filter, then alarm</text><path d=\"M322 144 L398 180\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><rect x=\"400\" y=\"224\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"240.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EventBridge</text><text x=\"500.0\" y=\"255.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a rule per event name</text><path d=\"M322 144 L398 248\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#trl-ah)\"></path><text x=\"660\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after</text><text x=\"660\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the fact</text><text x=\"660\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">as it</text><text x=\"660\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">happens</text></svg>", "caption": "One event, four destinations. The audit log is the trail; the alarms are the last two."}
```

## Creating the shop's

Work in `~/aws/trail` (`mkdir -p ~/aws/trail && cd ~/aws/trail`). A bucket, and a trail that covers every
region and validates its files:

```
ana@laptop:~/aws/trail$ aws s3 mb s3://shop-trail-123456789012
make_bucket: shop-trail-123456789012
ana@laptop:~/aws/trail$ aws cloudtrail create-trail --name shop --s3-bucket-name shop-trail-123456789012 --is-multi-region-trail --enable-log-file-validation --query '[TrailARN,IsMultiRegionTrail,LogFileValidationEnabled]' --output text
arn:aws:cloudtrail:sa-east-1:123456789012:trail/shop	True	True
ana@laptop:~/aws/trail$ aws cloudtrail start-logging --name shop
ana@laptop:~/aws/trail$ aws cloudtrail get-trail-status --name shop --query '[IsLogging,LatestDeliveryTime]' --output text
True	2026-10-16T19:49:02-03:00
ana@laptop:~/aws/trail$ aws s3 ls s3://shop-trail-123456789012 --recursive | wc -l
0
```

**Multi-region** matters because a credential in the wrong hands is used in a region nobody watches; a
trail for São Paulo alone records nothing of the instances started in another region. **Log file
validation** makes CloudTrail write a signed digest file every hour, with the hash of each log file it
delivered, so that `validate-logs` can prove later that no file was changed or removed: evidence that
cannot be checked is an opinion.

The last two lines are moto being confident: the status reports a delivery a second ago, and the bucket
holds nothing. On AWS the trail also needs a **bucket policy** letting `cloudtrail.amazonaws.com` write
to it, which the console adds and the command line does not; without it, `create-trail` is refused.
moto checks no bucket policy at all.

## Management and data events

**Management events** are changes and reads of resources: creating a bucket, changing a security group,
scheduling a key's deletion. **Data events** are operations inside a resource: reading an object in S3,
invoking a Lambda function. There are far more of them, they are not recorded unless a trail selects
them, and they are priced. The usual choice is to select them only where the question *who read this?*
matters, here the bucket of order files:

```
ana@laptop:~/aws/trail$ aws cloudtrail put-event-selectors --trail-name shop --advanced-event-selectors '[{"Name":"management","FieldSelectors":[{"Field":"eventCategory","Equals":["Management"]}]},{"Name":"orders objects","FieldSelectors":[{"Field":"eventCategory","Equals":["Data"]},{"Field":"resources.type","Equals":["AWS::S3::Object"]},{"Field":"resources.ARN","StartsWith":["arn:aws:s3:::shop-orders/"]}]}]' --query 'AdvancedEventSelectors[].Name' --output text
management	orders objects
```

The first selector keeps the management events; the second adds object-level events for one bucket,
and only that bucket.
