---
title: Building it on CloudWatch
version: 1
---

Everything this lesson computed in Python, CloudWatch can compute itself, with **metric math**: queries
that read metrics and expressions that combine them, in `get-metric-data`, on a dashboard and in an
alarm. The availability SLI, as metric math:

```json
[
  {"Id": "errors", "MetricStat": {"Metric": {"Namespace": "Shop", "MetricName": "Errors", "Dimensions": [{"Name": "Service", "Value": "ongoing"}]}, "Period": 300, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "requests", "MetricStat": {"Metric": {"Namespace": "Shop", "MetricName": "Requests", "Dimensions": [{"Name": "Service", "Value": "ongoing"}]}, "Period": 300, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "sli", "Expression": "100 * (1 - errors / requests)", "Label": "availability, %"}
]
```

Two queries read the sums and do not return them (`ReturnData: false`); the expression divides them and
returns the indicator as a percentage.

```
ana@laptop:~/aws/slo$ aws cloudwatch get-metric-data --metric-data-queries file://math.json --start-time $(date -u -d '-30 min' +%FT%TZ) --end-time $(date -u +%FT%TZ) --query 'MetricDataResults[].[Id,Label,length(Values)]' --output text
sli	availability, %	0
```

**Zero values**: moto accepts the expression and computes nothing. On AWS, that query returns one
availability figure per five minutes, and an alarm can use the same three lines: the burn-rate alarm of
the previous section is two such alarms, one per window, each on the expression
`(errors / requests) / 0.001`, joined by a composite alarm with `AND` (lesson 10).

## Thirty days of minutes do not exist

A 30-day objective needs 30 days of counts. Lesson 8's retention table says one-minute data lasts 15
days and five-minute data 63, so **a rolling 30-day SLI is computed from five-minute sums**, or from a
copy of the counts kept somewhere longer. Teams that report SLOs for a year export the daily totals, a
few numbers per service per day, into a table of their own.

## Application Signals

CloudWatch also offers SLOs as a feature, under **Application Signals**: an objective defined on a
service's latency or availability, with the budget and the burn rate computed and drawn by AWS, and
alarms on them. It saves building the math by hand and is billed separately; moto does not implement
it, so it was not run here. The arithmetic underneath is this lesson's, which is what makes its numbers
readable.

## What to show, and to whom

| audience | what they need |
|---|---|
| the team on call | burn-rate alarms on two windows, nothing else pages |
| the team's planning | budget remaining this month, and what spent it |
| the business | the objective, met or not, month by month |

An SLO dashboard that shows the budget remaining as a single number, with the incidents that spent it
listed beside it, is the one that changes decisions.
