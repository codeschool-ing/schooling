---
title: Rules, and an alert from rule to pager
version: 1
---

Queries so far were asked by a person. **Rules are queries Prometheus asks itself**, every fifteen
seconds, from files listed in `prometheus.yml`. There are two kinds, and the lab's rules file now
has both:

```yaml
groups:
  - name: shop
    rules:
      - alert: TargetDown
        expr: up == 0
        for: 1m
        labels:
          severity: ticket
        annotations:
          summary: "{{ $labels.job }} has not answered a scrape for a minute"

      - record: job:http_server_requests:rate1m
        expr: sum by (job, code) (rate(http_server_requests_total[1m]))

      - alert: PaymentsFailing
        expr: |
          sum(job:http_server_requests:rate1m{job="payments", code=~"5.."})
            / sum(job:http_server_requests:rate1m{job="payments"}) > 0.02
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "More than 2% of charges are failing"

      - alert: ReportNotRun
        expr: time() - report_last_success_timestamp_seconds > 26 * 3600
        labels:
          severity: ticket
        annotations:
          summary: "The nightly report has not finished for over 26 hours"
```

A **recording rule**, `record:`, evaluates an expression and stores the result as a new series under
the name given. `job:http_server_requests:rate1m` is the rate per job and code, computed once per
evaluation instead of once per dashboard panel and per alert that wants it; the name follows the
convention *level:metric:operation*. An **alerting rule**, `alert:`, evaluates an expression and,
for every series that comes back, holds an alert. `PaymentsFailing` is the ratio from earlier in
this lesson, written over the recording rule, and `ReportNotRun` is the Pushgateway's timestamp
with twenty-six hours on it: a day, plus slack for a run that started late.

The file is checked with `promtool`, from Prometheus's own image, and Prometheus is told to reload:

```
ana@obs:~/shop$ docker run --rm -v ./prometheus:/etc/prometheus --entrypoint promtool prom/prometheus:v3.15.0 check rules /etc/prometheus/rules/shop.yml
Checking /etc/prometheus/rules/shop.yml
  SUCCESS: 4 rules found

ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && echo reloaded
reloaded
```

Twenty seconds later the recorded series exists, and the alert has started:

```
ana@obs:~/shop$ ./promq 'job:http_server_requests:rate1m{job="payments"}'
__name__=job:http_server_requests:rate1m code=200 job=payments  4.266666666666666
__name__=job:http_server_requests:rate1m code=503 job=payments  0.2222222222222222
ana@obs:~/shop$ curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt] | @tsv'
PaymentsFailing	pending	2026-10-02T10:07:39.145836091Z
```

**`pending`, not firing.** The rule says `for: 2m`: the condition has to hold on every evaluation
for two minutes before the alert fires. Two minutes later:

```
ana@obs:~/shop$ curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | [.labels.alertname, .state, .activeAt] | @tsv'
PaymentsFailing	firing	2026-10-02T10:07:39.145836091Z
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The life of the PaymentsFailing alert, left to right. Inactive while the condition is false. Pending from 10:07:39, when the error ratio first exceeded 2 per cent: Prometheus waits, because the rule says for 2m. Firing two minutes later, if the condition held throughout: Prometheus sends it to Alertmanager. Alertmanager groups it, waits 10 seconds for others, and sends it to the pager, which logged a PAGE line.\"><defs><marker id=\"life-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">inactive</text><text x=\"65.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">condition false</text><rect x=\"155\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pending</text><text x=\"210.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">true, waiting for: 2m</text><rect x=\"310\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">firing</text><text x=\"365.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">true for 2 minutes</text><rect x=\"470\" y=\"70\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Alertmanager</text><text x=\"525.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">group_wait 10s</text><rect x=\"610\" y=\"70\" width=\"90\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pager</text><text x=\"655.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PAGE line</text><path d=\"M122 100 L153 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M267 100 L308 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M422 100 L468 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M582 100 L608 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><path d=\"M210 132 L210 165 L70 165 L70 132\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#life-ah)\"></path><text x=\"140\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">condition clears: back to inactive, nobody paged</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one alert, from rule to pager</text></svg>", "caption": "for: 2m is the difference between a blip and a page. A condition that clears before the two minutes are up goes back to inactive, and nobody is woken."}
```

Prometheus only decides that an alert is firing. **Who hears about it is Alertmanager's job**: it
receives every firing alert, groups the ones that belong together, holds back duplicates, and sends
each group to a receiver. The lab's routes everything to the pager:

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -r '.[] | [.labels.alertname, .labels.severity, .status.state] | @tsv'
PaymentsFailing	page	active
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep PAGE | jq -c '{status, alertname, severity, summary}'
{"status":"firing","alertname":"PaymentsFailing","severity":"page","summary":"More than 2% of charges are failing"}
```

Alertmanager holds the alert as `active`, and the pager logged the page, with the severity and the
summary the rule gave it. **Every word in that line was written in the rule**, which is why lesson 16
spends its time on what a rule should say and to whom. The fault file was removed at the end of the
capture.
