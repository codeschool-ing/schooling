---
title: Testing the plan
version: 1
---

Lesson 11's plan, as a test: 1,000 reads and 100 sales a second, the first minute of the on-sale,
for thirty seconds. Two scenarios run at once, each tagging its requests with a `kind`, and the
pass mark is written into the test as **thresholds**: the 95th percentile of reads under 100 ms, of
sales under 250 ms, and fewer than 1% of requests failing, where k6 counts any status of 400 or
more as a failure. Save it as `onsale.js`:

```javascript
// onsale.js
import http from "k6/http";

const READS = Number(__ENV.READS || 1000);
const SALES = Number(__ENV.SALES || 100);

export const options = {
  scenarios: {
    reads: {
      executor: "constant-arrival-rate", exec: "read",
      rate: READS, timeUnit: "1s", duration: "30s",
      preAllocatedVUs: 100, maxVUs: 1000,
    },
    sales: {
      executor: "constant-arrival-rate", exec: "sale",
      rate: SALES, timeUnit: "1s", duration: "30s",
      preAllocatedVUs: 50, maxVUs: 1000,
    },
  },
  thresholds: {
    "http_req_duration{kind:read}": ["p(95)<100"],
    "http_req_duration{kind:sale}": ["p(95)<250"],
    "http_req_failed": ["rate<0.01"],
  },
  summaryTrendStats: ["med", "p(95)", "p(99)", "max"],
};

const show = () => Math.floor(Math.random() * 50) + 1;

export function read() {
  http.get(`http://localhost:8080/events/${show()}`, { tags: { kind: "read" } });
}

export function sale() {
  http.post(`http://localhost:8080/events/${show()}/tickets`, null, {
    tags: { kind: "sale" },
    headers: { "X-Buyer": `buyer-${__VU}-${__ITER}` },
  });
}

export function handleSummary(data) {
  const lines = [];
  for (const [name, metric] of Object.entries(data.metrics)) {
    for (const [rule, result] of Object.entries(metric.thresholds || {})) {
      const v = metric.values;
      const seen = "p(95)" in v ? `${v["p(95)"].toFixed(1)} ms` : `${(v.rate * 100).toFixed(2)}%`;
      lines.push(`${result.ok ? "ok    " : "FAILED"}  ${name} ${rule}  (was ${seen})`);
    }
  }
  return { stdout: lines.sort().join("\n") + "\n" };
}
```

This `handleSummary` prints only the thresholds, each with the value it was judged on. When any of
them is crossed, k6 exits with code 99 instead of 0, which is what makes a test a gate: a pipeline
that runs it before a release stops on a failed threshold, with nobody having to read anything.

First with one copy, then with three:

```
ana@lab:~/tickets$ docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none - < onsale.js; echo "exit code $?"
FAILED  http_req_duration{kind:read} p(95)<100  (was 4453.4 ms)
FAILED  http_req_duration{kind:sale} p(95)<250  (was 5092.5 ms)
ok      http_req_failed rate<0.01  (was 0.31%)
exit code 99
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-prometheus-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-payments-1 Running 
 Container tickets-app-1 Running 
 Container tickets-collector-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-jaeger-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Creating 
 Container tickets-app-3 Created 
 Container tickets-app-2 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none - < onsale.js; echo "exit code $?"
ok      http_req_duration{kind:read} p(95)<100  (was 16.5 ms)
ok      http_req_duration{kind:sale} p(95)<250  (was 84.5 ms)
ok      http_req_failed rate<0.01  (was 0.06%)
exit code 0
```

**One copy fails the plan**, and not by a little: the 95th percentile of reads was 4.5 s and of
sales 5.1 s, against 100 and 250 ms. The error rate passed, at 0.31%, which is the trap of a test
with only an error threshold: a box office that answers everything in five seconds is not failing,
by that measure. **Three copies pass**, with reads at 16.5 ms and sales at 84.5 ms at the 95th
percentile, and exit code 0.

The plan said three copies at 70% busy, four with one spare. The test confirms the first half on
this machine. The second half, N + 1, is a test of its own: run the same load with three copies and
stop one in the middle, `docker compose stop` on one container, and see whether the thresholds hold.
That is a spike test and a failure test at once, and it is the kind of test that finds out whether
the spare copy is really a spare.
