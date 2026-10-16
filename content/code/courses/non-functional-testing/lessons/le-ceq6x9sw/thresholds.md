---
title: Thresholds, and the exit code
version: 1
---

A load test that prints numbers still needs somebody to read them. **A threshold turns the run
into a verdict**, and k6 reports that verdict in the one place every script, terminal and pipeline
already looks: the exit code of the program. Zero is a pass, anything else is a fail, and nobody
has to agree afterwards what the numbers meant.

## A run that passes

With the box office running in the first terminal, run the script at its default of three
journeys a second, and print the exit code after it:

```
ana@nft:~$ k6 run -q k6/boxoffice.js; echo "exit $?"


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=127.01ms

      {name:booking}
      ✓ 'p(95)<300' p(95)=134.14ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    checks_total.......: 162     7.461202/s
    checks_succeeded...: 100.00% 162 out of 162
    checks_failed......: 0.00%   0 out of 162

    ✓ show answers 200
    ✓ seats left is a number
    ✓ booked or taken

    HTTP
    http_req_duration..............: avg=55.65ms min=16.84ms med=52.53ms max=179.68ms p(90)=103.28ms p(95)=127.01ms
      { expected_response:true }...: avg=55.65ms min=16.84ms med=52.53ms max=179.68ms p(90)=103.28ms p(95)=127.01ms
      { name:booking }.............: avg=79.55ms min=17.18ms med=71.86ms max=179.68ms p(90)=127.19ms p(95)=134.14ms
    http_req_failed................: 0.00% 0 out of 108
    http_reqs......................: 108   4.974135/s

    EXECUTION
    iteration_duration.............: avg=2.06s   min=1.13s   med=2.06s   max=3.02s    p(90)=2.76s    p(95)=2.87s   
    iterations.....................: 54    2.487067/s
    vus............................: 3     min=1        max=7 
    vus_max........................: 20    min=20       max=20

    NETWORK
    data_received..................: 31 kB 1.4 kB/s
    data_sent......................: 14 kB 629 B/s



exit 0
```

The summary opens with the thresholds, one block per metric, each with a tick and the value that
was compared. Every request together reached a 95th percentile of 127.01 ms against a limit of
200, the bookings alone 134.14 ms against 300, and no request failed. **The exit code is 0**, and
`echo "exit $?"` is there only so that you can see it; a pipeline reads it without being told.

## The same file, ten times the load

`-e RATE=30` changes nothing in the file and asks for thirty journeys a second instead of three:

```
ana@nft:~$ k6 run -q -e RATE=30 k6/boxoffice.js; echo "exit $?"
time="2026-10-10T04:36:07-03:00" level=warning msg="Insufficient VUs, reached 60 active VUs and cannot initialize more" executor=ramping-arrival-rate scenario=visitors


  █ THRESHOLDS 

    http_req_duration
    ✗ 'p(95)<200' p(95)=2.71s

      {name:booking}
      ✗ 'p(95)<300' p(95)=2.76s

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    checks_total.......: 801     33.630389/s
    checks_succeeded...: 100.00% 801 out of 801
    checks_failed......: 0.00%   0 out of 801

    ✓ show answers 200
    ✓ seats left is a number
    ✓ booked or taken

    HTTP
    http_req_duration..............: avg=1s    min=16.66ms med=112.02ms max=2.85s p(90)=2.61s p(95)=2.71s
      { expected_response:true }...: avg=1s    min=16.66ms med=112.02ms max=2.85s p(90)=2.61s p(95)=2.71s
      { name:booking }.............: avg=1.95s min=23.75ms med=2.1s     max=2.85s p(90)=2.71s p(95)=2.76s
    http_req_failed................: 0.00%  0 out of 534
    http_reqs......................: 534    22.42026/s

    EXECUTION
    dropped_iterations.............: 260    10.916231/s
    iteration_duration.............: avg=4.06s min=1.17s   med=4.28s    max=5.91s p(90)=5.21s p(95)=5.54s
    iterations.....................: 267    11.21013/s
    vus............................: 16     min=3        max=60
    vus_max........................: 60     min=20       max=60

    NETWORK
    data_received..................: 152 kB 6.4 kB/s
    data_sent......................: 68 kB  2.8 kB/s



time="2026-10-10T04:36:23-03:00" level=error msg="thresholds on metrics 'http_req_duration, http_req_duration{name:booking}' have been crossed"
exit 99
```

**Two crosses, and the exit code is 99**, which is the code k6 uses for thresholds that were
crossed. The 95th percentile of all requests went from 127.01 ms to 2.71 s, and the bookings
from 134.14 ms to 2.76 s. Lesson 1's `app.py` shows why the bookings are the ones that suffer: it
holds one lock while it pays, so bookings go through one at a time, and thirty journeys a second
send more of them than one at a time can serve. Lesson 9 measures that lock.

Three other lines in this run matter as much as the crosses.

- **`http_req_failed` still passed, at 0.00%.** Every request was answered correctly, only late.
  A slow answer is not an error, which is exactly why the requirement needs a time threshold as
  well as an error threshold: with only the second one, this run would be green.
- **Every check passed too**, 801 out of 801. The checks asked whether each answer was right, and
  each one was. Correct and too slow is a failure only a threshold can see.
- **`dropped_iterations` is 260**, and the warning at the top says why: the scenario reached its
  `maxVUs` of 60, every one of them busy waiting for a booking, and k6 had nobody left to start
  the next journey with. The test asked for thirty journeys a second and delivered 11.21013. **A
  run that drops iterations did not apply the load it was written for**, so read that line before
  any percentile: these numbers describe a lighter test than the one you meant.

## What reads the exit code

In a terminal, `$?` holds the exit code of the last command, and `&&` runs the next command only
if it was 0: `k6 run -q k6/boxoffice.js && echo "release it"` prints its message only after a
pass. A pipeline job works the same way, and fails when its step exits with anything but 0;
lesson 11 puts this script in one and keeps the thresholds as a performance budget.

A threshold can also stop a run early. Written as an object,
`http_req_duration: [{ threshold: 'p(95)<200', abortOnFail: true }]`, it makes k6 stop the test as
soon as the limit is crossed, rather than load a system for ten more minutes after the verdict is
already known. That form was not run here; every run in this lesson lasts the full twenty seconds.
