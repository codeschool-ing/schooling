---
title: Managed rules, and counting before blocking
version: 1
---

Nobody in a small team writes the rules against SQL injection or cross-site scripting, and nobody
should: **managed rule groups** are written and updated by AWS, or by sellers in the AWS Marketplace,
and added to a web ACL as a single rule. The ones that cost nothing beyond their rule and their
capacity are the baseline:

| group | what it is for | WCU |
|---|---|---|
| `AWSManagedRulesCommonRuleSet` | the common attacks on web applications, and oversized requests | 700 |
| `AWSManagedRulesKnownBadInputsRuleSet` | request patterns known to exploit specific vulnerabilities | 200 |
| `AWSManagedRulesSQLiRuleSet` | SQL injection, for an application with a database behind it | 200 |
| `AWSManagedRulesAmazonIpReputationList` | addresses Amazon's own threat intelligence has seen misbehave | 25 |

Bot Control, account takeover prevention and account creation fraud prevention are also managed groups,
and those are **priced on top**, per month and per request; the section on cost has the numbers. The
lab cannot list any of them, because moto does not have the call that does
(`list-available-managed-rule-groups`), so the table is from AWS's documentation.

Two things about a group are the team's decision rather than AWS's. **Its version**: by default a
group follows AWS's updates, which is the point, and a web ACL can pin a version and move it by hand
for an application where a changed rule has broken something before. And **its actions**: any rule in
the group can be overridden, as the shop overrode `SizeRestrictions_BODY`, and that is the answer to a
false positive, rather than removing the whole group.

## Count first

**A new rule in front of a live site starts in `Count`.** Blocking at once tests the rule on customers;
counting tests it on the logs. A week of counting answers the one question that matters, *what would
this have blocked?*, and only then does the action become `Block`.

Changing a web ACL is a read, a change and a write, and the write needs the **lock token** from the
read. Two people editing the same web ACL is how a change gets lost, and the token is what refuses the
second write:

```
ana@laptop:~/aws/waf$ TOKEN=$(aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query LockToken --output text)
ana@laptop:~/aws/waf$ jq '.Rules[1].Action = {"Count": {}} | del(.Name, .Scope)' shop-acl.json > login-count.json
ana@laptop:~/aws/waf$ aws wafv2 update-web-acl --name shop --scope REGIONAL --id $ID --lock-token $TOKEN --cli-input-json file://login-count.json --cli-binary-format raw-in-base64-out
{
    "NextLockToken": "77db2054-5faf-48a2-b2a3-cc6bc33ca4dd"
}
ana@laptop:~/aws/waf$ aws wafv2 update-web-acl --name shop --scope REGIONAL --id $ID --lock-token $TOKEN --cli-input-json file://login-count.json --cli-binary-format raw-in-base64-out

aws: [ERROR]: An error occurred (WAFOptimisticLockException) when calling the UpdateWebACL operation: AWS WAF couldn’t save your changes because someone changed the resource after you started to edit it. Reapply your changes.
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query 'WebACL.Rules[1].Action'
{
    "Count": {}
}
```

The first update succeeds and answers with the next token. The second, with the old token, is refused:
somebody, here the same person a second earlier, changed the web ACL after the read. On AWS that is the
same refusal, and the answer is to read again and reapply. `login-rate` now counts.

## Where the counting is read

Every match is in two places on AWS. **The metrics**, `AWS/WAFV2` with `CountedRequests`,
`BlockedRequests` and `AllowedRequests` per rule, say how many. **The logs** say which requests: one
JSON record per request, with the rule that decided it, the rules that counted it, and the request's
address, path and headers. WAF sends its logs to a CloudWatch Logs group, an S3 bucket or a Firehose
stream, and the destination's name must start with `aws-waf-logs-`. **moto does not check that**:

```
ana@laptop:~/aws/waf$ aws logs create-log-group --log-group-name shop-waf
ana@laptop:~/aws/waf$ aws wafv2 put-logging-configuration --logging-configuration ResourceArn=$ACL,LogDestinationConfigs=arn:aws:logs:sa-east-1:123456789012:log-group:shop-waf --query LoggingConfiguration.LogDestinationConfigs
[
    "arn:aws:logs:sa-east-1:123456789012:log-group:shop-waf"
]
```

AWS refuses `shop-waf` and accepts `aws-waf-logs-shop`. And since moto inspects no request, the group
stays empty either way. What one record looks like is in AWS's documentation; abridged, and not
produced by this lab, a request counted by `login-rate` and let through reads:

```json
{
  "timestamp": 1791979200000,
  "action": "ALLOW",
  "terminatingRuleId": "Default_Action",
  "nonTerminatingMatchingRules": [{ "ruleId": "login-rate", "action": "COUNT" }],
  "httpRequest": { "clientIp": "198.51.100.23", "httpMethod": "POST", "uri": "/login" }
}
```

`terminatingRuleId` is what decided it, and here that was the default action. The rule being tried is
in `nonTerminatingMatchingRules`. A Logs Insights query over a week of these, counting the addresses
`login-rate` would have blocked, is lesson 9's tool on WAF's data, and the list it prints is what the
team reads before switching `Count` to `Block`: a list of strangers is a rule ready to block, and a list
with the office's address in it is a limit set too low.
