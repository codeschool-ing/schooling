---
title: Vegeta, one program and a pipeline
version: 1
---

Vegeta is a single program written in Go, like k6, and it has no scenarios, no think time and no
users. **It sends requests at a rate you name, for as long as you say, and nothing else.** That is
less than any tool so far, and it is exactly the shape of lesson 1's requirement: one operation, at
a rate, for a duration.

## One program

```sh
cd ~
curl -fsSLO https://github.com/tsenart/vegeta/releases/download/v12.13.0/vegeta_12.13.0_linux_amd64.tar.gz
tar -xzf vegeta_12.13.0_linux_amd64.tar.gz vegeta
sudo install vegeta /usr/local/bin/
```

On ARM the archive is `vegeta_12.13.0_linux_arm64.tar.gz`. **These lines were not run for this
course**, because the computer it was recorded on cannot reach GitHub; the Vegeta in the
transcripts was built from the same v12.13.0 source, which is why the version prints a Go version
and an empty date:

```
ana@nft:~$ vegeta -version
Version: v12.13.0
Commit: 4b240c3089fa4aa10816542d64a74294d974211f
Runtime: go1.25.1 linux/amd64
Date: 
```

## A pipeline of three commands

Vegeta is three subcommands joined by pipes, each doing one step. `vegeta attack` reads targets,
one request per line, and writes the results in a binary format; `vegeta report` reads results
and prints them. `tee` keeps a copy of the results in a file on the way:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l07-pipeline\" aria-label=\"Vegeta as a pipeline, left to right. echo writes one target, a line saying GET and an address. vegeta attack reads targets and sends them at the rate it was given, for the duration it was given, and writes one binary result per request. tee copies those results into results.bin on the way. vegeta report reads results and prints them as text, as a histogram or as JSON, and can read results.bin again later without sending anything.\"><defs><marker id=\"l07-pipeline-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-pipeline-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"50.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">echo</text><rect x=\"20.0\" y=\"92.0\" width=\"120.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"80.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one target</text><text x=\"80.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">per line</text><rect x=\"172.0\" y=\"50.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"247.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">vegeta attack</text><rect x=\"172.0\" y=\"92.0\" width=\"150.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"247.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-rate=50</text><text x=\"247.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-duration=10s</text><rect x=\"354.0\" y=\"50.0\" width=\"100.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tee</text><rect x=\"354.0\" y=\"92.0\" width=\"100.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"404.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a copy on</text><text x=\"404.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the way</text><rect x=\"486.0\" y=\"50.0\" width=\"214.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"593.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">vegeta report</text><rect x=\"486.0\" y=\"92.0\" width=\"214.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"593.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-type=text</text><text x=\"593.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-type='hist[...]'</text><text x=\"593.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">-type=json</text><path d=\"M140.0 67.0 L168.0 67.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-paper-dim)\"></path><path d=\"M322.0 67.0 L350.0 67.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-paper-dim)\"></path><path d=\"M454.0 67.0 L482.0 67.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-paper-dim)\"></path><text x=\"156.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">targets</text><text x=\"338.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">results</text><text x=\"470.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">results</text><rect x=\"354.0\" y=\"176.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">results.bin</text><path d=\"M404.0 148.0 L404.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-amber)\"></path><path d=\"M454.0 191.0 L593.0 191.0 L593.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-pipeline-nf-ah-amber)\"></path><text x=\"600.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">report again, sending nothing</text></svg>", "caption": "Three commands joined by pipes: what to send, sending it, and reading what came back."}
```

Fifty requests a second for ten seconds to the show lesson 1 asked about, with the box office
running in the first terminal:

```
ana@nft:~$ echo "GET http://127.0.0.1:8000/shows/990" | vegeta attack -rate=50 -duration=10s | tee results.bin | vegeta report
Requests      [total, rate, throughput]         500, 50.10, 49.80
Duration      [total, attack, wait]             10.041s, 9.981s, 60.171ms
Latencies     [min, mean, 50, 90, 95, 99, max]  7.45ms, 47.629ms, 52.846ms, 58.017ms, 60.875ms, 68.687ms, 74.068ms
Bytes In      [total, mean]                     60000, 120.00
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           100.00%
Status Codes  [code:count]                      200:500  
Error Set:
```

**`Requests` says the rate was kept**: 500 requests, sent at 50.10 a second, answered at a
throughput of 49.80. `Latencies` gives the minimum, the mean, the 50th, 90th, 95th and 99th
percentiles and the maximum, so the requirement's number is the fifth: a 95th percentile of
60.875 ms, under the 200 ms of lesson 1. `Success` is the share of answers with a 2xx or 3xx status,
and `Error Set` lists the distinct errors, none here.

The results in `results.bin` can be reported again, in any of the report's forms, without sending
a single request. A histogram with the buckets you choose shows where the times fell:

```
ana@nft:~$ vegeta report -type='hist[0,20ms,40ms,60ms,100ms,200ms]' results.bin
Bucket           #    %       Histogram
[0s,     20ms]   82   16.40%  ############
[20ms,   40ms]   5    1.00%   
[40ms,   60ms]   367  73.40%  #######################################################
[60ms,   100ms]  46   9.20%   ######
[100ms,  200ms]  0    0.00%   
[200ms,  +Inf]   0    0.00%   
```

**The histogram has two humps.** 82 answers came back in under 20 ms, about the time lesson 1's
`curl` measured, and 367 between 40 and 60 ms, with almost nothing between them. On a connection the load generator keeps open,
about 40 ms of a response is spent outside the application, and lesson 9 finds where.

## An open model, and why it matters

**Vegeta sends the next request when the clock says so, not when the last answer arrives.** If
the box office is slow, Vegeta starts more workers and keeps to the rate. That is the open model
of lessons 5 and 6, and Vegeta has no users and no think time to make it anything else; only
`-max-workers`, which caps how many requests may be in flight, would stop it keeping the rate. Asked for more than the box office can serve, the answers fall behind and pile up:

```
ana@nft:~$ echo "GET http://127.0.0.1:8000/shows/990" | vegeta attack -rate=300 -duration=5s -timeout=5s | vegeta report
Requests      [total, rate, throughput]         1500, 300.16, 135.39
Duration      [total, attack, wait]             9.86s, 4.997s, 4.863s
Latencies     [min, mean, 50, 90, 95, 99, max]  15.483ms, 2.508s, 2.413s, 5s, 5.001s, 5.001s, 5.013s
Bytes In      [total, mean]                     160200, 106.80
Bytes Out     [total, mean]                     0, 0.00
Success       [ratio]                           89.00%
Status Codes  [code:count]                      0:165  200:1335  
Error Set:
Get "http://127.0.0.1:8000/shows/990": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l07-backlog\" aria-label=\"Requests a second against time, over the ten seconds of the run at 300 a second, drawn from its totals rather than sampled. Vegeta sends 300 a second for five seconds and then stops. The box office answers about 135 a second throughout, until 9.86 seconds. The gap between the two lines during the attack is the backlog: requests sent and waiting for an answer. After the attack, the box office spends nearly five more seconds working through it, and the requests that waited longer than the five-second timeout get no answer.\"><path d=\"M90.0 200.0 L650.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90.0 200.0 L90.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M90.0 200.0 L90.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"90.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M202.0 200.0 L202.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"202.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2 s</text><path d=\"M314.0 200.0 L314.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"314.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 s</text><path d=\"M426.0 200.0 L426.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"426.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6 s</text><path d=\"M538.0 200.0 L538.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 s</text><path d=\"M650.0 200.0 L650.0 204.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"650.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 s</text><path d=\"M86.0 200.0 L90.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M86.0 136.7 L90.0 136.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"136.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">135</text><path d=\"M86.0 59.4 L90.0 59.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"82.0\" y=\"59.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"82.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests/s</text><path d=\"M90.0 59.4 L370.0 59.4 L370.0 136.7 L90.0 136.7 Z\" stroke=\"none\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"230.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">the backlog grows</text><path d=\"M90.0 59.4 L370.0 59.4 L370.0 200.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"378.0\" y=\"59.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sent: 300 a second, then stop</text><path d=\"M90.0 136.7 L642.2 136.7 L642.2 200.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"504.4\" y=\"124.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">answered: about 135 a second</text><text x=\"504.4\" y=\"171.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the backlog drains</text><text x=\"360.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">an open generator keeps sending, so the waiting shows up in the times it reports</text></svg>", "caption": "The run at 300 a second: the box office cannot keep up, and the requests it has not answered wait in line."}
```

**Vegeta sent at 300.16 a second and the box office answered at 135.39.** The rate was kept to
the end of the attack, so the requests the box office could not serve waited in line. The median
went from 52.846 ms at fifty a second to 2.413 s here, and 165 requests reached the five-second
`-timeout` with no answer at all: that is the `0` in `Status Codes` and the `context deadline
exceeded` in `Error Set`, and why `Success` is 89.00%. A closed generator with the same number of
users would have slowed its own sending down to match, and printed far kinder numbers.

Lesson 8 gives a name to what a closed generator does instead: **coordinated omission**. A closed
generator, whose users wait for each answer, sends fewer requests exactly while the system is slow,
and leaves the slow moments out of its own sample. Vegeta cannot do that, which makes it the tool
to reach for when the question is "what happens at this rate", and lesson 8 shows the difference
in numbers.
