---
title: Running Artillery, and its report
version: 1
---

`artillery run` takes the file and starts the phases. While it runs it prints a block of metrics
every ten seconds, one per period, and at the end a summary of the whole run. With the box office
running in the first terminal, send the output to a file and look at the summary:

```
ana@nft:~/artillery$ artillery run boxoffice.yml > run.log; echo "exit $?"
exit 0
ana@nft:~/artillery$ sed -n '/Summary report/,$p' run.log
Summary report @ 16:53:51(-0300)
--------------------------------

http.codes.200: ................................................................ 56
http.codes.201: ................................................................ 50
http.codes.409: ................................................................ 6
http.downloaded_bytes: ......................................................... 8966
http.request_rate: ............................................................. 6/sec
http.requests: ................................................................. 112
http.response_time:
  min: ......................................................................... 6
  max: ......................................................................... 202
  mean: ........................................................................ 36.2
  median: ...................................................................... 19.1
  p95: ......................................................................... 68.7
  p99: ......................................................................... 94.6
http.response_time.2xx:
  min: ......................................................................... 6
  max: ......................................................................... 202
  mean: ........................................................................ 37.2
  median: ...................................................................... 22
  p95: ......................................................................... 68.7
  p99: ......................................................................... 94.6
http.response_time.4xx:
  min: ......................................................................... 9
  max: ......................................................................... 53
  mean: ........................................................................ 19.5
  median: ...................................................................... 13.1
  p95: ......................................................................... 16.9
  p99: ......................................................................... 16.9
http.responses: ................................................................ 112
vusers.completed: .............................................................. 56
vusers.created: ................................................................ 56
vusers.created_by_name.look and book: .......................................... 56
vusers.failed: ................................................................. 0
vusers.session_length:
  min: ......................................................................... 2027
  max: ......................................................................... 2240.7
  mean: ........................................................................ 2081.6
  median: ...................................................................... 2059.5
  p95: ......................................................................... 2101.1
  p99: ......................................................................... 2231

Checks:
ok: maxErrorRate < 1
ok: http.response_time.p95 < 200
```

**Artillery's report is a list of counters and distributions, named by what they count.**

| line | what it says here |
|---|---|
| `http.codes.200`, `.201`, `.409` | 56 shows, 50 bookings made and 6 seats already taken: every answer, by status |
| `http.requests`, `http.responses` | 112 sent and 112 answered |
| `http.response_time` | `min`, `max`, `mean`, `median`, `p95` and `p99` of every answer, in milliseconds: a median of 19.1 and a 95th percentile of 68.7 |
| `http.response_time.2xx`, `.4xx` | the same, split by the class of the status: the 409s, which skip the payment, had a median of 13.1 |
| `vusers.created`, `vusers.completed` | 56 visitors arrived and 56 finished the journey |
| `vusers.failed` | visitors whose journey stopped on an error, 0 |
| `vusers.session_length` | how long one journey took, in milliseconds: a median of 2059.5, the two-second think plus two requests |
| `Checks` | one line per `ensure` rule, `ok` or `fail` |

**A 409 is not an error to Artillery**, so nothing like k6's response callback is needed: an
error is a request with no answer, and a status is just counted. The other side of that is that a
500 is not an error either. A box office answering 500 to every booking would pass `maxErrorRate`
and show up only as `http.codes.500` in the list, so a rule about status codes has to be written
as a rule of its own in `ensure`.

## A check that fails

`--overrides` replaces part of `config` from the command line, as JSON, without editing the file.
Here it sets a 95th percentile of 5 ms, which no answer of this box office can meet:

```
ana@nft:~/artillery$ artillery run boxoffice.yml --overrides '{"config": {"ensure": {"thresholds": [{"http.response_time.p95": 5}]}}}' > fail.log; echo "exit $?"
exit 1
ana@nft:~/artillery$ sed -n '/^Checks/,$p' fail.log
Checks:
ok: maxErrorRate < 1
fail: http.response_time.p95 < 5
```

**A failed check makes `artillery run` exit with 1**, and the `Checks` block says which one with
`fail:`. Without `ensure` in the file, the run would have exited 0 whatever the times were.

`artillery run --output report.json` also writes every period's metrics to a JSON file, which is
what a pipeline keeps as the record of the run. Artillery's company offers a hosted dashboard that
reads those results; it is a paid service on the internet and is not used in this course.
