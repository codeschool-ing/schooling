---
title: Thresholds and a baseline for the back end
version: 1
---

A page budget says nothing about the server behind it. The back end gets its gate from k6, which
lesson 5 introduced. **A threshold is a pass-or-fail condition on a metric, checked at the end of
the run, and a failed threshold makes k6 exit with a non-zero code.** That exit code is the whole
contract with a pipeline.

There are two kinds of limit worth putting in a threshold, and they catch different things.

- **The requirement.** Lesson 1 wrote `GET /shows/{id}` at under 200 ms at the 95th percentile.
  It is absolute, and it holds whatever the last version did.
- **The baseline.** The 95th percentile the last accepted version reached, with a tolerance. It
  catches a change that makes an endpoint several times slower while it is still well under 200 ms,
  which the requirement would let through for months, one release at a time.

## The script

`perf/api.js` checks both:

```schooling-example
{"language": "javascript", "file": "boxoffice/perf/api.js", "parts": [{"code": "// boxoffice/perf/api.js\n// The back end's half of the gate: 20 requests a second for 15 seconds on\n// GET /shows/{id}, judged against the requirement and against the baseline,\n// the 95th percentile of the last version somebody accepted.\nimport http from \"k6/http\";\n", "note": "The same `k6/http` module lesson 5 used. The load is small on purpose: the gate runs on every pull request, and its job is to notice a change, not to find the breaking point."}, {"code": "const TOLERANCE = 0.5;          // 50% slower than the baseline fails...\nconst SLACK_MS = 5;             // ...plus 5 ms, the noise of a fast endpoint\nconst thresholds = [\"p(95)<200\"];\ntry {\n  const baseline = JSON.parse(open(\"./baseline.json\"));\n  const limit = baseline.p95_ms * (1 + TOLERANCE) + SLACK_MS;\n  thresholds.push(`p(95)<${limit.toFixed(1)}`);\n} catch (e) {\n  console.warn(\"no baseline.json yet: judging against the requirement alone\");\n}\n", "note": "Two thresholds on the 95th percentile. `p(95)<200` is the requirement, and it never moves. The second comes from `baseline.json`: the baseline's 95th percentile, 50% more, plus 5 ms. Without a baseline the script warns and keeps only the requirement, which is how the first baseline gets recorded."}, {"code": "export const options = {\n  scenarios: {\n    shows: { executor: \"constant-arrival-rate\", rate: 20, timeUnit: \"1s\",\n             duration: \"15s\", preAllocatedVUs: 10 },\n  },\n  thresholds: {\n    http_req_failed: [\"rate<0.01\"],\n    http_req_duration: thresholds,\n  },\n};\n", "note": "A constant arrival rate, so every run sends the same 300 requests whatever the server does, and `thresholds` holds both lists. When any threshold fails at the end of the run, k6 exits with code 99."}, {"code": "export default function () {\n  const id = 981 + Math.floor(Math.random() * 20);\n  http.get(`http://127.0.0.1:8000/shows/${id}`);\n}", "note": "Each iteration asks for one of the twenty shows on sale, at random, so the test counts the bookings of all twenty rather than of one show."}]}
```

## A faster box office to start from

**A baseline is only interesting on a version worth keeping.** Lesson 9 traced the time of `GET /shows/{id}`
to the database, which counts one show's bookings among nearly three hundred thousand rows with no
index, so this lesson starts from the obvious fix: an index on `bookings.show_id`. It changes the database, not `app.py`: run `python3 seed.py` again whenever you
want the original back.

```
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=12.7, pay;dur=0.0, total;dur=13.1
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "CREATE INDEX bookings_show ON bookings(show_id)"
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=0.2, pay;dur=0.0, total;dur=0.5
```

The database's share of the request, the `db` in `Server-Timing`, fell from 12.7 ms to 0.2 ms.

## The first run, and the baseline

With no `baseline.json`, the script warns and judges against the requirement alone:

```
ana@nft:~/boxoffice$ k6 run --quiet perf/api.js; echo "exit $?"
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:51-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=1.19ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=841.88µs min=562.81µs med=780.16µs max=4.66ms p(90)=1ms   p(95)=1.19ms
      { expected_response:true }...: avg=841.88µs min=562.81µs med=780.16µs max=4.66ms p(90)=1ms   p(95)=1.19ms
    http_req_failed................: 0.00% 0 out of 301
    http_reqs......................: 301   20.064104/s

    EXECUTION
    iteration_duration.............: avg=1ms      min=691.38µs med=930.22µs max=4.78ms p(90)=1.2ms p(95)=1.7ms 
    iterations.....................: 301   20.064104/s
    vus............................: 0     min=0        max=0 
    vus_max........................: 10    min=10       max=10

    NETWORK
    data_received..................: 96 kB 6.4 kB/s
    data_sent......................: 24 kB 1.6 kB/s



exit 0
```

The warning appears twelve times because every virtual user runs the top level of the script,
and k6 runs it a few more times of its own while it reads the options. The two thresholds that
exist were met, and the exit code is 0.

**A baseline recorded from one run carries that run's noise into every later comparison**, so
this one is the median of three. `jq -s` reads the three summaries into one array:

```
ana@nft:~/boxoffice$ mkdir -p perf/runs
ana@nft:~/boxoffice$ for i in 1 2 3; do k6 run --quiet --summary-export=perf/runs/base-$i.json perf/api.js > /dev/null 2>&1; done
ana@nft:~/boxoffice$ jq -s '{p95_ms: (map(.metrics.http_req_duration["p(95)"]) | sort | .[1])}' perf/runs/base-*.json > perf/baseline.json
ana@nft:~/boxoffice$ cat perf/baseline.json
{
  "p95_ms": 3.177051450000001
}
```

The median of the three is 3.177 ms; the next section looks at how far apart they were. Run the
script again, and the second threshold appears beside the first, computed from the baseline:

```
ana@nft:~/boxoffice$ k6 run --quiet perf/api.js; echo "exit $?"


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=1.32ms
    ✓ 'p(95)<9.8' p(95)=1.32ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=844.47µs min=512.13µs med=735.3µs  max=6.37ms p(90)=971.83µs p(95)=1.32ms
      { expected_response:true }...: avg=844.47µs min=512.13µs med=735.3µs  max=6.37ms p(90)=971.83µs p(95)=1.32ms
    http_req_failed................: 0.00% 0 out of 301
    http_reqs......................: 301   20.064601/s

    EXECUTION
    iteration_duration.............: avg=995.35µs min=596.59µs med=862.87µs max=6.47ms p(90)=1.17ms   p(95)=1.85ms
    iterations.....................: 301   20.064601/s
    vus............................: 0     min=0        max=0 
    vus_max........................: 10    min=10       max=10

    NETWORK
    data_received..................: 96 kB 6.4 kB/s
    data_sent......................: 24 kB 1.6 kB/s



exit 0
```

The 9.8 ms is 3.177 × 1.5 + 5, rounded to one decimal, and this run's 95th percentile, 1.32 ms,
is well inside it.

## A regression the requirement would miss

Now undo the fix, as a migration that forgot the index would:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "DROP INDEX bookings_show"
ana@nft:~/boxoffice$ k6 run --quiet perf/api.js; echo "exit $?"


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=33.4ms
    ✗ 'p(95)<9.8' p(95)=33.4ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=16.21ms min=7.89ms med=12.55ms max=77.15ms p(90)=27.04ms p(95)=33.4ms 
      { expected_response:true }...: avg=16.21ms min=7.89ms med=12.55ms max=77.15ms p(90)=27.04ms p(95)=33.4ms 
    http_req_failed................: 0.00% 0 out of 301
    http_reqs......................: 301   20.050534/s

    EXECUTION
    iteration_duration.............: avg=16.41ms min=8.05ms med=12.72ms max=77.29ms p(90)=27.36ms p(95)=33.61ms
    iterations.....................: 301   20.050534/s
    vus............................: 0     min=0        max=1 
    vus_max........................: 10    min=10       max=10

    NETWORK
    data_received..................: 97 kB 6.4 kB/s
    data_sent......................: 24 kB 1.6 kB/s



time="2026-10-10T16:43:06-03:00" level=error msg="thresholds on metrics 'http_req_duration' have been crossed"
exit 99
```

The 95th percentile went to 33.4 ms, about ten times the baseline. The requirement passed and the
baseline did not. **The endpoint got many times slower and stayed
under 200 ms, and only the comparison with the last good version noticed.** k6 says which
threshold crossed, in its summary and in the error line under it, and exits with 99.
