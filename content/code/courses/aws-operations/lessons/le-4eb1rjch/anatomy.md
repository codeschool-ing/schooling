---
title: The parts of an alarm, and the three states
version: 1
---

An alarm watches one metric and answers one question every period: is this metric in a state somebody
should hear about? The common picture is a threshold: above it, alarm. **The threshold is one of five
numbers, and the other four decide whether the alarm wakes somebody for nothing**, or stays quiet
through an outage.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A bar chart of errors per minute over eleven minutes: 0, 1, 0, 12, 15, 0, 14, 16, then three minutes with no data. A dashed line marks the threshold of 10; the bars above it, 12, 15, 14 and 16, are highlighted. A dashed box around five consecutive points, 12, 15, 0, 14 and 16, is labelled last 5 points, 3 above, ALARM.\"><defs><marker id=\"mn-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M50 200 L665 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M50 130 L665 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"655\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">threshold 10</text><text x=\"80.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M115 200 L115 193 L155 193 L155 200 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"135.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"190.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M225 200 L225 116 L265 116 L265 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"245.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><path d=\"M280 200 L280 95 L320 95 L320 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"300.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15</text><text x=\"355.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M390 200 L390 102 L430 102 L430 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"410.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><path d=\"M445 200 L445 88 L485 88 L485 200 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"465.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"520.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no data</text><text x=\"520.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-</text><text x=\"575.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no data</text><text x=\"575.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-</text><text x=\"630.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no data</text><text x=\"630.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-</text><path d=\"M217 40 L493 40 L493 226 L217 226 Z\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></path><text x=\"223\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">last 5 points: 3 above, ALARM</text><text x=\"50\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Errors per minute. The window slides one minute at a time; at the end it holds two bad points and three empty ones.</text></svg>", "caption": "Three of five is the rule; what the three empty minutes at the end count as is the missing-data setting."}
```

| part | the shop's value | what it decides |
|---|---|---|
| statistic and period | `Sum` per 60 seconds | what one data point is |
| threshold and comparison | `GreaterThanThreshold` 10 | what counts as a breaching point |
| evaluation periods, N | 5 | how many recent points are looked at |
| datapoints to alarm, M | 3 | how many of those must breach |
| missing data | `notBreaching` | what a minute with no data counts as |

**M of N** is the part that makes an alarm usable. A single bad minute is noise: a burst of retries, a
deploy's restart. Three bad minutes out of five is a pattern, and the alarm fires on the pattern and
not on the noise. M equal to N, 5 of 5, waits for a perfect run of bad minutes and misses an outage
that flickers; M of 1 fires on every blip.

An alarm is always in one of three states: **`OK`**, **`ALARM`** and **`INSUFFICIENT_DATA`**, which
means the alarm cannot tell, because the data it needs is not there. It notifies on a **change** of
state, not on every period spent in one, so an alarm in `ALARM` for an hour sends one message, plus
one more when it returns to `OK`.

## In the lab

```
ana@laptop:~/aws/alarms$ aws sns create-topic --name shop-oncall --query TopicArn --output text
arn:aws:sns:sa-east-1:123456789012:shop-oncall
ana@laptop:~/aws/alarms$ aws cloudwatch put-metric-alarm --alarm-name api-errors --namespace Shop --metric-name Errors5xx --dimensions Name=Service,Value=api --statistic Sum --period 60 --evaluation-periods 5 --datapoints-to-alarm 3 --threshold 10 --comparison-operator GreaterThanThreshold --treat-missing-data notBreaching --alarm-actions arn:aws:sns:sa-east-1:123456789012:shop-oncall --ok-actions arn:aws:sns:sa-east-1:123456789012:shop-oncall
ana@laptop:~/aws/alarms$ aws cloudwatch describe-alarms --alarm-names api-errors --query 'MetricAlarms[0].[StateValue,StateReason,DatapointsToAlarm,EvaluationPeriods,TreatMissingData]' --output text
OK	Unchecked: Initial alarm creation	3	5	notBreaching
```

The alarm exists, with every number above, and its state is `OK` with the reason `Unchecked: Initial
alarm creation`. That reason never changes in moto: **moto stores alarms and never evaluates them**.
The next section publishes data that should fire this alarm, and then does the evaluation itself.
