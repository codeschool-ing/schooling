---
title: Routing: pages, tickets, and inhibition
version: 2
---

Prometheus decides that an alert is firing. **Alertmanager decides who hears about it**, how often,
and together with what. Lesson 5's configuration sent everything to the pager. The new one,
`alertmanager/routes.yml`, saved as the `cat` below prints it, separates the two severities:

```
ana@obs:~/shop$ cat alertmanager/routes.yml
# Pages and tickets go to different places, and a page silences the ticket
# about the same objective.
route:
  receiver: tickets
  group_by: [alertname, slo]
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 4h
  routes:
    - matchers: ['severity="page"']
      receiver: pager

inhibit_rules:
  - source_matchers: ['severity="page"']
    target_matchers: ['severity="ticket"']
    equal: [slo]

receivers:
  - name: pager
    webhook_configs:
      - url: http://pager:8090/page
  - name: tickets
    webhook_configs:
      - url: http://pager:8090/ticket
```

Three parts, each with a job:

- **The route tree.** Every alert enters at the top, whose receiver is `tickets`. A child route
  catches `severity="page"` and sends it to the pager instead. Routes are matched top-down and the
  first match wins, unless a route says to continue.
- **Grouping.** Alerts with the same `alertname` and `slo` become one notification, sent ten seconds
  after the first arrives (`group_wait`) so that alerts firing together arrive together. A repeat goes
  out every four hours while the alert keeps firing.
- **Inhibition.** While a `page` fires, any `ticket` with the same `slo` is held back. The person
  already woken for checkouts failing fast does not need a second message about checkouts failing
  slowly.

An override points Alertmanager at the new file:

`~/shop/compose.override.yaml`

```yaml
services:
  alertmanager:
    command: [--config.file=/etc/alertmanager/routes.yml]
```

And Alertmanager is recreated with it:

```
ana@obs:~/shop$ docker compose up -d alertmanager 2>&1 | tail -1
 Container shop-alertmanager-1 Started 
```

In the incident above, both alerts fired. The page went to the pager. The ticket reached `/ticket` once, in the moment the page had
flapped to resolved, and was held back the rest of the time. In the API the ticket shows as
`suppressed`, with the id of the rule that inhibited it in `inhibitedBy`.

**The labels are the contract between the two programs.** Prometheus writes `severity` and `slo` on
the alert, and Alertmanager routes and inhibits on them. A rule written without `severity` falls to
the default receiver. That is why the default receiver is the ticket queue and not the pager: an
alert nobody classified should not wake anybody.
