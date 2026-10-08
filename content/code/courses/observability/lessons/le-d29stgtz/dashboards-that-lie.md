---
title: Dashboards that lie
version: 2
---

Every number on a dashboard is true, and a dashboard can still mislead. The commonest ways are few,
and each has a fix.

**The window hides what happened.** Every tenth charge is made to fail for seventy seconds, and
thirty seconds after it stopped, the same error share is asked over two windows:

```sh
echo '{"fail_every": 10}' > faults/payments.json
sleep 70
rm faults/payments.json
sleep 30
```

```
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job="payments",code=~"5.."}[1m])) / sum(rate(http_server_requests_total{job="payments"}[1m]))' | jq -r '.data.result[0].value[1]'
0.059113300492610835
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job="payments",code=~"5.."}[10m])) / sum(rate(http_server_requests_total{job="payments"}[10m]))' | jq -r '.data.result[0].value[1]'
0.01731959787210252
```

**5.9 per cent over the last minute, 1.7 per cent over the last ten**, for the same failures. A
panel with a ten-minute window would have shown a mild bump during an outage in which one charge in
ten failed. A one-minute window shows it as it was, and is noisier the rest of the time. Neither
is wrong. A dashboard should say which window it uses, in the panel's title or its legend, and an
alert, in lesson 16, uses two at once.

**An average hides the slow ones.** The mean of a thousand fast checkouts and ten that took eight
seconds is still fast. That is why the shop's dashboard draws percentiles from a histogram and never
the mean, and why lesson 6 spent a section on what a percentile from buckets can and cannot say.

**A missing series looks like a zero.** If payments stops answering scrapes, its error share is not
zero, it is unknown. A panel that draws *no data* as a flat line at zero says the opposite of the
truth. Show gaps as gaps, and keep `up` on the same dashboard.

**The axis exaggerates.** A y-axis that starts at 0.98 turns a change from 0.995 to 0.991 into a
cliff. The shop's panels declare `"min": 0`.

**A dashboard nobody designed shows everything.** Forty panels with every metric a service exports
answer no question. The usual structure for a service is three panels, the ones the shop has:
**rate, errors, duration**, known as the RED method, with the dependencies' versions of the same
three below them. For a resource such as a disk or a queue the equivalent is utilisation,
saturation and errors, the USE method. Each panel should answer a question somebody asks during an
incident, and a panel nobody can name the question for should go.
