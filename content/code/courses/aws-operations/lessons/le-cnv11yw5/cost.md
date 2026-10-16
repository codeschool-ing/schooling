---
title: What a web ACL costs
version: 1
---

WAF is priced by three things: the web ACLs, the rules in them, and the requests they inspect. The
price list from lesson 1 has each of them, for São Paulo:

```
ana@laptop:~/aws$ python3 price.py awswaf SAE1-WebACLV2
awswaf, sa-east-1, published 2026-09-14
  SAE1-WebACLV2                            5.000000 USD per Month      $5.00 per web ACL created (prorated hourly)
ana@laptop:~/aws$ python3 price.py awswaf SAE1-RuleV2
awswaf, sa-east-1, published 2026-09-14
  SAE1-RuleV2                              1.000000 USD per Month      $1.00 per rule created (prorated hourly)
ana@laptop:~/aws$ python3 price.py awswaf SAE1-RequestV2-Tier
awswaf, sa-east-1, published 2026-09-14
  SAE1-RequestV2-Tier0                     0.000001 USD per Request    $0.60 per million Request for Request Processed Tier0 in South America (Sao Paulo)
  SAE1-RequestV2-Tier1                     0.000001 USD per Request    $0.60 per million requests processed
  SAE1-RequestV2-Tier2-2000WCU             0.000001 USD per Request    $0.80 per million requests processed
  SAE1-RequestV2-Tier3-2500WCU             0.000001 USD per Request    $1.00 per million requests processed
  SAE1-RequestV2-Tier4-3000WCU             0.000001 USD per Request    $1.20 per million requests processed
  SAE1-RequestV2-Tier5-3500WCU             0.000001 USD per Request    $1.40 per million requests processed
  SAE1-RequestV2-Tier6-4000WCU             0.000002 USD per Request    $1.60 per million requests processed
  SAE1-RequestV2-Tier7-4500WCU             0.000002 USD per Request    $1.80 per million requests processed
  SAE1-RequestV2-Tier8-5000WCU             0.000002 USD per Request    $2.00 per million requests processed
```

Read the sentence on the right rather than the number, since the program prints six decimals and a
price of 60 cents per million requests is 0.0000006 a request. **A web ACL is 5 USD a month, each rule
is 1 USD a month**, both prorated by the hour, and a managed rule group counts as one rule however many
rules it holds. **Requests are 0.60 USD per million** while the web ACL stays within 1,500 WCU, the two lines
`Tier0` and `Tier1` at the same price, and each 500 WCU beyond that adds 0.20 USD per million, up to
2.00 at the limit of 5,000.

The shop's web ACL, at 50 million requests a month:

| line | quantity | USD a month |
|---|---|---|
| web ACL | 1 × 5.00 | 5.00 |
| rules | 3 × 1.00 | 3.00 |
| requests, ≤ 1,500 WCU | 50 million × 0.60 | 30.00 |
| **total** | | **38.00** |

**The requests are most of it**, and they scale with traffic rather than with the rules. Three
decisions move the total, and each is visible in the price list before it is made:

- **capacity past 1,500 WCU** changes the price of every request: the same 50 million at the 2,000 WCU
  tier is 0.80 × 50 = 40 USD instead of 30, so adding a 200-unit group to a web ACL at 1,400 costs 10 USD
  a month in requests on top of its 1 USD as a rule;
- **the paid managed groups** charge on top: Bot Control's common level is 10 USD a month, and its
  per-request line says 1 USD per million beyond the requests it includes;
- **CAPTCHA** is 0.40 USD per thousand attempts, a thousand times the price of an ordinary request, so a
  CAPTCHA action on a busy path is a line to watch on the bill.

`SAE1-` is the prefix the bill uses for São Paulo, as in lesson 1, and these lines appear on it under
the usage types above. Lesson 24 reads a bill by them, and lesson 25 alarms on one that moves.
