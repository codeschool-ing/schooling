---
title: The first minutes
version: 1
---

The lab stages an incident with the alerts of lesson 16 in place. A deploy robot marks a release of
payments in Grafana, as lesson 7's did:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["deploy"], "text": "payments 1.4.2"}' localhost:3000/api/annotations | jq -c .
{"id":1,"message":"Annotation added"}
```

The release is the fault file telling payments to fail one charge in eight. Nothing else happens until
the burn-rate alert decides it is worth a page:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix pager | grep '"PAGE"' | jq -c '{time, status, alertname, summary}'
{"time":"2026-10-02T20:49:58.986Z","status":"firing","alertname":"CheckoutBudgetBurningFast","summary":"Checkouts are failing fast enough to spend the month's error budget in two days"}
```

The page arrives three minutes after the release mark: the time the five-minute window needed to
fill with failures. The person on call reads the page and the three burn rates:

```
ana@obs:~/shop$ ./promq '{__name__=~"checkout:burn_rate:.*"}'
__name__=checkout:burn_rate:1m  24.752475247524753
__name__=checkout:burn_rate:5m  14.946663312584985
__name__=checkout:burn_rate:30m  12.473343961001747
```

24.8 over one minute, 14.9 over five, 12.5 over thirty: checkouts are failing at about thirteen
times the rate the month can afford, and it is still happening now. That is a SEV-2 by the shop's table: a large share of customers cannot buy. **The first
act is to say so**, where everybody can see it, with the commander's name:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"tags": ["incident"], "text": "SEV-2 declared: checkouts failing, IC ana"}' localhost:3000/api/annotations | jq -c .
{"id":2,"message":"Annotation added"}
```

Declaring took one command. In a real team it is a message in the incident channel and a status page
update, and the mark in Grafana is what ties both to the graphs.

**Then: where?** One query, failures as a share of requests, by service:

```
ana@obs:~/shop$ ./promq 'sum by (job) (rate(http_server_requests_total{code=~"5.."}[2m])) / sum by (job) (rate(http_server_requests_total[2m]))'
job=storefront  0.11090225563909775
job=payments  0.12473572938689217
job=orders  0.125
```

11% of the storefront's requests, 12.5% of orders' and of payments'. Payments fails the most, and every service above it fails in proportion. The same column of
red that lesson 11 read in a single trace, here in three numbers.

**And the question that solves most incidents: what changed?** The marks of the last half hour:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/annotations?from='$(date -d '-30 min' +%s000) | jq -r '.[] | [(.time/1000 | strftime("%H:%M:%S")), (.tags | join(",")), .text] | @tsv'
20:50:00	incident	SEV-2 declared: checkouts failing, IC ana
20:46:49	deploy	payments 1.4.2
```

Two marks: the declaration just written, and **a release of payments at 20:46:49**, three minutes
before the page. Nobody had to remember who deployed what, or search a chat log. The release mark was
written by a robot, and it names the service that is failing.
