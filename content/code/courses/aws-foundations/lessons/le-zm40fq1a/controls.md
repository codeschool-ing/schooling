---
title: Controls, and what the landing zone costs to run
version: 1
---

**A control is a rule Control Tower applies to every account in an OU, and there are three kinds,
told apart by when they act.** The wrong picture is that a control blocks something. Only one kind
does. The other two find a problem, one after the fact and one before anything is built. A
landing zone needs all three, because each misses what the others catch.

## Three kinds

| kind | when it acts | built from | what the shop sees |
|---|---|---|---|
| **preventive** | before the request is carried out | SCPs, lesson 4 | the request refused |
| **detective** | after the resource exists | AWS Config rules | the resource reported as not compliant |
| **proactive** | before a CloudFormation stack creates it | CloudFormation hooks | the stack refused before it builds |

**A preventive control is lesson 4's guardrail, written and attached by Control Tower.** It refuses
the call, so the bad state never exists. Its limit is that an SCP can only see a request, not the
state of the account: it cannot say "every bucket must be encrypted", only "this call may not be
made". Control Tower's region deny, which refuses every region the landing zone does not govern, is
lesson 4's `sa-east-1-only` as a setting.

**A detective control is a Config rule.** Config records each resource of an account and how it
changes, and a rule judges each record: a bucket readable by the public, a root user without MFA. It
**undoes nothing**. It turns the resource "non-compliant" on a dashboard in the Audit account, and
somebody acts. That is weaker than a refusal and it is the only kind that can see a resource made
before the control existed.

**A proactive control checks a template before it runs.** When a stack is created with
CloudFormation, a hook reads the resources it is about to make and refuses the stack if one breaks
the rule. It only sees what goes through CloudFormation, and the `iac` course is where that matters.

## Mandatory, strongly recommended, elective

Every control also carries AWS's **guidance**, which says how much choice there is:

- **mandatory** controls are on in every landing zone and cannot be switched off. They protect the
  landing zone itself: the trail, the log bucket, the roles and the Config setup Control Tower made.
- **strongly recommended** controls are AWS's advice for any company: detecting a root user with no
  second factor is the kind of rule in this group.
- **elective** controls are for particular needs, such as a regulated workload, and are switched on
  OU by OU when a company has the reason.

The shop starts with the mandatory ones, which arrive by themselves, and turns on the strongly
recommended ones for `Workloads` and `Sandbox` alike.

## What the landing zone costs to run

**Control Tower is free, and the services it switches on are not.** Two of them run in every
account and region the landing zone governs, so they are the ones to price. Config first:

```
ana@laptop:~/aws$ python3 price.py AWSConfig 20260911124534 sa-east-1 SAE1-ConfigurationItemRecorded SAE1-ConfigRuleEvaluations
AWSConfig 20260911124534, published 2026-09-11, USD
SAE1-ConfigurationItemRecorded
          0 to       Inf SAE1-ConfigurationItemRecorded 0.0030
SAE1-ConfigRuleEvaluations
          0 to   100,000 ConfigRuleEvaluations 0.0010
    100,000 to   500,000 ConfigRuleEvaluations 0.0008
    500,000 to       Inf ConfigRuleEvaluations 0.0005
```

A **configuration item** is one record of one resource at one moment, written each time a recorded
resource changes, at 0.003 dollars each. A **rule evaluation** is one Config rule judging one
resource, at 0.001 for the first 100,000 of the month. The counts depend entirely on how much
changes. As an illustration, not a measurement: an account whose machines are replaced often
enough to record 20,000 configuration items in a month pays 60 dollars for recording. If ten
detective controls evaluate them 200,000 times, that is 100.00 for the first 100,000 plus 80.00 for
the next, 180 dollars. **The busiest account pays most**, and that is usually production.

CloudTrail next:

```
ana@laptop:~/aws$ python3 price.py AWSCloudTrail 20260911124531 sa-east-1 SAE1-FreeEventsRecorded SAE1-PaidEventsRecorded SAE1-DataEventsRecorded
AWSCloudTrail 20260911124531, published 2026-09-11, USD
SAE1-FreeEventsRecorded
          0 to       Inf Events 0.0000
SAE1-PaidEventsRecorded
          0 to       Inf Events 0.0000
SAE1-DataEventsRecorded
          0 to       Inf Events 0.0000
ana@laptop:~/aws$ jq -r '.terms.OnDemand[][].priceDimensions[].description | select(test("paid event|data event recorded"))' ~/.cache/aws-prices/AWSCloudTrail-20260911124531-sa-east-1.json
0.000001 per data event recorded in South America(Sao Paulo) region
0.00002 per paid event recorded in South America(Sao Paulo) region
```

`price.py` prints four decimals and an event costs less than that, so its last two lines read
`0.0000`. The offer file it saved carries the exact prices, and `jq` reads them out. **The first
copy of an account's management events costs nothing**, and the organisation trail is that copy. A
second trail recording the same events, one a team adds in its own account, pays 0.00002 dollars
per event, 2 dollars per 100,000. Data events, such as every read of an object in a bucket, are
0.000001 each and are off unless somebody turns them on. What the records then cost to keep is S3
storage in `log-archive`, which this lesson did not price.

**These prices are from the lists AWS published on 11 September 2026**, read by lesson 1's program.
Nothing here was billed, since moto has no bill: the counts are illustrations and the arithmetic is
the paragraph's.
