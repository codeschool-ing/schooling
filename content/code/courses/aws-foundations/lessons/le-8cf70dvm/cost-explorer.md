---
title: Cost Explorer, a question asked of the bill
version: 1
---

**Cost Explorer is a query over the bill: a period, a granularity, what to measure and how to
split it.** The console draws it as a chart, which makes it look like a live meter of spending. It
is not live. AWS's documentation says its data is refreshed at least once every 24 hours, and that
the first time Cost Explorer is enabled on an account, preparing the current month and the twelve
before it can take up to a day. It answers "what did we spend, and on what", reliably and late.

## The shape of a query, against an empty bill

The same questions the console asks are one command, `aws ce get-cost-and-usage`. moto answers it,
and the answer is the first thing to understand about this section:

```
ana@laptop:~/aws$ aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity MONTHLY --metrics UnblendedCost AmortizedCost NetUnblendedCost --group-by Type=TAG,Key=team
{
    "ResultsByTime": [],
    "DimensionValueAttributes": []
}
ana@laptop:~/aws$ aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity DAILY --metrics UnblendedCost --group-by Type=DIMENSION,Key=SERVICE Type=DIMENSION,Key=LINKED_ACCOUNT
{
    "ResultsByTime": [],
    "DimensionValueAttributes": []
}
```

**Both answers are empty, because moto has no spending to report.** It records resources and never
bills them, so there is no September for it to add up. No number in this section came from moto,
and none was put into it to make the output look fuller. What the commands do show is the shape
of the question, which is the same against AWS:

- **`--time-period`** is a start and an end, and the end is **exclusive**: `End=2026-10-01` is the
  whole of September and nothing of October. Writing `End=2026-09-30` loses the last day of the
  month, without an error.
- **`--granularity`** is `MONTHLY`, `DAILY` or `HOURLY`; hourly data has to be turned on in the
  account first, and is a separate charge.
- **`--metrics`** names what to add up; the three above are the ones a reader of a bill confuses,
  and the next part says how they differ.
- **`--group-by`** splits the total, by a **dimension** such as `SERVICE`, `LINKED_ACCOUNT` or
  `REGION`, or by a **tag** that billing has activated. The second command groups by two
  dimensions at once, which is the most a query may ask for.

Grouping by the tag `team`, AWS answers with keys such as `team$web` and `team$data`, and with one
key that is just `team$`: **the costs of everything that had no `team` tag**, which is the untagged
remainder the section on tags warned about.

## Three ways of counting the same month

The metrics differ in **when** a cost is counted and **whether** a discount is taken off it. The
difference only shows when something was paid for ahead of time, and lesson 14 is about exactly those purchases; the table gives the shape:

| metric | what it counts |
|---|---|
| `UnblendedCost` | each charge on the day it was charged, at the rate charged: an upfront payment for a year lands whole on the day it was paid |
| `AmortizedCost` | upfront payments spread over the hours they pay for, so the same year shows as a twelfth in each month |
| `NetUnblendedCost` | unblended, after any discount the account has been given is subtracted; with no discount, the same as unblended |

**Unblended answers "what was charged this month"; amortised answers "what did this month's usage
cost".** A team that bought a year of capacity in January looks enormously expensive in January and
free for eleven months when read unblended, and steady when read amortised. A budget counts
unblended unless it was told otherwise, which the `UseAmortized: false` in the section on budgets
said. `BlendedCost` is a fourth, an average rate across the accounts of a consolidated bill, and it
belongs to lesson 3's subject.

## The price of asking

Cost Explorer's screens in the console are free to use. **The API is not**, and its price is in the
list:

```
ana@laptop:~/aws$ python3 price.py AWSCostExplorer 20260911124538 us-east-1 USE1-APIRequest
AWSCostExplorer 20260911124538, published 2026-09-11, USD
USE1-APIRequest
          0 to       Inf Request 0.0100
```

In the list AWS published on **11 September 2026**, every request costs 0.01 dollars. One command
typed by hand is a cent. A script that asks every minute, all month, is 60 × 24 × 30 = 43,200
requests, which is **432 dollars a month** spent on watching the bill. Ask once a day; the data
does not change faster than that.

## Anomaly detection

A budget fires when a total crosses a line. A cost that **doubled** in one service, while the
total stayed under the line, is something it never sees. **Cost Anomaly Detection** is the other
instrument: a **monitor** watches costs split by service, by account, by cost category or by a cost
allocation tag, learns their usual pattern from history, and reports a day that departs from it.
An **alert subscription** says who hears and how: each anomaly at once through an SNS topic, or a
daily or weekly summary by e-mail, above an impact you set in dollars or as a percentage. All of
this is from AWS's documentation; moto does not have it:

```
ana@laptop:~/aws$ aws ce get-anomaly-monitors 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the GetAnomalyMonitors operation (reached max retries: 2): <!doctype html>
```

The three instruments of this lesson answer three questions. A budget says the month is going over.
Anomaly detection says a pattern changed. Cost Explorer, grouped by the tags that billing knows,
says whose it was. Lesson 14 reads what the lines of the bill are, and lesson 15 opens the file
underneath all three, the Cost and Usage Report.
