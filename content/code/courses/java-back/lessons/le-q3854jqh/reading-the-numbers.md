---
title: Reading the numbers, and what they cannot say
version: 1
---

The two runs of the last section sent the same 20000 requests to the same application, and they
did not agree. COLD-WARM-SENTENCE

**The first run after a start measures a different program.** At start-up the JVM interprets most
of the bookshop's code and compiles the methods that turn out to be hot as the load goes on;
Hibernate builds its query plans on first use; the connection pool and Tomcat's threads fill up.
A load test therefore warms the application up first and throws that run away, and only then
measures.

## The average hides the slow requests

The report keeps every number per label and in total, in `statistics.json`. The total of the warm
run:

```
ana@vm:~/bookshop$ python3 -c 'import json; print(json.dumps(json.load(open("target/jmeter/report/statistics.json"))["Total"], indent=1))'
{
 "transaction": "Total",
 "sampleCount": 20000,
 "errorCount": 0,
 "errorPct": 0.0,
 "meanResTime": 8.127700000000011,
 "medianResTime": 5.0,
 "minResTime": 0.0,
 "maxResTime": 167.0,
 "pct1ResTime": 18.0,
 "pct2ResTime": 24.0,
 "pct3ResTime": 41.0,
 "throughput": 2114.611968703743,
 "receivedKBytesPerSec": 1065.7832241885176,
 "sentKBytesPerSec": 269.489122964686
}
```

`pct1ResTime`, `pct2ResTime` and `pct3ResTime` are percentiles, and JMeter's own settings say which:

```
ana@vm:~/bookshop$ grep aggregate_rpt_pct ~/opt/apache-jmeter-5.6.3/bin/jmeter.properties
#aggregate_rpt_pct1=90
#aggregate_rpt_pct2=95
#aggregate_rpt_pct3=99
```

A **percentile** sorts every response time and reads one position: the 95th percentile is the
time that 95% of the requests stayed at or under. TOTAL-SENTENCE

The average is a poor summary of response time, because response times are lopsided: most are
short, and a few are many times longer, and the few are what people feel. A page that makes ten
requests is held up by its slowest one, so a user who loads it is far more likely than one request
in a hundred to wait as long as the 99th percentile. That is why a goal for a service is written
as a percentile, such as "95% of searches answer in under 50 ms", and never as an average.

## Twenty threads is a choice, and it shapes the answer

Each thread of the plan sends a request, **waits for the answer**, and only then sends the next.
That is a **closed model**: the load is a number of users, not a number of requests a second, and
it slows down when the application slows down. It follows that the rate a run can reach is about
the number of threads divided by the response time. Twenty threads at 5 ms each can never exceed
4000 requests a second, whatever the server could do.

So the honest way to see what the bookshop does under more load is to add threads and watch both
numbers. The plan reads `threads` and `loops` as properties, so one loop in the shell can run it six
times, each with the same 20000 requests:

```
ana@vm:~/bookshop$ for t in 1 5 10 20 50 100; do printf "%3d threads  " $t; jmeter -n -t src/test/jmeter/books.jmx -Jthreads=$t -Jloops=$((10000 / t)) -l target/jmeter/sweep.jtl -j target/jmeter/sweep.log -f | grep "summary ="; done
  1 threads  summary =  20000 in 00:00:17 = 1162.7/s Avg:     0 Min:     0 Max:    18 Err:     0 (0.00%)
  5 threads  summary =  20000 in 00:00:07 = 2705.6/s Avg:     1 Min:     0 Max:    47 Err:     0 (0.00%)
 10 threads  summary =  20000 in 00:00:06 = 3194.9/s Avg:     2 Min:     0 Max:    75 Err:     0 (0.00%)
 20 threads  summary =  20000 in 00:00:05 = 3649.0/s Avg:     3 Min:     0 Max:   110 Err:     0 (0.00%)
 50 threads  summary =  20000 in 00:00:04 = 4663.1/s Avg:     4 Min:     0 Max:    34 Err:     0 (0.00%)
100 threads  summary =  20000 in 00:00:04 = 4480.3/s Avg:     6 Min:     0 Max:   269 Err:     0 (0.00%)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Two bar charts over the same six runs of 1, 5, 10, 20, 50 and 100 threads. Requests a second: 1 threads 1162.7, 5 threads 2705.6, 10 threads 3194.9, 20 threads 3649.0, 50 threads 4663.1, 100 threads 4480.3. Average response time in milliseconds: 1 threads 0, 5 threads 1, 10 threads 2, 20 threads 3, 50 threads 4, 100 threads 6.\"><defs><marker id=\"l20s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requests a second</text><polyline points=\"20,240 330,240\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></polyline><rect x=\"32\" y=\"192.62529218760054\" width=\"34\" height=\"47.37470781239947\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"49\" y=\"183.62529218760054\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1163</text><text x=\"49\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"82\" y=\"129.75917308228432\" width=\"34\" height=\"110.24082691771568\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"99\" y=\"120.75917308228432\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2706</text><text x=\"99\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"132\" y=\"109.82243571872789\" width=\"34\" height=\"130.1775642812721\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"149\" y=\"100.82243571872789\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3195</text><text x=\"149\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><rect x=\"182\" y=\"91.31993738071242\" width=\"34\" height=\"148.68006261928758\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"199\" y=\"82.31993738071242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3649</text><text x=\"199\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"232\" y=\"50.0\" width=\"34\" height=\"190.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"249\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4663</text><text x=\"249\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><rect x=\"282\" y=\"57.44826403036609\" width=\"34\" height=\"182.5517359696339\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"299\" y=\"48.44826403036609\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4480</text><text x=\"299\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><text x=\"175\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">threads</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">average response time, ms</text><polyline points=\"370,240 680,240\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></polyline><rect x=\"382\" y=\"240.0\" width=\"34\" height=\"0.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"399\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"399\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"432\" y=\"208.33333333333334\" width=\"34\" height=\"31.666666666666668\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"449\" y=\"199.33333333333334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><text x=\"449\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"482\" y=\"176.66666666666666\" width=\"34\" height=\"63.333333333333336\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"499\" y=\"167.66666666666666\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2</text><text x=\"499\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><rect x=\"532\" y=\"145.0\" width=\"34\" height=\"95.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"549\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><text x=\"549\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"582\" y=\"113.33333333333333\" width=\"34\" height=\"126.66666666666667\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"599\" y=\"104.33333333333333\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4</text><text x=\"599\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><rect x=\"632\" y=\"50.0\" width=\"34\" height=\"190.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"649\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6</text><text x=\"649\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><text x=\"525\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">threads</text></svg>", "caption": "Each run sent the same 20000 requests. More threads bought less and less throughput, and from twenty on, each extra thread mostly waited in line."}
```

SWEEP-SENTENCE

## One computer, measuring itself

```
ana@vm:~/bookshop$ nproc
4
```

Four processors, and during these runs they held the bookshop, PostgreSQL and JMeter at once.
JMeter is not free: the `time` of the warm run in the last section reported USER-SECONDS of
processor time used by JMeter itself in REAL-SECONDS of elapsed time, CPU-SENTENCE. When the
generator and the application share the processors, adding threads adds work to both, and nothing
in the results says which of them ran out first.

**What a run on one computer measures is that computer, with that load generator on it.** It is
good for one thing, and that thing is valuable: comparing two versions of your code with the same
plan on the same machine, to see whether a change made the catalogue slower. It cannot say what a
production server will sustain, which has other processors, a network between the client and the
server, a database with more than six books in it, and no JMeter beside it. A load test that
answers that question runs the generator on separate machines, against an environment shaped like
production.

## Read the errors first

Stop the application in the second terminal with Ctrl+C, and run the plan once more, a short one:

```
ana@vm:~/bookshop$ jmeter -n -t src/test/jmeter/books.jmx -Jloops=50 -l target/jmeter/down.jtl -j target/jmeter/down.log -f | grep "summary ="
summary =   2000 in 00:00:02 =  995.0/s Avg:     1 Min:     0 Max:    17 Err:  2000 (100.00%)
ana@vm:~/bookshop$ cut -d, -f4,5 target/jmeter/down.jtl | sort | uniq -c
   2000 Non HTTP response code: org.apache.http.conn.HttpHostConnectException,Non HTTP response message: Connect to localhost:8080 [localhost/127.0.0.1] failed: Connection refused
      1 responseCode,responseMessage
```

DOWN-SENTENCE A connection that is refused fails at once, so a run against a stopped server is the
fastest run there is. **Read `Err` before any time**: a throughput figure means something only when
the requests behind it succeeded.

Load testing is a subject of its own. The `non-functional-testing` course, in the QA track, spends
lessons 3, 4 and 8 on modelling a load, on JMeter in depth, including runs spread over several
machines, and on reading results.
