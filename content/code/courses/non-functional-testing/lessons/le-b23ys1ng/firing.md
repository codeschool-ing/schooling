---
title: Firing for real, and where an alert goes
version: 1
---

A unit test proves the rule against invented numbers. The next step is to watch it fire against the
box office, under traffic that produces real failures. That needs three things: Prometheus
evaluating the rules, a box office that fails, and some traffic.

## Prometheus with rules

Replace `~/monitor/prometheus.yml` with this version. It is lesson 22's, with two blocks added:

```yaml
# monitor/prometheus.yml
# Lesson 24's version: lesson 22's scrapes, plus the rules to evaluate
# and the Alertmanager to tell when one of them fires.
global:
  scrape_interval: 5s
  evaluation_interval: 5s

rule_files:
  - alerts.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["127.0.0.1:9093"]

scrape_configs:
  - job_name: boxoffice
    static_configs:
      - targets: ["127.0.0.1:8000"]
  - job_name: node
    static_configs:
      - targets: ["127.0.0.1:9100"]
```

`rule_files` makes Prometheus evaluate `alerts.yml` every `evaluation_interval`, five seconds here.
`alerting` says where to send an alert once it fires: an **Alertmanager**, a separate program that
listens on port 9093 by default and that this section comes back to below. Nothing is listening
there yet, and that is deliberate.

## A box office that fails

The failures have to come from somewhere, and boxoffice as written never answers 5xx. `flaky.py` is
`observed.py` with a payment provider that times out on one call in three. Like lesson 23's
`slow.py`, it changes nothing in `app.py`; it replaces the function `pay` after importing it. Create
it in `~/boxoffice`:

```python
# boxoffice/flaky.py
# observed.py with a payment provider that times out on one call in three.
import random, time
import app, observed

def pay(customer, cents):
    time.sleep(app.PAYMENT_SECONDS)
    if random.random() < 0.33:
        raise TimeoutError("payment provider did not answer")

app.pay = pay
observed.serve()
```

The exception is raised inside the booking, after the lock is taken and before the row is written,
so the seat stays free, and `observed.py`'s `guarded` turns it into a 500 with the exception in the
log line.

Start everything, one terminal each, as in lesson 22: `python3 flaky.py > requests.log` in
`~/boxoffice`, then `prometheus --config.file=prometheus.yml --storage.tsdb.path=data` in
`~/monitor`, then lesson 22's traffic for four minutes, with k6's own flag overriding the
script's duration:

```sh
k6 run --duration 4m traffic.js
```

## Pending, then firing

The API's `/api/v1/alerts` lists every alert that is pending or firing. About fifty seconds into the
traffic:

```
ana@nft:~/monitor$ curl -s localhost:9090/api/v1/alerts | jq -c '.data.alerts[] | {alert: .labels.alertname, state, activeAt, value}'
{"alert":"BoxofficeErrorRatioHigh","state":"pending","activeAt":"2026-10-10T19:41:19.559363395Z","value":"3.6391060761412984e-02"}
```

**Pending means the expression is true and `for` has not run out.** `activeAt` is when it first
became true, and `value` is the ratio at the last evaluation, 3.6%. About a minute and a half
later:

```
ana@nft:~/monitor$ curl -s localhost:9090/api/v1/alerts | jq '.data.alerts[]'
{
  "labels": {
    "alertname": "BoxofficeErrorRatioHigh",
    "severity": "page"
  },
  "annotations": {
    "runbook_url": "https://wiki.example.com/runbooks/boxoffice-error-ratio",
    "summary": "boxoffice is failing 3.331% of its requests"
  },
  "state": "firing",
  "activeAt": "2026-10-10T19:41:19.559363395Z",
  "value": "3.3307772791676904e-02"
}
```

Firing, with the same `activeAt` and the annotations filled in from the measured value, 3.331%. The
summary is the sentence a phone would show, and the runbook link is the first thing the person
holding it opens.

Look at the number in the summary against what is failing. **One payment in three is failing, and
the alert says about 3%.** The ratio is over all requests, and bookings are only some of them:

```
ana@nft:~/monitor$ sh promql.sh 'sum by (route) (rate(boxoffice_requests_total{status=~"5.."}[5m])) / sum by (route) (rate(boxoffice_requests_total[5m]))'
{"route":"/bookings"}  0.2465155477571352
ana@nft:~/monitor$ sh promql.sh 'sum(rate(boxoffice_requests_total{route="/bookings"}[5m])) / sum(rate(boxoffice_requests_total[5m]))'
{}  0.1351142956128609
```

Per route, 24.7% of everything sent to `/bookings` failed; a 409 never reaches the payment, so it
counts in the bottom of that ratio and not the top, which is why it reads less than a third. And
bookings were 13.5% of all requests. Had the provider failed one call in ten, the overall ratio
would have been about 1%, under the line, while a tenth of the people trying to pay were turned
away. **An alert on the whole service hides a broken journey inside a
healthy average**, which is the argument for a second rule on the route that earns the money, with
its own threshold.

The log says which failure it was, with the request ids to follow:

```
ana@nft:~/boxoffice$ jq -c 'select(.level == "error")' requests.log | head -2
{"ts":"2026-10-10T19:41:05.980+00:00","level":"error","request_id":"51ac36cf319940d9","method":"POST","route":"/bookings","path":"/bookings","status":500,"ms":52.8,"error":"TimeoutError('payment provider did not answer')"}
{"ts":"2026-10-10T19:41:06.157+00:00","level":"error","request_id":"14db6ab7e09044b3","method":"POST","route":"/bookings","path":"/bookings","status":500,"ms":53.5,"error":"TimeoutError('payment provider did not answer')"}
```

## The alert nobody received

The alert fired, and nobody was told. Prometheus said so in its own terminal, at 19:43:19, two
minutes after `activeAt`, the moment `for` ran out:

```
ana@nft:~/monitor$ prometheus --config.file=prometheus.yml --storage.tsdb.path=data
…
ts=2026-10-10T19:43:19.568Z caller=notifier.go:529 level=error component=notifier alertmanager=http://127.0.0.1:9093/api/v2/alerts count=1 msg="Error sending alert" err="Post \"http://127.0.0.1:9093/api/v2/alerts\": dial tcp 127.0.0.1:9093: connect: connection refused"
```

**Prometheus decides when an alert fires; it does not decide who hears about it.** It hands the
alert to Alertmanager, and with no Alertmanager listening the alert goes nowhere, loudly in a log
nobody reads at night and silently everywhere else. It is a common way for an alerting setup to
fail, and the fix is to watch the watcher: Prometheus has its own metrics for this, such as
`prometheus_notifications_errors_total`, and the usual answer is a *dead man's switch*, an alert
that fires all the time and pages somebody when it *stops* arriving.

## Alertmanager

Alertmanager is in Ubuntu's archive as `prometheus-alertmanager`. **It is not installed on the
machine these transcripts were recorded on, so nothing below was run here.** On your VM, `sudo
apt-get install -y prometheus-alertmanager` installs it and starts it as a service on port 9093,
reading `/etc/prometheus/alertmanager.yml`. A configuration for boxoffice looks like this:

```yaml
# monitor/alertmanager.yml
# Where alerts go: anything labelled severity=page to the person on call,
# everything else to the team's queue, and nothing twice in four hours.
global:
  smtp_smarthost: "mail.example.com:587"
  smtp_from: "alertmanager@example.com"

route:
  receiver: team-queue
  group_by: [alertname]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  routes:
    - matchers: ['severity="page"']
      receiver: on-call

receivers:
  - name: on-call
    pagerduty_configs:
      - routing_key: "the-integration-key-pagerduty-gives-you"
  - name: team-queue
    email_configs:
      - to: "boxoffice-team@example.com"

inhibit_rules:
  - source_matchers: ['alertname="BoxofficeDown"']
    target_matchers: ['alertname="BoxofficeErrorRatioHigh"']
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l24-routing\" aria-label=\"Prometheus on the left sends firing alerts to Alertmanager in the middle. Alertmanager groups them, holds back the error ratio alert while BoxofficeDown is firing, and routes by label: alerts with severity page go to PagerDuty, which calls the person on call and, if nobody acknowledges, the secondary. Everything else goes to the team queue by e-mail, read in working hours.\"><defs><marker id=\"l24-routing-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l24-routing-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"120.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Prometheus</text><text x=\"85.0\" y=\"156.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decides it fires</text><path d=\"M152.0 150.0 L226.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l24-routing-nf-ah-paper-dim)\"></path><rect x=\"230.0\" y=\"80.0\" width=\"170.0\" height=\"140.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Alertmanager</text><text x=\"315.0\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">group</text><text x=\"315.0\" y=\"151.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">inhibit</text><text x=\"315.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">route by label</text><text x=\"315.0\" y=\"185.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">repeat every 4h</text><path d=\"M402.0 120.0 L476.0 80.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l24-routing-nf-ah-amber)\"></path><text x=\"440.0\" y=\"84.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">severity=&quot;page&quot;</text><path d=\"M402.0 190.0 L476.0 228.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l24-routing-nf-ah-paper-dim)\"></path><text x=\"446.0\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the rest</text><rect x=\"480.0\" y=\"50.0\" width=\"220.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">PagerDuty, Opsgenie</text><text x=\"590.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">call the person on call,</text><text x=\"590.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">then the secondary</text><rect x=\"480.0\" y=\"200.0\" width=\"220.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"221.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the team queue, by e-mail</text><text x=\"590.0\" y=\"234.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read in working hours</text></svg>", "caption": "Prometheus decides that an alert fires. Alertmanager decides who hears about it, and when."}
```

It does four jobs, and each is a way of making fewer, better notifications.

- **Routing.** The tree under `route` sends every alert labelled `severity="page"` to the person on
  call, here through PagerDuty, and everything else to an e-mail queue the team reads in working
  hours. The labels a rule sets are what this reads, which is why `severity` is a label and not an
  annotation.
- **Grouping.** `group_by: [alertname]` makes twenty instances of the same alert one notification,
  and `group_wait: 30s` waits half a minute for the rest of a group before sending the first. That
  30 seconds is part of lesson 1's five minutes.
- **Repeating.** `repeat_interval: 4h` sends a firing alert again every four hours, not every
  evaluation.
- **Inhibition.** While `BoxofficeDown` fires, `BoxofficeErrorRatioHigh` is held back: the person
  already knows the box office is down, and a second page about its error ratio says nothing new.
  In a larger system this is the rule that stops a failed database from paging once for each of
  the twenty services that use it.

The two example addresses and the PagerDuty key are placeholders. The package also installs
`amtool`, which checks a file like this one with `amtool check-config alertmanager.yml`, the same
way `promtool` checks rules.

**PagerDuty and Opsgenie** are two of the services teams commonly put at the end of that route. They are
the part that knows who is on call this week, calls their phone until they acknowledge, and calls
the next person on the list if they do not. Alertmanager can send to both, and to Slack, e-mail or
any address that accepts a webhook. Neither was used here.
