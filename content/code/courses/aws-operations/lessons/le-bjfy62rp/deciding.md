---
title: The bill, and the decision
version: 1
---

Shield Advanced's price has two parts, and the price list from lesson 1 has the second:

```
ana@laptop:~/aws$ python3 price.py AWSShield ELB
AWSShield, sa-east-1, published 2026-09-16
  SAE1-DataTransfer-Shield-Bytes           0.030000 USD per GB         Shield Data Transfer Out of ELB in GRU - Above 500 TB
  SAE1-DataTransfer-Shield-Bytes           0.040000 USD per GB         Shield Data Transfer Out of ELB in GRU - Next 400 TB
  SAE1-DataTransfer-Shield-Bytes           0.050000 USD per GB         Shield Data Transfer Out of ELB in GRU - First 100 TB
ana@laptop:~/aws$ curl -sS https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AWSShield/20260916132208/aws-other/index.json | jq -r '.terms.OnDemand[][].priceDimensions[] | select(.description | test("Subscription")) | [.pricePerUnit.USD, .unit, .description] | @tsv'
3000.0000000000	month	$3,000 for First Subscription
0.0000000000	month	$0 for additional Subscriptions
ana@laptop:~/aws$ python3 price.py awswaf SAE1-ShieldProtected-RequestV2-Tier1
awswaf, sa-east-1, published 2026-09-14
  SAE1-ShieldProtected-RequestV2-Tier1     0.000000 USD per Request    $0 per million requests processed (Shield Protected)
```

The first command is the data transfer line: on top of the usual data transfer out, **every gigabyte a
protected load balancer sends** pays 0.05 USD, for the first 100 TB in a month. The subscription itself
is not a São Paulo line, because it belongs to the organisation rather than to a region; it is in the
offer's `aws-other` file, which `price.py` does not read, so the second command reads it with `curl` and
`jq`, keeping the lines about the subscription: **3,000 USD a month for the first subscription**, and nothing for further ones, since one
subscription covers every account of an organisation that pays through one bill. The third line is the
WAF request price for a protected resource, zero in the base tier.

## The shop's numbers

The shop's load balancer sends about 2 TB a month:

| line | quantity | USD a month |
|---|---|---|
| subscription | 1 | 3,000.00 |
| Shield data transfer | 2,000 GB × 0.05 | 100.00 |
| WAF requests, now included | 50 million × 0 | 0.00 |
| **total** | | **3,100.00** |

Against lesson 15's 38 USD a month for WAF on its own, and for a year, since the commitment is a year:
**37,200 USD**, of which 456 USD is WAF that the subscription now includes.

## Who should buy it

The subscription is worth it when **an hour of downtime, or a week of scaling, costs more than the
year's subscription**, or when somebody contractually requires protection and a response team. Three
questions settle it:

1. **What does an hour down cost?** A shop selling 10,000 USD a day loses about 420 USD an hour, and 37,200
   USD buys 89 hours of that. A payments platform losing 50,000 USD an hour buys the year with less than
   one.
2. **How much does it scale under load?** A service behind auto scaling turns an attack into a bill, and
   cost protection is what refunds it.
3. **Is there a team to work with the response team?** The specialists help a team that knows its own
   traffic. A team that has never read its WAF logs will spend the attack learning them.

For the shop as it is, the answer is no: Standard, the web ACL of lesson 15 and CloudFront in front.
Written down, with the numbers, that answer is the decision, and it is revisited when the numbers move.
