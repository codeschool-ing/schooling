---
title: What Config costs, and the account that surprised its owner
version: 1
---

```
ana@laptop:~/aws$ python3 price.py AWSConfig ConfigurationItemRecorded
AWSConfig, sa-east-1, published 2026-09-11
  SAE1-ConfigurationItemRecorded           0.003000 USD per SAE1-ConfigurationItemRecorded $0.003 per  Configuration Item recorded in South America (Sao Paulo) region
  SAE1-ConfigurationItemRecordedDaily      0.012000 USD per ConfigurationItemRecordedDaily $0.012 per ConfigurationItemRecordedDaily
ana@laptop:~/aws$ python3 price.py AWSConfig SAE1-ConfigRuleEvaluations
AWSConfig, sa-east-1, published 2026-09-11
  SAE1-ConfigRuleEvaluations               0.000500 USD per ConfigRuleEvaluations $0.0005 for 500,001 evaluations and more in South America (Sao Paulo) region
  SAE1-ConfigRuleEvaluations               0.000800 USD per ConfigRuleEvaluations $0.0008 for the next 400,000 evaluations in South America (Sao Paulo) region
  SAE1-ConfigRuleEvaluations               0.001000 USD per ConfigRuleEvaluations $0.001 for the first 100,000 evaluations in South America (Sao Paulo) region
```

Config charges for **configuration items recorded**, 0.003 USD each with continuous recording, and for
rule evaluations, 0.001 USD each for the first 100,000 a month and less after; conformance pack
evaluations have the same tiers. **Daily recording**, the second line, records at most one item per
resource per day at 0.012 USD.

For a quiet account the bill is small: two hundred resources changing a few times a month make some
thousand items, 3 USD, and ten rules evaluating them, a few dollars more. The surprise comes from
**resources that change all day**:

| resource churn | items a month | continuous, USD | daily, USD |
|---|---|---|---|
| 200 resources, a few changes each | 1,000 | 3.00 | up to 12.00 |
| an auto scaling group replacing 300 instances a day, each with a volume and a network interface | about 54,000 | 162.00 | depends on resources alive each day |

Each instance launched and terminated is items for the instance, its volume and its network interface,
at each change. **Recording every type continuously, in an account that scales, turns Config into one of its larger
lines.** The fixes are a recording group that leaves out the types nobody asks
about, or daily recording for the types that change many times a day, where one item a day at four
times the price is less than dozens at the normal one.
