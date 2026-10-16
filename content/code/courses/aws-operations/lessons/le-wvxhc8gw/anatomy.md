---
title: What a metric is, and what makes two of them different
version: 1
---

A CloudWatch metric is a series of numbers over time, and the common picture of it stops there: a
name, like `Orders`, and its values. **The name is a third of the identity.** A metric is identified by
its namespace, its name and its dimensions together, and changing any one of the three
makes a different metric, with its own history and its own line on the bill.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A metric is drawn as three boxes: namespace Shop, name Orders, dimensions Service=api and Stage=prod. Below, three rows. Shop Orders with Service=api and Stage=prod holds 12 orders. Shop Orders with Service=api and Stage=staging holds 3. Shop Orders with only Service=api was never published, and on AWS has no data.\"><defs><marker id=\"mid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">three parts make one metric</text><rect x=\"20\" y=\"44\" width=\"140\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">namespace</text><text x=\"90.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Shop</text><rect x=\"180\" y=\"44\" width=\"140\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">name</text><text x=\"250.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Orders</text><rect x=\"340\" y=\"44\" width=\"360\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dimensions</text><text x=\"520.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Service=api, Stage=prod</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Change any part and it is another metric, with its own history and its own line on the bill:</text><rect x=\"20\" y=\"150\" width=\"680\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop  Orders  Service=api, Stage=prod</text><text x=\"688\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">12 orders</text><rect x=\"20\" y=\"178\" width=\"680\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop  Orders  Service=api, Stage=staging</text><text x=\"688\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">3 orders</text><rect x=\"20\" y=\"206\" width=\"680\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Shop  Orders  Service=api</text><text x=\"688\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">never published: no data on AWS</text></svg>", "caption": "A query names one metric exactly. CloudWatch adds metrics up only when asked, with math or a search."}
```

- the **namespace** is a container, `AWS/EC2` for AWS's own metrics and anything you choose, here
  `Shop`, for yours;
- the **name** says what is measured: `Orders`, `Latency`;
- the **dimensions** are name-value pairs that say which thing it was measured on: `Service=api`,
  `Stage=prod`. Up to 30 per metric.

Each data point carries a timestamp, a value and a unit. **The period and the statistic are not
part of the data**: they are chosen when somebody reads it. The same data points can be read as a
sum per minute, an average per hour or a maximum per day.

## Publishing two, and asking for three

```
ana@laptop:~/aws/metrics$ aws cloudwatch put-metric-data --namespace Shop --metric-name Orders --dimensions Service=api,Stage=prod --unit Count --value 12
ana@laptop:~/aws/metrics$ aws cloudwatch put-metric-data --namespace Shop --metric-name Orders --dimensions Service=api,Stage=staging --unit Count --value 3
ana@laptop:~/aws/metrics$ aws cloudwatch list-metrics --namespace Shop --query 'Metrics[].Dimensions[].[Name,Value]' --output text
Service	api
Stage	prod
Service	api
Stage	staging
```

Two data points with the same namespace and name and different `Stage` values made **two metrics**,
and the listing shows both sets of dimensions. Now read them back three ways, over the last ten
minutes:

```
ana@laptop:~/aws/metrics$ START=$(date -u -d "-10 min" +%FT%TZ); END=$(date -u -d "+1 min" +%FT%TZ)
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --dimensions Name=Service,Value=api Name=Stage,Value=prod --start-time $START --end-time $END --period 600 --statistics Sum --query 'Datapoints[].Sum'
[
    12.0
]
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --dimensions Name=Service,Value=api --start-time $START --end-time $END --period 600 --statistics Sum --query 'Datapoints[].Sum'
[
    15.0
]
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Orders --start-time $START --end-time $END --period 600 --statistics Sum --query 'Datapoints[].Sum'
[
    15.0
]
```

With both dimensions, the 12 orders of production. With only `Service=api`, and with no dimensions at
all, **moto answers 15**: it adds up every metric whose dimensions include the ones asked for. **AWS
does not.** On CloudWatch, the query names one metric exactly, and a metric with fewer dimensions is a
different metric that nobody published, so the second and third commands return an empty list. That
was not run here, and it is the behaviour to expect: a dashboard that shows zero orders because one
dimension was left out of its query is one of the most common ways a graph lies, and it lies by being
empty. Adding metrics up across a dimension is something you ask for, with metric math or a
`SEARCH` expression, never something CloudWatch does by itself.

## Resolution and retention

A data point published with the default **standard resolution** is stored per minute; with
`--storage-resolution 1`, high resolution, per second, which costs more to alarm on. CloudWatch then
keeps less detail as data ages, which is AWS's documented behaviour rather than anything run here:

| age of the data | smallest period available |
|---|---|
| under 3 hours | 1 second, for high-resolution metrics |
| under 15 days | 1 minute |
| under 63 days | 5 minutes |
| under 15 months | 1 hour |

So a question about a spike three months ago can only be answered in hours, and a minute-by-minute
graph of last quarter does not exist. **Export what you need to keep in detail** before it ages out,
which lesson 12 does for the numbers an error budget is built from.
