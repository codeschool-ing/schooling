---
title: One run is not a verdict
version: 1
---

Every run of a performance test is a sample. Run the same test on the same code and the numbers
come back different, because the machine is doing other things, the garbage collector ran at a
different moment, or the network took a different path. Lesson 8 met this as the spread of
response times inside one run; **here it is the spread between runs**, and it decides how a gate
has to be built.

The three runs that made the baseline in the previous section are a small example of it:

```
ana@nft:~/boxoffice$ jq '.metrics.http_req_duration["p(95)"]' perf/runs/base-*.json
2.113172
3.177051450000001
3.384710850000008
```

The same code, the same load, three answers, from 2.113 to 3.385 ms: the slowest run is 60% above
the fastest. The regression's three runs, measured by the gate in
the next section, are further apart still, and every one of them is far above the baseline.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 345\" role=\"img\" data-fig=\"l11-noise\" aria-label=\"The 95th percentile of GET /shows/{id} in every k6 run of this lesson, one dot per run, on a logarithmic scale from 1 to 50 milliseconds. A dashed line marks the baseline at 3.18 ms and a solid amber line the limit at 9.8 ms. With the index in place: the three baseline runs at 2.11, 3.18 and 3.38 ms; the gate on the fixed page at 3.1, 1.9 and 1.7 ms, all under the limit; the gate on the slow page at 2.1, 12.5 and 11.4 ms, two of them over the limit with no change to the code. With the index dropped: the single run at 33.4 ms and the gate at 23.1, 16.8 and 21.9 ms, all far over the limit.\"><text x=\"30.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">index in place</text><text x=\"30.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">index dropped</text><text x=\"30.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">baseline, 3 runs</text><path d=\"M250.0 64.0 L690.0 64.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"334.1\" cy=\"64.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"380.0\" cy=\"64.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"387.1\" cy=\"64.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><text x=\"30.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gate on /fast.html</text><path d=\"M250.0 100.0 L690.0 100.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"377.3\" cy=\"100.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"322.2\" cy=\"100.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"309.7\" cy=\"100.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><text x=\"30.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gate on /</text><path d=\"M250.0 136.0 L690.0 136.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"333.4\" cy=\"136.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"534.1\" cy=\"136.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><circle cx=\"523.7\" cy=\"136.0\" r=\"5.5\" fill=\"var(--paper)\"></circle><text x=\"30.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one run</text><path d=\"M250.0 202.0 L690.0 202.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"644.6\" cy=\"202.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><text x=\"30.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gate on /fast.html</text><path d=\"M250.0 238.0 L690.0 238.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><circle cx=\"603.1\" cy=\"238.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"567.3\" cy=\"238.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><circle cx=\"597.1\" cy=\"238.0\" r=\"5.5\" fill=\"var(--amber)\"></circle><path d=\"M380.0 46.0 L380.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M506.7 46.0 L506.7 252.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"380.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">baseline 3.18 ms</text><text x=\"512.7\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">limit 9.8 ms</text><path d=\"M250.0 290.0 L690.0 290.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M250.0 290.0 L250.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"250.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 ms</text><path d=\"M328.0 290.0 L328.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"328.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 ms</text><path d=\"M431.0 290.0 L431.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"431.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 ms</text><path d=\"M509.0 290.0 L509.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"509.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 ms</text><path d=\"M586.9 290.0 L586.9 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"586.9\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 ms</text><path d=\"M690.0 290.0 L690.0 295.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 ms</text></svg>", "caption": "Every run of the back end in this lesson. The two dots right of the limit in the third row are noise: the code was the baseline's."}
```

## Why a single run cannot gate

A gate decides from one number, and with a single run that number is whatever this run happened
to be. Two kinds of mistake follow, and both are expensive:

- **A false failure.** A good change fails because its one run landed on a busy moment. Somebody
  reruns the job, it passes, and the team learns that a red performance gate means "run it again".
  After a few weeks of that, nobody reads it. The next section has one, on this machine.
- **A false pass.** A real regression passes because its one run landed on a quiet moment. Nobody
  notices, and the next baseline is recorded from the slower version.

## Repeat, and take the median

The median of several runs moves much less than any one of them, and one wild run cannot drag it
the way it drags a mean. Lighthouse's documentation recommends the median of five runs; this
lesson's gate uses three of each tool to keep it under a few minutes, which is the usual trade
between how long a pull request waits and how often the gate is wrong.

There is a shortcut for thresholds. **With three runs and a fixed limit, the median crosses the
limit exactly when at least two of the runs do.** So the gate does not need to collect the three
95th percentiles and sort them: it counts how many runs k6 failed, and fails on two. With five
runs the rule is three.

## The tolerance has to be wider than the noise

A tolerance is a statement about noise. Set it narrower than the spread between runs and the gate
fails good changes; set it far wider and it passes real regressions. **Measure the spread first,
then set the tolerance**, and set it in two parts when the endpoint is fast:

- a **relative part**, here 50%, which scales with the endpoint: a 100 ms endpoint gets 50 ms of
  room;
- an **absolute part**, here 5 ms, because on a request that takes two milliseconds the noise is
  measured in milliseconds, not in percent. Fifty per cent of 2 ms is 1 ms, and a busy machine adds
  more than that.

Two more habits keep the noise down. Run the gate on the same kind of machine every time, since a
baseline from one runner and a run on another compare the runners. And refresh the baseline
deliberately, when a change that should move it is accepted, never automatically from the last
run: a baseline that follows every run follows every regression too.
