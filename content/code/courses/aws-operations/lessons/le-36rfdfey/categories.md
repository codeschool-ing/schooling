---
title: Cost Categories, and dividing what nobody can own
version: 1
---

Tags group resources. **Cost Categories** group costs: a set of rules, evaluated in order, that put
every line of the bill into a named value, by tag, by account, by service, by usage type, or by another
category. The first rule that matches decides; a line no rule matches gets the **default value**. The
category then appears in Cost Explorer and in the CUR as if it were one more column.

The shop's, `team.json`:

```json
{
  "Name": "team",
  "RuleVersion": "CostCategoryExpression.v1",
  "Rules": [
    { "Value": "checkout", "Rule": { "Tags": { "Key": "owner", "Values": ["checkout"] } } },
    { "Value": "api", "Rule": { "Tags": { "Key": "owner", "Values": ["api"] } } },
    { "Value": "platform", "Rule": { "Tags": { "Key": "owner", "Values": ["platform"] } } },
    { "Value": "shared", "Rule": { "Dimensions": { "Key": "USAGE_TYPE", "Values": ["SAE1-DataTransfer-Out-Bytes"] } } }
  ],
  "DefaultValue": "unallocated",
  "SplitChargeRules": [
    { "Source": "shared", "Targets": ["checkout", "api", "platform"], "Method": "PROPORTIONAL" }
  ]
}
```

```
ana@laptop:~/aws/owners$ CATEGORY=$(aws ce create-cost-category-definition --cli-input-json file://team.json --query CostCategoryArn --output text); echo $CATEGORY
arn:aws:ce::123456789012:costcategory/4e42bfb5-2d89-4a85-be93-149cf74f9d80
ana@laptop:~/aws/owners$ aws ce describe-cost-category-definition --cost-category-arn $CATEGORY --query 'CostCategory.[Name,EffectiveStart,DefaultValue,SplitChargeRules[0].Method]' --output text
team	2026-10-01T00:00:00Z	unallocated	PROPORTIONAL
ana@laptop:~/aws/owners$ aws ce list-cost-category-definitions 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the ListCostCategoryDefinitions operation (reached max retries: 2): <!doctype html>
```

The category starts at the **first day of the current month**, which is AWS's behaviour too: like an
activated tag, a category is not applied to the past. moto keeps it and lists none; on AWS
`list-cost-category-definitions` and the console show it, and Cost Explorer can group by `team`.

## What the rules do to the shop's month

Read the rules against `bill.py`'s month:

- the three tag rules put **433.05** USD in `checkout`, 432.04 in `api`, 231.34 in `platform`;
- the data transfer, **180.00**, matches `shared`;
- the untagged lines, **249.19**, match nothing and fall to `unallocated`.

The split charge rule then divides `shared` among the three teams **in proportion to their own costs**,
1,096.43 USD in all: checkout gets 433.05 / 1,096.43 of the 180, 71.09; api 70.93; platform
37.98. Each team now sees a share of the data transfer that its traffic, roughly, caused.
`PROPORTIONAL` is one of three methods; `EVEN` splits equally, and `FIXED` uses percentages the team
writes down.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two stacked bars of the same month, 1,525.62 USD. Before the split: checkout 433.05, api 432.04, platform 231.34, shared 180.00, unallocated 249.19. After: checkout 504.14, api 502.97, platform 269.32, and unallocated still 249.19. The shared data transfer is divided in proportion to each team&#x27;s own costs; unallocated is not divided.\"><defs><marker id=\"spl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">before the split</text><rect x=\"130\" y=\"50\" width=\"161.8\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210.9\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkout</text><text x=\"210.9\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">433.05</text><rect x=\"291.8\" y=\"50\" width=\"161.4\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"372.5\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">api</text><text x=\"372.5\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">432.04</text><rect x=\"453.2\" y=\"50\" width=\"86.4\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"496.4\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">platform</text><text x=\"496.4\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">231.34</text><rect x=\"539.6\" y=\"50\" width=\"67.3\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"573.25\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shared</text><text x=\"573.25\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">180.00</text><rect x=\"606.9\" y=\"50\" width=\"93.1\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"653.4499999999999\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unallocated</text><text x=\"653.4499999999999\" y=\"80.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">249.19</text><text x=\"20\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">after</text><rect x=\"130\" y=\"140\" width=\"188.4\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"224.2\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checkout</text><text x=\"224.2\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">504.14</text><rect x=\"318.4\" y=\"140\" width=\"187.9\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"412.34999999999997\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">api</text><text x=\"412.34999999999997\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">502.97</text><rect x=\"506.3\" y=\"140\" width=\"100.6\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"556.6\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">platform</text><text x=\"556.6\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">269.32</text><rect x=\"606.9\" y=\"140\" width=\"93.1\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"653.4499999999999\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unallocated</text><text x=\"653.4499999999999\" y=\"170.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">249.19</text><text x=\"360\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD for the month, by the category team; the 180 shared are divided in proportion, unallocated is not</text></svg>", "caption": "The shared cost goes to the teams; the cost nobody owns stays visible under its own name."}
```

**`unallocated` is not split, and should not be.** Dividing the untagged instances among the teams would
make them disappear into everybody's numbers, and the point of the category is that 249.19 USD a month
stays visible, under a name that says what it is, until somebody owns each line or deletes it. A falling
`unallocated` line, month after month, is how a team knows the tagging is working.
