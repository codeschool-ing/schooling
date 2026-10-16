---
title: What to act on first
version: 1
---

Sorting findings by severity alone puts a critical CVE in a build tool nobody can reach above a high
finding that says somebody is using the shop's credentials right now. Severity is how bad a thing would
be; the order to act in also asks **whether it is happening**, and **whether the way in is open**. Three
questions, in this order:

1. **Is somebody inside now?** A threat finding, of high severity, from GuardDuty: credentials used from
   elsewhere, an instance talking to a mining pool. Every hour it waits is an hour somebody else has.
2. **Is there a known, published way in?** A critical or high vulnerability with an exploit available,
   in something that runs. Attackers use published exploits within days of publication.
3. **Is it high or critical?** Everything else of that severity, in the working day.

The rest is the backlog, read weekly. `triage.py` writes the order down:

```python
# triage.py: the findings in the order to act on them
import boto3

SEVERITY = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFORMATIONAL": 4}


def tier(f):
    kind = f["Types"][0]
    sev = f["Severity"]["Label"]
    if kind.startswith(("TTPs", "Effects", "Unusual Behaviors")) and sev in ("CRITICAL", "HIGH"):
        return 1  # somebody may be inside now
    exploit = any(v.get("ExploitAvailable") == "YES" for v in f.get("Vulnerabilities", []))
    if exploit and sev in ("CRITICAL", "HIGH"):
        return 2  # a known way in, published
    return 3 if sev in ("CRITICAL", "HIGH") else 4


hub = boto3.client("securityhub")
filters = {"RecordState": [{"Value": "ACTIVE", "Comparison": "EQUALS"}]}
found = hub.get_findings(Filters=filters, MaxResults=100)["Findings"]
for f in sorted(found, key=lambda f: (tier(f), SEVERITY[f["Severity"]["Label"]])):
    print(tier(f), f'{f["Severity"]["Label"]:<8}', f["Title"], "|", f["Resources"][0]["Id"])
```

```
ana@laptop:~/aws/findings$ python3 triage.py
1 HIGH     Instance credentials used from outside AWS | shop-api-task
2 CRITICAL CVE in a library of the api image | shop/api:9f1c2ab34de5
3 CRITICAL CVE in a build tool of the worker image | shop/worker:77ad01
3 HIGH     S3 bucket allows public read | shop-exports
4 MEDIUM   CloudTrail log file validation is off | shop-trail
4 LOW      Port 22 probed on an instance | i-0lab1
```

The credentials finding is first although it is only high: it is the one that is happening. The CVE
with an exploit is second; the other critical CVE, in a build tool of an image whose exploit nobody has
published, is third, beside the public bucket.

**The program cannot know what a person can.** `shop-exports` is in the third tier because nothing in the
finding says what the bucket holds. If it holds customers' exports, it is a data leak in progress and it
goes to the top; if it holds the public product catalogue, it is expected and the finding is suppressed
with that reason. A triage order is a starting point for the person reading it, not a replacement.

## Deadlines by tier

A team writes down how long each tier may wait, and reports against it. A common shape:

| tier | acted on within | how it reaches people |
|---|---|---|
| 1, somebody may be inside | the hour, day or night | a page, lesson 14's `shop-page` |
| 2, a published way in | two days | a ticket, worked first |
| 3, high or critical | two weeks | a ticket |
| 4, the rest | the weekly review | the queue |

## Routing the first tier to a page

GuardDuty sends every finding to EventBridge as an event, and a rule with a pattern picks the ones that
page. `guardduty-high.json`:

```json
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": { "severity": [{ "numeric": [">=", 7] }] }
}
```

```
ana@laptop:~/aws/findings$ aws events put-rule --name guardduty-high --event-pattern file://guardduty-high.json --query RuleArn --output text
arn:aws:events:sa-east-1:123456789012:rule/guardduty-high
ana@laptop:~/aws/findings$ aws sns create-topic --name shop-page --query TopicArn --output text
arn:aws:sns:sa-east-1:123456789012:shop-page
ana@laptop:~/aws/findings$ aws events put-targets --rule guardduty-high --targets Id=page,Arn=arn:aws:sns:sa-east-1:123456789012:shop-page --query FailedEntryCount
0
```

The rule matches GuardDuty findings of severity 7 and above and sends them to the page topic. In the lab
nothing will ever match, since moto's GuardDuty raises no findings; on AWS, `create-sample-findings`
followed by a look at the phone is the test. A finding at severity 7 is not always tier 1, so the page's
first job, for the person who receives it, is the triage above.
