---
title: Reading the summary, line by line
version: 1
---

The end-of-test summary is the same shape on every run, so it is worth reading once slowly. These
are the lines of the passing run in "Thresholds, and the exit code", in the order k6 prints them,
with the values that run printed.

## Checks

| line | what it counts |
|---|---|
| `checks_total: 162` | every check evaluated: three per journey, over 54 journeys |
| `checks_succeeded: 100.00%` | the share that passed, with the count beside it |
| `✓ show answers 200` | one line per check, by the name the script gave it; a cross when any of them failed, with the counts |

## HTTP

| line | what it measures |
|---|---|
| `http_req_duration` | from the first byte of the request sent to the last byte of the answer received: the response time the requirement is about |
| `{ expected_response:true }` | the same, over the answers the response callback called expected: the times of failed requests are left out |
| `{ name:booking }` | the same, over the requests tagged `booking`. It is printed because a threshold names it; a tag no threshold mentions gets no line of its own |
| `http_req_failed: 0.00%` | the share of answers that were not expected, 0 out of 108 |
| `http_reqs: 108  4.974135/s` | the requests sent, and how many a second over the whole run |

Each duration line carries six numbers: `avg`, `min`, `med`, `max`, `p(90)` and `p(95)`. The
median is the time half the requests stayed under, and `p(95)` the time 95 in 100 stayed under.
**Read `med` and `p(95)` before `avg`.** For the bookings the average was 79.55 ms and the median
71.86 ms, close together here. In the failing run the average of all requests was 1 s against a
median of 112.02 ms: a mean that sits between the fast pages and the slow bookings and describes
neither. Lesson 8 is about why.

The first run in this lesson printed a median of 27.68 ms and a 95th percentile of 62.09 ms for
show 990, where lesson 1's `curl` saw about 17 ms and `Server-Timing` said the database took nearly all of it. **On a connection
the load generator keeps open, about 40 ms of a response can be spent outside the application**,
and lesson 9 finds where.

## Execution and network

| line | what it says |
|---|---|
| `iteration_duration: avg=2.06s` | one whole journey: the two requests and the think time between them, one to three seconds |
| `iterations: 54  2.487067/s` | journeys finished, a little under three a second because the first five seconds ramp up from one |
| `vus: 3  min=1  max=7` | virtual users busy, from the last sample and over the run: at most 7 were needed at once |
| `vus_max: 20` | virtual users k6 had ready, the scenario's `preAllocatedVUs` |
| `data_received`, `data_sent` | bytes over the network each way, with the rate |

**`max=7` against `vus_max: 20` is the line that says the run was healthy.** k6 never ran short
of users to start a journey with, so it delivered the arrival rate the scenario asked for, and
there is no `dropped_iterations` line at all.

## The groups, and the phases of a request

The default summary leaves the groups out. `--summary-mode=full` adds a block for the scenario and
one for every group, and each of those carries more lines about time. Run the passing test again
with it, keeping only the groups:

```
ana@nft:~$ k6 run -q --summary-mode=full k6/boxoffice.js 2>&1 | sed -n '/GROUP: browse/,$p'
    ↳ GROUP: browse 

      checks_total.......: 110     5.105001/s
      checks_succeeded...: 100.00% 110 out of 110
      checks_failed......: 0.00%   0 out of 110

      ✓ show answers 200
      ✓ seats left is a number

      HTTP
      http_req_blocked...........: avg=163.54µs min=7.22µs  med=10.63µs  max=930.18µs p(90)=422.73µs p(95)=512.05µs
      http_req_connecting........: avg=109.12µs min=0s      med=0s       max=813.4µs  p(90)=291.78µs p(95)=333.62µs
      http_req_duration..........: avg=20.39ms  min=16.43ms med=18.42ms  max=46.86ms  p(90)=27.22ms  p(95)=31.64ms 
      http_req_failed............: 0.00% 0 out of 55
      http_req_receiving.........: avg=234.83µs min=89.25µs med=136.66µs max=2.96ms   p(90)=277.15µs p(95)=645.94µs
      http_req_sending...........: avg=66.43µs  min=21.22µs med=53.8µs   max=280.08µs p(90)=112.5µs  p(95)=126.21µs
      http_req_tls_handshaking...: avg=0s       min=0s      med=0s       max=0s       p(90)=0s       p(95)=0s      
      http_req_waiting...........: avg=20.09ms  min=16.31ms med=18.23ms  max=46.34ms  p(90)=27.07ms  p(95)=31.4ms  
      http_reqs..................: 55    2.552501/s

    ↳ GROUP: book 

      checks_total.......: 55      2.552501/s
      checks_succeeded...: 100.00% 55 out of 55
      checks_failed......: 0.00%   0 out of 55

      ✓ booked or taken

      HTTP
      http_req_blocked...........: avg=11.35µs  min=7.43µs  med=9.72µs   max=48.55µs  p(90)=14.21µs  p(95)=17.02µs 
      http_req_connecting........: avg=0s       min=0s      med=0s       max=0s       p(90)=0s       p(95)=0s      
      http_req_duration..........: avg=57.31ms  min=16.69ms med=61.73ms  max=122.57ms p(90)=70.77ms  p(95)=102.4ms 
      http_req_failed............: 0.00% 0 out of 55
      http_req_receiving.........: avg=144.3µs  min=82.01µs med=128.45µs max=378.48µs p(90)=187.65µs p(95)=280.21µs
      http_req_sending...........: avg=114.41µs min=28.47µs med=55.19µs  max=3.09ms   p(90)=82.29µs  p(95)=93.65µs 
      http_req_tls_handshaking...: avg=0s       min=0s      med=0s       max=0s       p(90)=0s       p(95)=0s      
      http_req_waiting...........: avg=57.05ms  min=16.5ms  med=61.54ms  max=122.39ms p(90)=70.64ms  p(95)=102.06ms
      http_reqs..................: 55    2.552501/s
```

**The full summary breaks `http_req_duration` into its phases.** `http_req_sending` is writing the
request, `http_req_waiting` is waiting for the first byte of the answer, and
`http_req_receiving` is reading the rest; the three add up to the duration. `http_req_blocked`,
`http_req_connecting` and `http_req_tls_handshaking` come before it, while k6 finds or opens a
connection, and are not part of it. Here the waiting is almost all of every request: 20.09 ms of
the 20.39 ms average in `browse`, and 57.05 ms of the 57.31 ms in `book`, where the 40 ms payment
sits. That is the server's time, and lesson 9 starts from it.
