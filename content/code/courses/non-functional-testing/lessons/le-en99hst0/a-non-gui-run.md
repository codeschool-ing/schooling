---
title: A run without the window
version: 1
---

With the box office running in its own terminal, as in lesson 2, the plan runs from `~/loadtest`
with one command. Each option has a job:

| option | what it does |
|---|---|
| `-n` | non-GUI mode |
| `-t plan.jmx` | the test plan to run |
| `-l results.jtl` | write every sample to this file |
| `-e -o report/` | when the run ends, build an HTML report from the samples, in `report/` |

```
ana@nft:~/loadtest$ jmeter -n -t plan.jmx -l results.jtl -e -o report/
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using plan.jmx
Starting standalone test @ 2026 Oct 10 16:52:02 BRT (1791661922743)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary +      1 in 00:00:02 =    0.6/s Avg:    28 Min:    28 Max:    28 Err:     0 (0.00%) Active: 7 Started: 7 Finished: 0
summary +    326 in 00:00:25 =   12.8/s Avg:     8 Min:     1 Max:    32 Err:     0 (0.00%) Active: 20 Started: 20 Finished: 0
summary =    327 in 00:00:27 =   12.0/s Avg:     8 Min:     1 Max:    32 Err:     0 (0.00%)
summary +     35 in 00:00:03 =   12.2/s Avg:     8 Min:     1 Max:    23 Err:     0 (0.00%) Active: 0 Started: 20 Finished: 20
summary =    362 in 00:00:30 =   12.0/s Avg:     8 Min:     1 Max:    32 Err:     0 (0.00%)
Tidying up ...    @ 2026 Oct 10 16:52:32 BRT (1791661952869)
... end of run
```

## The summary lines

While a non-GUI test runs, JMeter's **summariser** prints a line every 30 seconds, and once more at
the end. A `summary +` line covers only the period since the last one; a `summary =` line is the
running total since the start. **The last `summary =` is the whole run**: 362 samples in 30
seconds, 12.0 a second, an average of 8 ms, a slowest of 32 ms and no errors. `Active`,
`Started` and `Finished` count the threads, and the first `summary +` shows the ramp at work, with
7 of the 20 started after two seconds.

Twenty users thinking 1.5 seconds on average, against responses of a few milliseconds, should send
about 20 / 1.5 ≈ 13 requests a second by lesson 3's law, and the run measured 12.0, the ramp
accounting for some of the gap. The summary is enough to know the run happened and roughly how it
went. **It is not enough to judge a requirement**: an average across two operations is two
numbers blurred into one, which is the reason lesson 1's requirement names a percentile of one
operation.

## The results file

Every sample went into `results.jtl`, one CSV line each:

```
ana@nft:~/loadtest$ head -4 results.jtl
timeStamp,elapsed,label,responseCode,responseMessage,threadName,dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,URL,Latency,IdleTime,Connect
1791661924518,28,GET /shows,200,OK,visitors 1-3,text,true,,1745,124,7,7,http://127.0.0.1:8000/shows,28,0,17
1791661924519,27,GET /shows,200,OK,visitors 1-1,text,true,,1745,124,7,7,http://127.0.0.1:8000/shows,27,0,17
1791661924837,3,GET /shows,200,OK,visitors 1-2,text,true,,1745,124,8,8,http://127.0.0.1:8000/shows,2,0,1
ana@nft:~/loadtest$ ls report
content
index.html
sbadmin2-1.0.7
statistics.json
ana@nft:~/loadtest$ jq -c '.["GET /shows/{id}"] | {sampleCount, errorCount, medianResTime, pct2ResTime, throughput}' report/statistics.json
{"sampleCount":176,"errorCount":0,"medianResTime":13.0,"pct2ResTime":27.0,"throughput":6.460375142238373}
```

The columns that matter most are `elapsed`, the milliseconds from just before sending to the last
byte of the answer; `label`, the sampler's name; `responseCode` and `success`; `Latency`, the
time to the first byte; and `Connect`, the time spent opening the connection. In the first two
lines `Connect` is 17 ms of a 28 ms sample, because each thread opened its connection then. The
third line, a thread's later request on a connection it kept, spent 1 ms connecting.

The `report/` directory is the same samples as an HTML dashboard: graphs over time, a table per
sampler, and the percentiles lesson 8 explains. `statistics.json` holds the table, and `jq`
reads one row of it: 176 samples of `GET /shows/{id}`, a median of 13 ms, and a `pct2ResTime`, the
95th percentile, of 27 ms. That last number is what a requirement would be judged on.

To read the dashboard, open `report/index.html` in a browser on your own computer, after copying the
directory out of the VM with `multipass transfer --recursive nft:loadtest/report .`. That was not
run here. JMeter refuses to write into a report directory that already has files in it, so delete
`report/` before the next run with `-e -o report/`.

## When an assertion fails

An assertion turns a wrong answer into an error, even when the server answered quickly and with a
status that looked fine. To see one fail, add a show that does not exist to the data file and run
the plan for ten seconds, with `-Jseconds=10` setting the property the thread group reads:

```
ana@nft:~/loadtest$ echo 1001 >> shows.csv
ana@nft:~/loadtest$ jmeter -n -t plan.jmx -l broken.jtl -Jseconds=10
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using plan.jmx
Starting standalone test @ 2026 Oct 10 16:52:38 BRT (1791661958983)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary =     87 in 00:00:10 =    8.8/s Avg:    43 Min:     1 Max:   410 Err:     2 (2.30%)
Tidying up ...    @ 2026 Oct 10 16:52:49 BRT (1791661969186)
... end of run
ana@nft:~/loadtest$ grep -m 2 ",false," broken.jtl
1791661965678,53,GET /shows/{id},404,Not Found,visitors 1-17,text,false,"Test failed: text expected to contain /""left""/",235,129,20,20,http://127.0.0.1:8000/shows/1001,53,0,0
1791661968882,29,GET /shows/{id},404,Not Found,visitors 1-3,text,false,"Test failed: text expected to contain /""left""/",235,129,5,5,http://127.0.0.1:8000/shows/1001,29,0,0
ana@nft:~/loadtest$ sed -i '/1001/d' shows.csv
```

**`Err: 2 (2.30%)` in the summary is the assertion at work**: twice in those ten seconds a thread
read `1001` from the file, the box office answered `404`, and the body had no `"left"` in it. In
the `.jtl` the failed samples carry `false` and the assertion's own message. A 404 is marked as
failed even without an assertion, because JMeter treats any status from 400 up as a failure. The
assertion is what catches the answer that is *wrong* with a `200`, like an empty list or an error
page served as success. The last command takes `1001` out of the file again.

## Why the plan has no listener

A listener receives every sample as it is produced, and some keep all of them in memory. The
*View Results Tree* keeps every request and response body, which is exactly what makes it useful
for debugging one user and ruinous for a thousand. **In a load run, the `.jtl` written with `-l`
is the listener**: it writes each sample to disk and holds nothing, and the report and any other
analysis are built from that file after the run. A plan meant for load runs carries no listeners,
or has them disabled, and the ones in the GUI are for building it.
