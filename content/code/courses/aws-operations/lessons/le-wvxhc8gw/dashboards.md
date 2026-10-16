---
title: A dashboard for the person who opens it at three
version: 1
---

A dashboard is a JSON document of widgets, and it is worth keeping in the repository beside the
service, like the alarms of lesson 10, so that it changes when the service does. The shop's API
dashboard, `dashboard.json`:

```json
{
  "widgets": [
    {
      "type": "text", "x": 0, "y": 0, "width": 24, "height": 2,
      "properties": {
        "markdown": "## shop api\nOwner: team shop. When this page is red, start with the latency graph."
      }
    },
    {
      "type": "metric", "x": 0, "y": 2, "width": 12, "height": 6,
      "properties": {
        "title": "Latency, p50 and p99", "region": "sa-east-1", "period": 60,
        "metrics": [
          ["Shop", "Latency", "Service", "api", { "stat": "p50" }],
          ["...", { "stat": "p99" }]
        ]
      }
    },
    {
      "type": "metric", "x": 12, "y": 2, "width": 12, "height": 6,
      "properties": {
        "title": "Orders per minute", "region": "sa-east-1", "period": 60, "stat": "Sum",
        "metrics": [["Shop", "Orders", "Service", "api", "Stage", "prod"]]
      }
    }
  ]
}
```

Each widget has a position on a grid 24 units wide and a `properties` object. A metric row lists the
namespace, the name and the dimensions as pairs; `"..."` repeats the row above, so the p99 line is the
same metric with another statistic. The text widget is the part people leave out and the part the
person paged at three in the morning needs most: **who owns this, and where to look first**.

```
ana@laptop:~/aws/metrics$ aws cloudwatch put-dashboard --dashboard-name shop-api --dashboard-body file://dashboard.json
{
    "DashboardValidationMessages": []
}
ana@laptop:~/aws/metrics$ aws cloudwatch list-dashboards --query 'DashboardEntries[].[DashboardName,Size]' --output text
shop-api	833
ana@laptop:~/aws/metrics$ aws cloudwatch get-dashboard --dashboard-name shop-api --query DashboardBody --output text | jq '.widgets | length'
3
```

moto stored the dashboard and returns its body; there is no console here to draw it. On AWS the
console draws each widget from the metrics, and `get-metric-widget-image` renders one as a picture for
a chat message or a postmortem.

## What belongs on it

A dashboard that shows everything shows nothing. For a service, four signals answer most questions,
in this order:

1. **latency**, as p50 and p99, because it is what customers feel first;
2. **traffic**, requests or orders per minute, because every other number is read against it;
3. **errors**, as a rate rather than a count, because ten errors in a quiet hour and in a busy one
   are different news;
4. **saturation**: the resource that runs out first, a queue's depth, a pool's connections.

Put the business metric beside them (orders here) and leave infrastructure detail to dashboards of
its own. **The dashboard is for recognising the problem; the logs are for explaining it**, and lesson
9 is about those.

Dashboards are billed per dashboard per month beyond a free few, and that line is not in the bulk
price list this course reads; AWS's CloudWatch pricing page carries it.
