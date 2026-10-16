---
title: Conformance packs, compliance as a file
version: 1
---

Twenty rules created one by one are twenty commands nobody will repeat the same way in the next account.
A **conformance pack** is the set as one file, a template in the shape of CloudFormation's, deployed as a
unit and reported as a unit: a pack is compliant when all its rules are. AWS publishes sample packs for
common frameworks, and a team's own is usually a short list of the rules it actually means.

`shop-pack.yaml`:

```yaml
# shop-pack.yaml: the rules the shop means, deployed as one
Resources:
  S3PublicRead:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: s3-public-read
      Source:
        Owner: AWS
        SourceIdentifier: S3_BUCKET_PUBLIC_READ_PROHIBITED
      Scope:
        ComplianceResourceTypes:
          - AWS::S3::Bucket
  RequiredOwner:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: required-owner
      InputParameters:
        tag1Key: owner
      Source:
        Owner: AWS
        SourceIdentifier: REQUIRED_TAGS
  TrailEnabled:
    Type: AWS::Config::ConfigRule
    Properties:
      ConfigRuleName: cloudtrail-enabled
      MaximumExecutionFrequency: TwentyFour_Hours
      Source:
        Owner: AWS
        SourceIdentifier: CLOUD_TRAIL_ENABLED
```

The third rule is periodic: whether a trail is on is a fact about the account, checked once a day.
Lesson 20's point, that a trail which can be stopped silently is not an audit log, becomes a rule that
says so.

```
ana@laptop:~/aws/config$ aws configservice put-conformance-pack --conformance-pack-name shop-baseline --template-body file://shop-pack.yaml 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the PutConformancePack operation (reached max retries: 2): <!doctype html>
```

moto has no conformance packs for a single account. On AWS the same command deploys the pack, and
`describe-conformance-pack-compliance` reports each rule; with AWS Organizations, an
**organisation conformance pack** deploys the same file to every account, which is how one team keeps
fifty accounts to one standard.

## Remediation, with care

A rule can carry a **remediation**: a Systems Manager Automation document that fixes a non-compliant
resource, run by hand or automatically. Turning on the public access block of a bucket that should never
be public is a good candidate for automatic remediation. Adding a missing tag is not: the remediation
would have to invent the owner. **Automate the fixes whose right answer does not depend on the
resource**, and leave the rest to a ticket, lesson 14's second topic.
