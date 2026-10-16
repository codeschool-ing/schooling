---
title: Answering who spent what
version: 1
---

**"Who spent what" is two questions, and a report answers the first much more easily than the
second.** Which account spent it is a column, filled on every line. Which team spent it is a tag,
filled only where somebody tagged the resource and billing activated the key. The lines where that
did not happen are not an error to clean away. They are a part of the answer, **the untagged
remainder**, and a report that hides it gives every team a number that adds up to less than the
bill.

## Each team, counted two ways

Two questions, each in a file of its own, because a question that runs to a dozen lines reads
better in a file than on a command line. Write both in `~/aws`:

```sh
cat > team.sql <<'EOF'
-- Each team's month, unblended and amortised, before tax and credits.
SELECT coalesce(json_extract(resource_tags, '$.user_team'), '(no team)') AS team,
       sum(line_item_unblended_cost) AS unblended,
       sum(CASE line_item_line_item_type
             WHEN 'SavingsPlanCoveredUsage' THEN savings_plan_savings_plan_effective_cost
             WHEN 'SavingsPlanNegation' THEN 0
             WHEN 'SavingsPlanRecurringFee' THEN 0
             ELSE line_item_unblended_cost
           END) AS amortised
FROM cur
WHERE line_item_line_item_type NOT IN ('Tax', 'Credit')
GROUP BY team
ORDER BY amortised DESC;
EOF
cat > remainder.sql <<'EOF'
-- What no team's tag claims, by account and usage type.
SELECT line_item_usage_account_id AS account,
       line_item_usage_type AS usage_type,
       sum(line_item_unblended_cost) AS unblended
FROM cur
WHERE json_extract(resource_tags, '$.user_team') IS NULL
  AND line_item_line_item_type NOT IN ('Tax', 'Credit', 'SavingsPlanRecurringFee')
GROUP BY account, usage_type
ORDER BY unblended DESC;
EOF
```


The first is each team's month, before tax and credits, counted twice. **Unblended** adds the lines
as they were charged. **Amortised** replaces the three lines of the Savings Plan with what the
covered hour cost at the plan's rate, `savings_plan_savings_plan_effective_cost`, so the plan's
cost lands on the line that used it:

```
ana@laptop:~/aws$ python3 ask.py team.sql
team       unblended  amortised
web           376.55     456.23
data          165.90     165.90
(no team)     210.82     131.14
```

**The two columns disagree by exactly 79.68, the plan's fee for the month**, and the disagreement is
the lesson. Unblended, the web team's instance under the plan looks free. Its covered usage and its
negation cancel, and the 79.68 sits on the fee line, which carries no tag, so it falls into
`(no team)`. Amortised, the 79.68 moves onto the web team, where the hours were used, and the
remainder shrinks by the same amount. The data team bought nothing in advance and is the same in
both. This month the plan covered its instance in every hour. In a month with idle hours, the unused
part of the fee would be a cost of its own, which `team.sql` would have to keep rather than set to
zero. **For "who spent what", amortised is the honest column.** It charges a commitment to the usage
it covered rather than to whoever happened to buy it. Unblended stays the right column for "what did
we pay this month", which is a question for finance rather than for teams.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-amortise\" aria-label=\"Each team's month in the made-up report, in dollars, before tax and credits, counted two ways. Web: 376.55 unblended, 456.23 amortised. Data: 165.90 both ways. No team: 210.82 unblended, 131.14 amortised. The difference, 79.68 dollars, is the Savings Plan's fee, which unblended leaves untagged and amortised moves onto the web team that used it.\"><path d=\"M80.0 250.0 L690.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"72.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><text x=\"72.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><text x=\"72.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><text x=\"72.0\" y=\"90.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><text x=\"80.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dollars, before tax and credits</text><rect x=\"130.0\" y=\"99.4\" width=\"52.0\" height=\"150.6\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"90.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">376.55</text><rect x=\"192.0\" y=\"67.5\" width=\"52.0\" height=\"182.5\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"218.0\" y=\"58.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">456.23</text><text x=\"187.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">web</text><rect x=\"320.0\" y=\"183.6\" width=\"52.0\" height=\"66.4\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"174.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">165.90</text><rect x=\"382.0\" y=\"183.6\" width=\"52.0\" height=\"66.4\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"408.0\" y=\"174.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">165.90</text><text x=\"377.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data</text><rect x=\"510.0\" y=\"165.7\" width=\"52.0\" height=\"84.3\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"536.0\" y=\"156.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">210.82</text><rect x=\"572.0\" y=\"197.5\" width=\"52.0\" height=\"52.5\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">131.14</text><text x=\"567.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">(no team)</text><rect x=\"520.0\" y=\"30.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"538.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">unblended</text><rect x=\"520.0\" y=\"50.0\" width=\"12.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"538.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">amortised</text><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">made-up data, from cur.csv; the 79.68 that moves is the Savings Plan fee</text></svg>", "caption": "Amortised moves the plan's fee from nobody onto the team whose hours it covered."}
```

## The remainder, line by line

```
ana@laptop:~/aws$ python3 ask.py remainder.sql
account       usage_type                    unblended
444455556666  SAE1-NatGateway-Hours             67.89
777788889999  SAE1-BoxUsage:m7i.large           24.10
444455556666  SAE1-NatGateway-Bytes             18.60
111122223333  SAE1-PublicIPv4:InUseAddress       7.30
444455556666  SAE1-PublicIPv4:IdleAddress        7.30
777788889999  USE1-APIRequest                    3.00
777788889999  SAE1-PublicIPv4:InUseAddress       1.75
111122223333  USE1-APIRequest                    1.20
```

**131.14 dollars that no team's tag claims, and every line of it has an account and a usage type
that say what it is.** The largest lines are lesson 14's staging NAT gateway, its hours and its
bytes, and an untagged sandbox instance. None of it is mysterious. It is unowned. The last query
puts the remainder beside each account's usage:

```
ana@laptop:~/aws$ python3 ask.py "SELECT line_item_usage_account_id AS account, sum(line_item_unblended_cost) AS usage, sum(CASE WHEN json_extract(resource_tags, '$.user_team') IS NULL THEN line_item_unblended_cost ELSE 0 END) AS untagged FROM cur WHERE line_item_line_item_type = 'Usage' GROUP BY account"
account        usage  untagged
111122223333  382.55      8.50
444455556666  227.06     93.79
777788889999   63.98     28.85
```

Production's usage is almost all claimed, 8.50 untagged of 382.55. Staging's is 93.79 of 227.06,
**41%**. That number tells the shop where to start tagging, and where lesson 13's tag policies and
an SCP requiring `team` would have earned their keep.

## Showback, chargeback, and the AWS way of running these

What a shop does with the answer has two names. **Showback** sends each team its number, every
month, and no money moves: the point is that the people who start machines see what the machines
cost. **Chargeback** goes further and moves the cost into each team's own budget, an internal
invoice. That makes the number matter, and makes every rule behind it a matter for argument. Either
way the rules have to be written before the first report goes out:

- **the untagged remainder** belongs to somebody, by a rule: the account's owner, or split among
  the teams in proportion to what they did claim;
- **commitments** are charged amortised, to the usage they covered, so that the team that bought
  the plan for everybody is not the team that looks expensive;
- **shared lines**, tax, support and credits, are split by a rule too, usually in proportion to
  each team's usage, because no tag will ever claim them.

At the size of a real organisation, the report is millions of rows of Parquet in a bucket. The AWS
way to query it is **Amazon Athena**, which runs SQL directly over files in S3, with **Amazon
QuickSight** drawing the dashboards a team actually opens. Neither was run for this course, because
both need the real report to read. The SQL above would change little: Athena reads the
`resource_tags` map with its own syntax instead of `json_extract`, and the `GROUP BY` stays.
Grouping accounts and tags into business units by rule, without rewriting every query, is what
**Cost Categories** do, and `aws-operations` lesson 24 builds them.
