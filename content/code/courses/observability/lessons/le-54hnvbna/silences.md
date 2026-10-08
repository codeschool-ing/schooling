---
title: Silences: quiet on purpose, with a reason
version: 2
---

During planned work an alert can be right and useless: everybody already knows payments is down,
because they took it down. **A silence tells Alertmanager to stop notifying about matching alerts for a
while**, and it is the only acceptable way to make an alert quiet. Deleting the rule, raising its
threshold or muting the pager channel all outlive the maintenance; a silence ends by itself.

`amtool`, Alertmanager's command-line tool, creates one while the incident above is still firing:

```
ana@obs:~/shop$ docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence add alertname=CheckoutBudgetBurningFast --duration=20m --author=ana --comment='payments maintenance, ticket OPS-123'
54571fb2-98a1-4bbf-8160-d00b17c9f336
```

The answer is the silence's id. What it holds:

```
ana@obs:~/shop$ docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence query -o extended
ID                                    Matchers                                 Starts At                Ends At                  Updated At               Created By  Comment                               
54571fb2-98a1-4bbf-8160-d00b17c9f336  {alertname="CheckoutBudgetBurningFast"}  2026-10-02 20:24:53 UTC  2026-10-02 20:44:53 UTC  2026-10-02 20:24:53 UTC  ana         payments maintenance, ticket OPS-123  
```

**A matcher, an end, an author and a comment**, all four on purpose. The matcher is narrow: one alert
by name, not every alert of the shop. The end is twenty minutes away, so a forgotten silence cannot
hide next week's incident. And the author and comment answer the question anybody looking at a quiet
pager will ask: *who did this, and why?* `OPS-123` points at the change ticket.

The alert is still evaluated and still firing; it is just not sent:

```
ana@obs:~/shop$ curl -s localhost:9093/api/v2/alerts | jq -c '.[] | {alertname: .labels.alertname, severity: .labels.severity, state: .status.state, inhibitedBy: .status.inhibitedBy, silencedBy: .status.silencedBy}'
{"alertname":"CheckoutBudgetBurningSlowly","severity":"ticket","state":"suppressed","inhibitedBy":["50e1ed8789a027ea"],"silencedBy":[]}
{"alertname":"CheckoutBudgetBurningFast","severity":"page","state":"suppressed","inhibitedBy":[],"silencedBy":["54571fb2-98a1-4bbf-8160-d00b17c9f336"]}
```

Both alerts are `suppressed`, for different reasons: the ticket by the inhibition, and the page by the
silence, whose id it names.

Two rules for silences in a team:

- **Silence the page, not the problem.** If the maintenance was meant to take five minutes and the
  burn rate is still high after twenty, the silence expires and the page arrives, which is correct.
- **Silences are visible.** A list of active silences belongs on the on-call handover of lesson 18,
  because a silence somebody else made is the most surprising thing to discover during an incident.

When the work is done, the payments fault is removed and the silence is expired by hand rather than
left to run out:

```sh
rm faults/payments.json
```

Then the silence, and four minutes later the burn rates and the pager:

```
ana@obs:~/shop$ docker compose exec alertmanager sh -c 'amtool --alertmanager.url=http://localhost:9093 silence expire $(amtool --alertmanager.url=http://localhost:9093 silence query -q)'
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  0
__name__=checkout:burn_rate:5m  4.053000779423233
__name__=checkout:burn_rate:30m  4.15784887339723
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep -E '"(PAGE|TICKET)"' | jq -c '{message, status, alertname, severity}'
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"PAGE","status":"resolved","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"TICKET","status":"firing","alertname":"CheckoutBudgetBurningSlowly","severity":"ticket"}
{"message":"PAGE","status":"firing","alertname":"CheckoutBudgetBurningFast","severity":"page"}
{"message":"PAGE","status":"resolved","alertname":"CheckoutBudgetBurningFast","severity":"page"}
```

The one-minute burn rate is back to 0 and **the page resolves**, the last line of the pager's log. The
ticket is still firing: its thirty-minute window still holds the incident, at 4.2. That is what a slow
alert is for. It says the month is worse off than it was, and it says so without waking anybody.
