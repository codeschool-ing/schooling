---
title: Drift, and comparing what is with what was meant
version: 1
---

A stack knows what it created and with which properties. It does not know what happened afterwards.
Somebody lowers the log retention in the console at two in the morning, to stop a cost, and goes to
bed. **The template still says 14 days, the stack still says 14 days, and the log group keeps one.**
That difference is drift, and the next update of the stack may silently put 14 back, or fail,
depending on the property.

The lab plays the person in the console with one command:

```
ana@laptop:~/aws/cfn$ aws logs put-retention-policy --log-group-name /shop/web --retention-in-days 1
```

## Detection, which moto does not do

CloudFormation compares each resource with what the stack expects, on request:

```
ana@laptop:~/aws/cfn$ aws cloudformation detect-stack-drift --stack-name shop-base 2>&1 | grep -m1 ERROR
aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
```

moto fails with an internal error. On AWS, `detect-stack-drift` starts a comparison and returns an
id; `describe-stack-resource-drifts` then lists each resource as **`IN_SYNC`**, `MODIFIED`,
`DELETED` or `NOT_CHECKED`, and for a modified one, each property with its expected and actual
value. For this stack it would show `WebLogs` as `MODIFIED`, with `RetentionInDays` expected 14 and
actually 1. Not every resource type supports drift detection, and a property the template does not
set is not compared at all, which is what `NOT_CHECKED` and silence mean.

## The same comparison, by hand

The idea needs no service: read what was meant, read what is, compare.

```
ana@laptop:~/aws/cfn$ aws cloudformation describe-stacks --stack-name shop-base --query 'Stacks[0].Parameters[?ParameterKey==`Retention`].ParameterValue' --output text
14
ana@laptop:~/aws/cfn$ aws logs describe-log-groups --log-group-name-prefix /shop/web --query 'logGroups[0].retentionInDays'
1
```

Fourteen meant, one actual. That two-line comparison is what drift detection does for every property
of every resource, and doing it by hand for the one property that matters is how to check a fix
before a service is available to check it.

## What to do about drift

There are only two honest answers, and both end with the template and the resource agreeing:

- **the change was wrong**: update the stack with the template as it is, and the property returns to
  what was meant;
- **the change was right**: put it in the template, review it like any change, and update the stack,
  so the next update does not undo it.

The third answer, leaving it, is the one that costs most: the drift sits there until the next
unrelated update reverses an emergency fix at the worst moment. AWS Config, lesson 21, can watch for
drift continuously; the habit underneath is this one: **the file is the truth, and anything else is a
change that has not been written down yet**.
