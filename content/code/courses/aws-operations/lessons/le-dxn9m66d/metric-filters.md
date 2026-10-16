---
title: Metric filters, and turning lines into a number
version: 1
---

A query answers a question when somebody asks it. An alarm needs a number every minute without
anybody asking. A **metric filter** connects the two: it watches every line arriving in a log group,
and for each line that matches its pattern it adds a value to a metric. The shop's errors, counted from
its logs:

```
ana@laptop:~/aws/logs$ aws logs put-metric-filter --log-group-name /shop/api --filter-name errors-5xx --filter-pattern '{ $.status >= 500 }' --metric-transformations metricName=Errors5xx,metricNamespace=Shop,metricValue=1,defaultValue=0
ana@laptop:~/aws/logs$ aws logs describe-metric-filters --log-group-name /shop/api --query 'metricFilters[0].[filterName,filterPattern,metricTransformations[0].metricName]' --output text
errors-5xx	{ $.status >= 500 }	Errors5xx
ana@laptop:~/aws/logs$ jq -n --arg t "$(date +%s000)" '[{timestamp: ($t | tonumber), message: ({status: 503, path: "/checkout"} | tojson)}]' > one.json
ana@laptop:~/aws/logs$ aws logs put-log-events --log-group-name /shop/api --log-stream-name api-1 --log-events file://one.json --query rejectedLogEventsInfo
null
ana@laptop:~/aws/logs$ aws cloudwatch list-metrics --namespace Shop --query 'Metrics'
[]
```

The filter was stored, with its pattern and the metric it feeds, `Shop/Errors5xx`. Then a line with
status 503 arrived, and **no metric appeared**: moto stores metric filters and never runs them. On
AWS, that line would have added 1 to `Errors5xx` within the minute, and `defaultValue=0` makes the
filter publish a zero in minutes with no matching line, so an alarm sees a quiet minute as zero
rather than as missing data, which lesson 10 explains.

## Logs, metrics and their order

Metric filters invert the order of lesson 8. There, the application published metrics and kept logs
for detail; here, the application only writes logs and the metrics are derived from them. Both work,
and they fail differently:

| | published metric | metric from a filter |
|---|---|---|
| cost | a custom metric and its requests | the log ingestion, already paid |
| when the pattern changes | a code change | a filter change, no deployment |
| when logging is reduced | unaffected | the metric drops, silently |

The last row is the one to remember. **A metric derived from logs depends on a line somebody may
delete** while cleaning up logging to save money, and nothing tells them the alarm downstream just went
blind. Keep the lines a filter reads in the same review as the filter, or publish the metric directly.

## Sending lines somewhere else

A **subscription filter** is the other way a log group pushes lines out: every matching line is sent, as
it arrives, to a Kinesis stream, a Firehose delivery stream or a Lambda function, for a search service
or an archive in S3. It is how logs leave CloudWatch for a tool that keeps them longer or cheaper, and
it is billed as the delivery the destination receives.
