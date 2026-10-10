---
title: A rule, and a test for the rule
version: 1
---

Lesson 1 left one row of its table for this lesson: *an alert reaches the person on call within
5 minutes of the error rate passing 2%*. Here is that row as a Prometheus rule. Create
`alerts.yml` in `~/monitor`:

```yaml
# monitor/alerts.yml
# Page somebody when boxoffice fails its customers: more than 2% of requests
# answered with a 5xx over five minutes, or the process not answering at all.
groups:
  - name: boxoffice
    rules:
      - alert: BoxofficeErrorRatioHigh
        expr: |
          sum(rate(boxoffice_requests_total{status=~"5.."}[5m]))
            / sum(rate(boxoffice_requests_total[5m])) > 0.02
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "boxoffice is failing {{ $value | humanizePercentage }} of its requests"
          runbook_url: "https://wiki.example.com/runbooks/boxoffice-error-ratio"

      - alert: BoxofficeDown
        expr: up{job="boxoffice"} == 0
        for: 1m
        labels:
          severity: page
        annotations:
          summary: "Prometheus cannot reach boxoffice at {{ $labels.instance }}"
          runbook_url: "https://wiki.example.com/runbooks/boxoffice-down"
```

Each rule has four parts, and each one is a decision somebody should be able to explain.

- **`expr`** is the symptom, written in PromQL. The first is lesson 22's error ratio over a
  five-minute window, compared with 0.02. The second is `up`, which Prometheus writes for every
  target it scrapes: 0 means it could not reach boxoffice at all, the failure that makes the error
  ratio go silent rather than high.
- **`for`** is how long the expression has to stay true before the alert fires. Until then it is
  *pending*. Two minutes for the ratio, one for `up`, for the reasons in the section before this
  one.
- **`labels`** are what the routing reads. `severity: page` is this course's convention for "wake
  somebody up"; nothing in Prometheus knows the word.
- **`annotations`** are what the person reads. The summary carries the measured value, formatted
  as a percentage by `humanizePercentage`, and `runbook_url` says where the instructions are.

## Checking it

Prometheus comes with `promtool`, which you installed in lesson 22 with the same package. First,
whether the file is a valid set of rules at all:

```
ana@nft:~/monitor$ promtool check rules alerts.yml
Checking alerts.yml
  SUCCESS: 2 rules found
```

That catches a YAML mistake, an unknown function or a PromQL syntax error. **It cannot say
whether the rule fires when it should**, which is the only thing anybody cares about at 03:00. For
that, `promtool` runs unit tests: made-up series, fed to the rules minute by minute, with the
alerts you expect at chosen moments. Create `alerts_test.yml` beside it:

```yaml
# monitor/alerts_test.yml
# Made-up series, fed to alerts.yml one minute at a time by promtool.
rule_files:
  - alerts.yml
evaluation_interval: 1m

tests:
  # 100 good answers a minute throughout; from minute 10, 5 failures a minute too.
  - interval: 1m
    input_series:
      - series: 'boxoffice_requests_total{route="/bookings",status="201"}'
        values: '0+100x30'
      - series: 'boxoffice_requests_total{route="/bookings",status="500"}'
        values: '0x9 5+5x20'
    alert_rule_test:
      - eval_time: 9m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts: []
      - eval_time: 13m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts: []
      - eval_time: 14m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts:
          - exp_labels:
              severity: page
            exp_annotations:
              summary: "boxoffice is failing 4.762% of its requests"
              runbook_url: "https://wiki.example.com/runbooks/boxoffice-error-ratio"

  # 1% failing, for half an hour: annoying, and below the line.
  - interval: 1m
    input_series:
      - series: 'boxoffice_requests_total{route="/bookings",status="201"}'
        values: '0+99x30'
      - series: 'boxoffice_requests_total{route="/bookings",status="500"}'
        values: '0+1x30'
    alert_rule_test:
      - eval_time: 30m
        alertname: BoxofficeErrorRatioHigh
        exp_alerts: []

  # The process stops answering at minute 3.
  - interval: 1m
    input_series:
      - series: 'up{job="boxoffice",instance="127.0.0.1:8000"}'
        values: '1 1 1 0 0 0 0'
    alert_rule_test:
      - eval_time: 3m
        alertname: BoxofficeDown
        exp_alerts: []
      - eval_time: 4m
        alertname: BoxofficeDown
        exp_alerts:
          - exp_labels:
              severity: page
              job: boxoffice
              instance: 127.0.0.1:8000
            exp_annotations:
              summary: "Prometheus cannot reach boxoffice at 127.0.0.1:8000"
              runbook_url: "https://wiki.example.com/runbooks/boxoffice-down"
```

The notation `'0+100x30'` means start at 0 and add 100 each step, thirty times: a counter of 100
good answers a minute. `'0x9 5+5x20'` is ten zeros and then a counter growing by 5 a minute, the
failures starting at minute 10. At that point the ratio is 5 in 105, 4.76%, which is what the
expected summary says once `humanizePercentage` has rounded it. Run it:

```
ana@nft:~/monitor$ promtool test rules alerts_test.yml
Unit Testing:  alerts_test.yml
  SUCCESS
```

The three tests hold four claims about the rules. Before the failures nothing fires. The
failures start at minute 10, yet nothing fires at 13 and the alert is firing at 14, because the
five-minute ratio needs until minute 12 to climb past 2% and then has to stay there for the two
minutes of `for`. A steady 1% fires nothing in half an hour. And a boxoffice that stops answering
at minute 3 fires its alert at minute 4.

## Watching a test fail

A test that has only ever passed proves little. Change `for: 2m` to `for: 5m`, a value that looks
just as reasonable, and run it again:

```
ana@nft:~/monitor$ sed -i 's/for: 2m/for: 5m/' alerts.yml
ana@nft:~/monitor$ promtool test rules alerts_test.yml
Unit Testing:  alerts_test.yml
  FAILED:
    alertname: BoxofficeErrorRatioHigh, time: 14m, 
        exp:[
            0:
              Labels:{alertname="BoxofficeErrorRatioHigh", severity="page"}
              Annotations:{runbook_url="https://wiki.example.com/runbooks/boxoffice-error-ratio", summary="boxoffice is failing 4.762% of its requests"}
            ], 
        got:[]


ana@nft:~/monitor$ sed -i 's/for: 5m/for: 2m/' alerts.yml
```

**The test failed and said why**: at minute 14 it expected one alert and got none, because with
five minutes of `for` the alert would fire at minute 17. That is five minutes after the ratio
passed 2%, the whole of what lesson 1's requirement allows, spent before anything has been sent to
anybody. The rule file and its test are two files in the repository, reviewed together, run by
`promtool test rules` in the same pipeline as every other test. A change to a threshold that breaks
a promise now breaks a build.
The last command above put `for: 2m` back.
