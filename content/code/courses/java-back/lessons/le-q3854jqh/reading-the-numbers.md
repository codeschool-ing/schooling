---
title: Reading the numbers, and what they cannot say
version: 1
---

The two runs of the last section sent the same 20000 requests to the same application, and they
did not agree. The first took 11 seconds at 1878.3 requests a second, with an average of 9 ms; the
second took 7 seconds at 2787.8 a second, with an average of 5 ms. Inside the first run, the first
`summary +` line, covering its first three seconds, managed only 837.9 a second.

**The first run after a start measures a different program.** At start-up the JVM interprets most
of the bookshop's code. It compiles to machine code the methods that turn out to be busy as the
load goes on, and it loads many classes only when the first request needs them. A load test
therefore warms the application up first, throws that run away, and only then measures.

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
 "meanResTime": 5.726850000000034,
 "medianResTime": 4.0,
 "minResTime": 0.0,
 "maxResTime": 103.0,
 "pct1ResTime": 13.0,
 "pct2ResTime": 17.0,
 "pct3ResTime": 26.0,
 "throughput": 2821.272393849626,
 "receivedKBytesPerSec": 1422.040308929327,
 "sentKBytesPerSec": 359.5469212865002
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
time that 95% of the requests stayed at or under. In this run the median was 4 ms and the mean
5.7, while one request in ten took 13 ms or more, one in a hundred 26 ms or more, and the slowest
103 ms, eighteen times the mean.

The average is a poor summary of response time, because response times are lopsided: most are
short, a few are many times longer, and the few are what people feel. A page that makes ten
requests waits for the slowest of them, so somebody loading it meets the slow tail far more often
than one request in a hundred would suggest. That is why a goal for a service is written as a
percentile, such as "95% of searches answer in under 50 ms", and not as an average.

## Twenty threads is a choice, and it shapes the answer

Each thread of the plan sends a request, **waits for the answer**, and only then sends the next.
That is a **closed model**: the load is a number of users, not a number of requests a second, and
it slows down when the application slows down. So the rate a run can reach is at most the number of
threads divided by the response time. The warm run had twenty threads and an average of 5 ms, so it
could not have passed 4000 requests a second, whatever the server could do; it reached 2787.8.

To see what the bookshop does under more load, add threads and watch both numbers. The plan reads
`threads` and `loops` as properties, so one loop in the shell can run it six times, each run with
the same 20000 requests:

```
ana@vm:~/bookshop$ for t in 1 5 10 20 50 100; do printf "%3d threads  " $t; jmeter -n -t src/test/jmeter/books.jmx -Jthreads=$t -Jloops=$((10000 / t)) -l target/jmeter/sweep.jtl -j target/jmeter/sweep.log -f | grep "summary ="; done
  1 threads  summary =  20000 in 00:00:15 = 1356.2/s Avg:     0 Min:     0 Max:    19 Err:     0 (0.00%)
  5 threads  summary =  20000 in 00:00:06 = 3629.1/s Avg:     0 Min:     0 Max:    18 Err:     0 (0.00%)
 10 threads  summary =  20000 in 00:00:05 = 4088.3/s Avg:     1 Min:     0 Max:    24 Err:     0 (0.00%)
 20 threads  summary =  20000 in 00:00:04 = 4447.4/s Avg:     2 Min:     0 Max:    24 Err:     0 (0.00%)
 50 threads  summary =  20000 in 00:00:04 = 4934.6/s Avg:     4 Min:     0 Max:    39 Err:     0 (0.00%)
100 threads  summary =  20000 in 00:00:04 = 4904.4/s Avg:     5 Min:     0 Max:    65 Err:     0 (0.00%)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Two bar charts over the same six runs of 1, 5, 10, 20, 50 and 100 threads. Requests a second: 1 threads 1356.2, 5 threads 3629.1, 10 threads 4088.3, 20 threads 4447.4, 50 threads 4934.6, 100 threads 4904.4. Average response time in milliseconds: 1 threads 0, 5 threads 0, 10 threads 1, 20 threads 2, 50 threads 4, 100 threads 5.\"><defs><marker id=\"l20s-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requests a second</text><polyline points=\"20,240 330,240\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></polyline><rect x=\"32\" y=\"187.7813804563693\" width=\"34\" height=\"52.21861954363069\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"49\" y=\"178.7813804563693\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1356.2</text><text x=\"49\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"82\" y=\"100.26648563206746\" width=\"34\" height=\"139.73351436793254\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"99\" y=\"91.26648563206746\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">3629.1</text><text x=\"99\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"132\" y=\"82.5856199084019\" width=\"34\" height=\"157.4143800915981\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"149\" y=\"73.5856199084019\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4088.3</text><text x=\"149\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><rect x=\"182\" y=\"68.75896729218178\" width=\"34\" height=\"171.24103270781822\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"199\" y=\"59.75896729218178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4447.4</text><text x=\"199\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"232\" y=\"50.0\" width=\"34\" height=\"190.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"249\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4934.6</text><text x=\"249\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><rect x=\"282\" y=\"51.162809548899645\" width=\"34\" height=\"188.83719045110035\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"299\" y=\"42.162809548899645\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4904.4</text><text x=\"299\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><text x=\"175\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">threads</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">average response time, ms</text><polyline points=\"370,240 680,240\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></polyline><rect x=\"382\" y=\"240.0\" width=\"34\" height=\"0.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"399\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">0</text><text x=\"399\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"432\" y=\"240.0\" width=\"34\" height=\"0.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"449\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">0</text><text x=\"449\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"482\" y=\"202.0\" width=\"34\" height=\"38.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"499\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1</text><text x=\"499\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><rect x=\"532\" y=\"164.0\" width=\"34\" height=\"76.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"549\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2</text><text x=\"549\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><rect x=\"582\" y=\"88.0\" width=\"34\" height=\"152.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"599\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4</text><text x=\"599\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><rect x=\"632\" y=\"50.0\" width=\"34\" height=\"190.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"649\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">5</text><text x=\"649\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><text x=\"525\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">threads</text></svg>", "caption": "Each run sent the same 20000 requests. Throughput stopped growing at fifty threads while the average kept rising. JMeter prints whole milliseconds, so an average below one can read 0."}
```

From one thread to five, throughput nearly tripled. From fifty to a hundred it did not grow at all,
and the average kept rising: past a point, a thread added to the plan adds a request waiting in a
queue rather than a request answered. Notice also that the run with twenty threads reached 4447.4
a second here, against 2787.8 in the warm run a minute earlier with the same twenty threads. The
JVM was still warming between the two, and on one shared machine two runs of the same plan can
differ that much. Run each point at least twice, and quote it only when the runs agree.

## One computer, measuring itself

```
ana@vm:~/bookshop$ nproc
4
```

Four processors, and during these runs they held the bookshop, PostgreSQL and JMeter at once.
JMeter is not free. The `time` of the warm run in the last section reported 10.744 seconds of
processor time spent by JMeter in user code, in 10.354 seconds of elapsed time: more than one of
the four processors, on average, from start to finish. The six runs above show the same thing from the
other side. With a hundred threads at 4904.4 requests a second, each thread completed a request
about every 20 ms, while the average answer took 5. The rest of those 20 ms was not the bookshop
answering: it was JMeter's own work, and threads waiting for a processor.

**What a run on one computer measures is that computer, with that load generator on it.** It is
good for one valuable thing: comparing two versions of your code with the same
plan on the same machine, to see whether a change made the catalogue slower. It cannot say what a
production server will sustain. That server has other processors, a network between the client and
it, a database with more than six books in it, and no JMeter beside it. A load test that answers
that question runs the generator on separate machines, against an environment shaped like
production.

## Read the errors first

Stop the application in the second terminal with Ctrl+C, and run the plan once more, a short one:

```
ana@vm:~/bookshop$ jmeter -n -t src/test/jmeter/books.jmx -Jloops=50 -l target/jmeter/down.jtl -j target/jmeter/down.log -f | grep "summary ="
summary =   2000 in 00:00:02 = 1031.5/s Avg:     0 Min:     0 Max:    25 Err:  2000 (100.00%)
ana@vm:~/bookshop$ cut -d, -f4,5 target/jmeter/down.jtl | sort | uniq -c
   2000 Non HTTP response code: org.apache.http.conn.HttpHostConnectException,Non HTTP response message: Connect to localhost:8080 [localhost/127.0.0.1] failed: Connection refused
      1 responseCode,responseMessage
```

An average of 0 ms, as low as any run in this lesson, and every one of the 2000 requests failed.
The results file says why: a connection refused at `localhost:8080`. A refused connection fails at once. **Read `Err` before any time**: a response
time means something only when the request behind it succeeded.

Load testing is a subject of its own. The `non-functional-testing` course, in the QA track, spends
lessons 3, 4 and 8 on modelling a load, on JMeter in depth, including runs spread over several
machines, and on reading results.
