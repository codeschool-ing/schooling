---
title: Five tests, five questions
version: 1
---

"We ran a load test" is the sentence that opens most performance reports, and it says almost
nothing, because the same tool and the same script can answer five different questions. **What
tells the five apart is the shape of the load over time**, and the question that shape was chosen
to answer. Pick the question first; the shape follows from it, and so does what *pass* means.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 440\" role=\"img\" data-fig=\"l02-shapes\" aria-label=\"Five tests drawn as load against time, one row each. Load test: a ramp up to the expected load, a long flat hold, a ramp down; it passes when the requirement holds for the whole hold. Stress test: steps that keep climbing past the expected load; it is read for where and how it breaks, and whether it recovers. Spike test: a flat normal load, a sudden jump to many times it for a short while, and back; it passes when errors stay bounded and the times come back to normal soon after. Soak test: the expected load held flat for hours; it passes when nothing drifts, the times at the end matching the times at the start. Scalability test: the same climbing steps run twice, with one share of resources and then with twice as much; it passes when the second run carries about twice the throughput.\"><text x=\"105.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">the test and its question</text><text x=\"340.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">load against time</text><text x=\"600.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">it passes when</text><text x=\"30.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">load</text><text x=\"30.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">does it meet the requirement</text><text x=\"30.0\" y=\"87.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">at the expected load?</text><path d=\"M230.0 96.0 L450.0 96.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 46.0 L230.0 96.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"107.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><path d=\"M230.0 62.0 L450.0 62.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"454.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">expected</text><path d=\"M230.0 96.0 L270.0 62.0 L410.0 62.0 L440.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"61.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the thresholds hold for</text><text x=\"520.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the whole hold</text><path d=\"M20.0 114.0 L700.0 114.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">stress</text><text x=\"30.0\" y=\"154.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">where does it break, how,</text><text x=\"30.0\" y=\"167.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and does it come back?</text><path d=\"M230.0 176.0 L450.0 176.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 126.0 L230.0 176.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"187.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><path d=\"M230.0 152.0 L450.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"454.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">expected</text><path d=\"M230.0 176.0 L230.0 168.0 L265.0 168.0 L265.0 160.0 L300.0 160.0 L300.0 152.0 L335.0 152.0 L335.0 144.0 L370.0 144.0 L370.0 136.0 L405.0 136.0 L405.0 128.0 L440.0 128.0 L440.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"141.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no fixed pass: the result is</text><text x=\"520.0\" y=\"154.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the breaking point and the manner</text><path d=\"M20.0 194.0 L700.0 194.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">spike</text><text x=\"30.0\" y=\"234.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">does it survive a sudden</text><text x=\"30.0\" y=\"247.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">crowd, and recover after?</text><path d=\"M230.0 256.0 L450.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 206.0 L230.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"267.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><path d=\"M230.0 244.0 L320.0 244.0 L325.0 207.0 L355.0 207.0 L360.0 244.0 L445.0 244.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"221.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">errors stay bounded, times are</text><text x=\"520.0\" y=\"234.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">normal again soon after</text><path d=\"M20.0 274.0 L700.0 274.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"294.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">soak</text><text x=\"30.0\" y=\"314.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">does anything grow or</text><text x=\"30.0\" y=\"327.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">drift with time?</text><path d=\"M230.0 336.0 L450.0 336.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 286.0 L230.0 336.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"347.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">hours</text><path d=\"M230.0 336.0 L245.0 302.0 L435.0 302.0 L445.0 336.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"301.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the last hour looks like</text><text x=\"520.0\" y=\"314.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the first one</text><path d=\"M20.0 354.0 L700.0 354.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"374.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">scalability</text><text x=\"30.0\" y=\"394.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do more resources carry</text><text x=\"30.0\" y=\"407.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">more load?</text><path d=\"M230.0 416.0 L450.0 416.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 366.0 L230.0 416.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"427.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><text x=\"278.0\" y=\"368.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">×1 resources</text><text x=\"393.0\" y=\"368.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">×2 resources</text><path d=\"M230.0 416.0 L230.0 416.0 L230.0 406.0 L254.0 406.0 L254.0 396.0 L278.0 396.0 L278.0 386.0 L302.0 386.0 L302.0 376.0 L326.0 376.0 L326.0 416.0 L345.0 416.0 L345.0 406.0 L369.0 406.0 L369.0 396.0 L393.0 396.0 L393.0 386.0 L417.0 386.0 L417.0 376.0 L441.0 376.0 L441.0 416.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"381.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">twice the resources give close</text><text x=\"520.0\" y=\"394.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to twice the throughput</text></svg>", "caption": "The five tests by the load each one applies. The shape is what tells them apart; the tool and the script can be the same."}
```

## Load: does it meet the requirement?

A **load test** applies the load the system is expected to meet, the one written in the
requirement from lesson 1, and holds it. The shape is a ramp up to that load, a long flat stretch
at it, and a ramp down. The ramp exists so the system is not hit cold with everything at once,
which would be a different test; lesson 3 says how long it should be.

Only the flat stretch is judged. **It passes when every threshold in the requirement holds for
the whole hold**: the 95th percentile under 200 ms and errors under 1%, at 50 requests a second,
for ten minutes. Its pass mark is the requirement itself, which is why it is the test a release
is gated on.

## Stress: where does it break, and how?

A **stress test** keeps adding load past the expected level until something gives. The shape is a
staircase that does not stop climbing. It has no pass mark in the usual sense, because the
question is not whether the system breaks (everything does) but where, and in what manner:

- **The breaking point**: the load at which a threshold is first crossed. That is the system's
  capacity under that requirement, and the gap between it and the expected load is the margin.
- **The manner**: a server that answers the excess quickly with a refusal, a `503` that says
  *try again*, is failing well. One that lets every request wait until all of them time out is
  failing badly, and the box office does the second, as "Three shapes on the box office" shows.
- **The recovery**: when the load drops, does it come back on its own, or does it stay broken
  until somebody restarts it?

A stress test *fails* when the manner is wrong: data corrupted under pressure, a seat sold twice,
a server that never recovers. Those are defects, whatever the breaking point was.

## Spike: does it survive a sudden crowd?

A **spike test** goes from normal to many times normal almost instantly, holds it briefly, and
drops back. It is the box office at 10:00, when a popular show goes on sale and the people who were
waiting all press the button in the same minute. A stress test climbs slowly enough for caches to
warm and pools to grow; a spike gives the system no time to adapt, which is exactly the situation it
has to survive.

It passes when the errors during the spike stay within what was agreed, and **the response times
return to normal within a stated time after it**. The second half is the one people forget. A
system that queues a spike and then takes two minutes to work the queue off is still failing the
customers who arrive in those two minutes, at a load that is normal again.

## Soak: does anything drift?

A **soak test**, also called an endurance test, holds the expected load for hours: eight, twelve,
a weekend. The shape is the load test's flat line, stretched. Nothing about the load is
demanding; the question is what accumulates. Memory that a handler never frees, database
connections that are opened and not returned, a log file filling a disk, a table that grows with
every request and makes each query slower than the one before.

It passes when **the last hour looks like the first**: the same response times, the same memory,
the same number of open connections. A soak test is read as a trend, and lesson 22 sets up the
metrics a soak test watches over hours. Nothing in this lesson runs one, because a demonstration
that takes a night is not one you can follow.

## Scalability: do more resources carry more load?

A **scalability test** asks a question about the architecture rather than the release: if the
system gets more processors, more memory, or more copies of the server, does it carry
proportionally more load? The shape is a stress staircase, run once per configuration, and the
number compared is the **capacity**, the highest throughput each configuration sustains within the
requirement.

A **capacity test** is the same measurement made once, on the configuration you have: how much
load does this machine take before the requirement fails? Teams use the two names loosely, and
the distinction worth keeping is that capacity is a number about one setup, and scalability is how
that number moves when the setup changes.

It passes when the capacity grows by a stated fraction of the resources added. Doubling the
processors and getting 1.8 times the throughput is a system that scales. Doubling them and getting
1.1 times is a system with something inside it that one processor or a hundred will wait on in turn,
and lesson 9 is about finding that something.

## The names are not settled, the questions are

Different teams and tools draw these lines differently. Some call every one of them a load test;
some call a spike a kind of stress test; the ISTQB glossary and a tool's documentation do not
agree in every detail. **What matters in a test plan is that the question is written next to the
name**, so that a reader knows whether a result with errors in it is a failure or the finding.

| test | the load | it answers | read as |
|---|---|---|---|
| load | the expected load, held | does it meet the requirement? | pass or fail against the thresholds |
| stress | climbing past expected | where and how does it break? | a breaking point and a manner |
| spike | a sudden jump and back | does it survive and recover? | errors bounded, time to recover |
| soak | expected, for hours | does anything drift? | a trend that should be flat |
| scalability | a staircase per configuration | do resources add capacity? | the ratio between capacities |
