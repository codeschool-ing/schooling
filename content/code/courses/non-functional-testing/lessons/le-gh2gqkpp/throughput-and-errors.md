---
title: Throughput, and what counts as an error
version: 1
---

Response time is one of three numbers a load test report leads with. The other two are
**throughput**, the requests the system completed per second, and the **error rate**, the share
of them that failed. Each one alone can be made to look good; read together they say whether the
system kept up.

## Throughput stops rising

Throughput is completed requests divided by elapsed time, which `measure.py` prints on its first
line. To see how it behaves, run the generator with more and more workers, looks at a show only,
five seconds each. The `sed` keeps two lines of each report, the first and the `all` row:

```
ana@nft:~/boxoffice$ for w in 1 2 4 8 16 32; do python3 measure.py $w 5 | sed -n "1p;4p"; done
1 workers, 5.0 s: 232 requests, 46.3 per second
all           232    21.6    19.6    29.5    31.1    36.1    38.7
2 workers, 5.0 s: 332 requests, 66.1 per second
all           332    30.2    28.2    43.7    51.4    61.8    68.2
4 workers, 5.0 s: 404 requests, 80.3 per second
all           404    49.7    48.3    71.5    78.6    84.0   116.4
8 workers, 5.1 s: 492 requests, 97.1 per second
all           492    81.8    78.8   119.4   133.0   155.5   197.6
16 workers, 5.1 s: 527 requests, 102.4 per second
all           527   153.6   129.7   204.0   226.7  1172.1  1255.3
32 workers, 6.0 s: 584 requests, 96.6 per second
all           584   289.0   167.2  1060.1  1214.1  1459.0  2456.7
```

From one worker to eight, throughput climbs, from 46.3 to 97.1 requests a second. From eight to
thirty-two it stays where it is: 102.4 with sixteen workers, 96.6 with thirty-two. **Four times
the workers bought no more answers per second**, and the response times paid for them: the
median went from 78.8 ms with eight workers to 167.2 ms with thirty-two, and the p95 from 133.0
to 1214.1 ms.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-load\" aria-label=\"Two charts of the same six runs, with 1, 2, 4, 8, 16 and 32 workers along the bottom of each. On the left, throughput in requests per second climbs from 46.3 with one worker to 97.1 with eight, then stays flat: 102.4 with sixteen and 96.6 with thirty-two. On the right, response time: the median rises from 19.6 to 167.2 ms, and the 95th percentile from 31.1 ms to 1214.1 ms, most of that rise after the throughput stopped growing.\"><text x=\"205.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">throughput, requests per second</text><path d=\"M70.0 240.0 L340.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 240.0 L70.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 240.0 L340.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 180.0 L340.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><path d=\"M70.0 120.0 L340.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M70.0 60.0 L340.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"64.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">120</text><text x=\"90.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"136.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"182.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"228.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"274.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"320.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32</text><text x=\"205.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workers</text><path d=\"M90.0 170.6 L136.0 140.9 L182.0 119.5 L228.0 94.4 L274.0 86.4 L320.0 95.1\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"90.0\" cy=\"170.6\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"136.0\" cy=\"140.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"182.0\" cy=\"119.5\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"228.0\" cy=\"94.4\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"274.0\" cy=\"86.4\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"320.0\" cy=\"95.1\" r=\"3\" fill=\"var(--phosphor)\"></circle><text x=\"222.0\" y=\"82.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">flat from 8</text><text x=\"555.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">response time, ms</text><path d=\"M420.0 240.0 L690.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420.0 240.0 L420.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M420.0 240.0 L690.0 240.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M420.0 182.4 L690.0 182.4\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"182.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><path d=\"M420.0 124.8 L690.0 124.8\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"124.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">800</text><path d=\"M420.0 67.2 L690.0 67.2\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"414.0\" y=\"67.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1200</text><text x=\"440.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"486.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"532.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"578.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"624.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"670.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32</text><text x=\"555.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workers</text><path d=\"M440.0 237.2 L486.0 235.9 L532.0 233.0 L578.0 228.7 L624.0 221.3 L670.0 215.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"440.0\" cy=\"237.2\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"486.0\" cy=\"235.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"532.0\" cy=\"233.0\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"578.0\" cy=\"228.7\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"624.0\" cy=\"221.3\" r=\"3\" fill=\"var(--phosphor)\"></circle><circle cx=\"670.0\" cy=\"215.9\" r=\"3\" fill=\"var(--phosphor)\"></circle><text x=\"664.0\" y=\"203.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">median</text><path d=\"M440.0 235.5 L486.0 232.6 L532.0 228.7 L578.0 220.8 L624.0 207.4 L670.0 65.2\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"440.0\" cy=\"235.5\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"486.0\" cy=\"232.6\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"532.0\" cy=\"228.7\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"578.0\" cy=\"220.8\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"624.0\" cy=\"207.4\" r=\"3\" fill=\"var(--amber)\"></circle><circle cx=\"670.0\" cy=\"65.2\" r=\"3\" fill=\"var(--amber)\"></circle><text x=\"664.0\" y=\"53.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">p95</text></svg>", "caption": "Past eight workers the box office answers no more requests a second. Every worker added after that only waits longer."}
```

This shape is the most common one in performance testing, and it has a simple reason. A worker
here sends a request, waits for the answer, and sends the next, so at any moment the number of
requests inside the system is the number of workers. If the system completes X requests a second
and each one spends R seconds inside it, then

> requests inside the system = X × R

which is **Little's law**, and it holds for any system that is not filling up or emptying. Check
it on the row with eight workers: 97.1 requests a second × 0.0818 s of mean response time is
about 7.9 requests inside, for eight workers. With sixteen, 102.4 × 0.1536 is about 15.7.

Once X cannot grow, because something in the box office is fully busy, every extra worker raises
R instead: it joins a queue. That is why latency against load is flat and then steep, and why the
point where it turns, here around eight workers, is the most useful number a test can find. **A
requirement of 50 requests a second is comfortable on this machine; one of 150 cannot be met by
adding workers**, only by finding what is busy, which is the subject of lesson 9.

The generator is part of that sentence too. `measure.py` runs on the same four processors as the
box office, and every thread it starts takes time from the server. Lesson 9 shows how to tell a
busy server from a busy generator.

## What counts as an error

An error rate is a count divided by a count, and everything depends on what goes on top. k6, from
lesson 5, counts a response as failed when its status is 400 or above, or when no response
arrived at all. Here is the same mixed load as `measure.py`, written for k6:

```javascript
// boxoffice/mix.js
// Eight virtual users for ten seconds: one request in five books a seat,
// the rest look at a show. A fresh connection for every request.
import http from 'k6/http';

export const options = { vus: 8, duration: '10s', noConnectionReuse: true };

export default function () {
  const show = 981 + Math.floor(Math.random() * 20);
  if (Math.random() < 0.2) {
    http.post('http://127.0.0.1:8000/bookings', JSON.stringify({
      show_id: show, seat: 1 + Math.floor(Math.random() * 300), customer: `vu${__VU}`,
    }));
  } else {
    http.get(`http://127.0.0.1:8000/shows/${show}`);
  }
}
```

`noConnectionReuse` makes k6 open a fresh connection for every request, as `measure.py` does, so
the two measure the same thing; lesson 9 shows what changes on this server when a connection is
kept. k6 prints a long summary, and the `grep` keeps its HTTP lines:

```
ana@nft:~/boxoffice$ k6 run mix.js 2>&1 | grep -E "http_req_(duration|failed)|expected_resp|http_reqs"
    http_req_duration..............: avg=104.68ms min=16.12ms med=31.3ms  max=1.18s p(90)=409.95ms p(95)=479.66ms
      { expected_response:true }...: avg=95.05ms  min=16.12ms med=30.53ms max=1.18s p(90)=401.95ms p(95)=475.68ms
    http_req_failed................: 3.28%  25 out of 761
    http_reqs......................: 761    74.113918/s
```

`http_req_failed` says 3.28%, 25 of 761 requests. **None of them is a fault.** The only status
this script can receive at 400 or above is a 409: a random seat that somebody already holds. The
box office refusing to sell a seat twice is the behaviour a booking test exists to see, and
counting it as a failure would make a release fail its error budget for working correctly.

The fix is to tell k6 which answers this test expects. `http.expectedStatuses` takes a range and
single codes:

```javascript
// boxoffice/mix-expected.js
// Eight virtual users for ten seconds: one request in five books a seat,
// the rest look at a show. A 409, a seat somebody already has, is an
// answer this test expects, so it is not counted as a failure.
import http from 'k6/http';

http.setResponseCallback(http.expectedStatuses({ min: 200, max: 299 }, 409));

export const options = { vus: 8, duration: '10s', noConnectionReuse: true };

export default function () {
  const show = 981 + Math.floor(Math.random() * 20);
  if (Math.random() < 0.2) {
    http.post('http://127.0.0.1:8000/bookings', JSON.stringify({
      show_id: show, seat: 1 + Math.floor(Math.random() * 300), customer: `vu${__VU}`,
    }));
  } else {
    http.get(`http://127.0.0.1:8000/shows/${show}`);
  }
}
```

```
ana@nft:~/boxoffice$ k6 run mix-expected.js 2>&1 | grep -E "http_req_(duration|failed)|expected_resp|http_reqs"
    http_req_duration..............: avg=115.02ms min=16.15ms med=32.64ms max=720.76ms p(90)=439.33ms p(95)=522.86ms
      { expected_response:true }...: avg=115.02ms min=16.15ms med=32.64ms max=720.76ms p(90)=439.33ms p(95)=522.86ms
    http_req_failed................: 0.00%  0 out of 704
    http_reqs......................: 704    67.995409/s
```

Now `http_req_failed` is 0.00%, 0 of 704. The two runs differ in their timings, as any two runs
do; the line that changed because of the script is the failure count. The second line of each
summary, `{ expected_response:true }`, is the response time of the expected answers alone. In the
first run it left the 409s out; in the second it covers everything, so it equals the line above.

The same summary line is worth reading once with this lesson in mind. `avg`, `min`, `med`, `max`,
`p(90)` and `p(95)` are k6's default statistics, so **the mean comes first and there is no p99**.
`--summary-trend-stats "med,p(95),p(99),max"` on the command line, or `summaryTrendStats` in the
options, chooses others.

Three rules hold for any error rate you write into a requirement:

- **Decide what is expected before the run.** A 409 in a test that books random seats is a
  correct answer. The same 409 in a test that books only seats it knows are free is a defect.
- **Count the requests that got no answer.** A timeout, a refused connection or a reset never
  produces a status code. `measure.py` records them as `failed`, and k6 counts them as failed; a
  homemade script that only counts status codes misses exactly the failures that matter most.
- **Read latency for the successful answers apart from the failed ones.** A server that answers
  503 in a millisecond while it is falling over makes its own percentiles look better; an error
  rate rising while response times fall is a warning, not good news.
