---
title: Writing the rule
version: 1
---

The shop's new alerts live in `prometheus/rules/burn.yml`, beside three recording rules for the burn
rate over 1, 5 and 30 minutes, each the expression of lesson 15 divided by the allowed 0.5%. The two
alerts:

```
ana@obs:~/shop$ sed -n '/- alert: CheckoutBudgetBurningFast/,$p' prometheus/rules/burn.yml
      - alert: CheckoutBudgetBurningFast
        expr: checkout:burn_rate:5m > 14.4 and checkout:burn_rate:1m > 14.4
        labels:
          severity: page
          slo: checkout
        annotations:
          summary: "Checkouts are failing fast enough to spend the month's error budget in two days"
          description: "{{ $value | printf \"%.0f\" }}x the sustainable rate of failed checkouts, over 5 minutes and still now."
          runbook_url: "https://wiki.example.invalid/runbooks/checkout-failing"

      - alert: CheckoutBudgetBurningSlowly
        expr: checkout:burn_rate:30m > 3 and checkout:burn_rate:5m > 3
        labels:
          severity: ticket
          slo: checkout
        annotations:
          summary: "Checkouts are failing fast enough to spend the month's error budget in nine days"
```

Every field of an alert is read by somebody, and each has a job:

- **The name says what is wrong for users**, `CheckoutBudgetBurningFast`, and not which component
  fired it. It is the first thing on a phone's lock screen.
- **`severity` decides where it goes** and is the only label Alertmanager's routing reads in this
  lab. `slo` says which objective it belongs to, and the next section uses it to keep a page and a
  ticket about the same thing from both arriving.
- **`summary` is for the person woken up**, so it says the consequence in words: *fast enough to spend
  the month's error budget in two days*. A summary that says `burn_rate > 14.4` makes the person
  translate it at three in the morning.
- **`description` adds the measurement**, here the current burn rate through `{{ $value }}`, so
  the page itself answers *how bad?*
- **`runbook_url` points at what to do.** A runbook is a short page: what this alert means, the first
  three things to check, how to roll back, and whom to call. An alert without one leaves every new
  on-call engineer to rediscover them.

There is no `for:` on either alert. A `for: 2m` delays every alert by two minutes to filter out blips,
and the second window already does that job without the delay. The previous section showed the price
of leaving it out: when the burn rate hovers near the threshold, the page flaps.

Prometheus reads the file again, and the five rules load:

```
ana@obs:~/shop$ curl -s -X POST localhost:9090/-/reload && curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name == "checkout-burn") | .rules[] | [.name, .health] | @tsv'
checkout:burn_rate:1m	unknown
checkout:burn_rate:5m	unknown
checkout:burn_rate:30m	unknown
CheckoutBudgetBurningFast	unknown
CheckoutBudgetBurningSlowly	unknown
```
