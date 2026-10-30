---
title: Beam writes the pipeline, Dataflow runs it
version: 1
---

**Dataflow is not something you program. You write the program in Apache Beam, and Dataflow is one
of the places a Beam program can run.** Beam is an open-source library, for Python, Java and Go,
for describing a computation over a collection of records: read them, change them, group them,
write them. A **runner** is what executes that description. Dataflow is Google's runner, a managed
service that starts virtual machines to do the work and takes them away afterwards. Others run the
same program on Spark, on Flink, or inside the Python process on your laptop, which is where this
lesson runs it.

The wrong picture is that a streaming job and a batch job are two programs. Quitanda has both
shapes of the same question: the shop's nightly export of the day's order events, a file in
`quitanda-raw-prod`, and the same events published to a Pub/Sub topic one by one as they happen, the
subject of lesson 19. Asked of either, the question is how many orders each neighbourhood placed, and
for how much. **Beam's model is that a file and a stream are both collections, one of which ends**,
and that the steps between reading and writing do not need to know which.

## Four words

| word | what it is |
|---|---|
| **pipeline** | the whole computation, built as a graph and then handed to a runner |
| **PCollection** | a collection of elements flowing between two steps; **bounded** if it ends, like a file, **unbounded** if it does not, like a subscription |
| **PTransform** | a step: `Map` and `Filter` take one element at a time, `FlatMap` may give any number back, `GroupByKey` and `CombinePerKey` bring together every element with the same key |
| **runner** | what executes the graph: the DirectRunner here, Dataflow on Google Cloud |

**A Beam program builds the graph first and runs it after.** The line
`lines | 'Parse' >> beam.FlatMap(parse)` does not parse anything when Python reaches it; it adds a
step called `Parse` to the graph and returns a PCollection that will hold its output. Only when the
pipeline is run does the runner decide how to execute the steps: in one process, or spread over a
hundred workers that each take a slice of the input. That separation is what lets the same program
run on a laptop and on Dataflow, and it is also why an error in a step's code shows up when the
pipeline runs, not when the line is read.

**Every element also carries a timestamp and a window.** A line read from a file gets no meaningful
time and goes into the **global window**, which holds everything. An element from a stream carries
a time, and a stream that is grouped has to be cut into windows first, for a reason the fourth
section shows with an error. Lesson 22 is the whole subject of windows; this one uses the simplest,
a fixed window of one minute.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"One Beam pipeline drawn with two pairs of ends. In batch it reads a file with ReadFromText and writes files with WriteToText. In stream it reads Pub/Sub with ReadFromPubSub, cuts the messages into windows of 60 seconds, and writes to Pub/Sub with WriteToPubSub. Between the ends sits PlacedTotals, the same five steps in both: Parse, Placed, Key, Add and Format, where Add is the combine. Each end receives the totals and the unreadable lines.\" data-fig=\"gcp21-pipeline\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">batch: a file, a collection that ends</text><rect x=\"20\" y=\"32\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ReadFromText</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stream: Pub/Sub, a collection that does not</text><rect x=\"20\" y=\"162\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ReadFromPubSub</text><rect x=\"20\" y=\"204\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"219\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">WindowInto(60 s)</text><line x1=\"105\" y1=\"192\" x2=\"105.0\" y2=\"203.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"105.0,203.0 102.4,197.6 107.6,197.6\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"240\" y=\"70\" width=\"250\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"365\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PlacedTotals, the same in both</text><rect x=\"252\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Parse</text><rect x=\"299\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"319\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Placed</text><line x1=\"292\" y1=\"125\" x2=\"298.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,125.0 292.6,127.6 292.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"346\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"366\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Key</text><line x1=\"339\" y1=\"125\" x2=\"345.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"345.0,125.0 339.6,127.6 339.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"393\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"413\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Add</text><line x1=\"386\" y1=\"125\" x2=\"392.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"392.0,125.0 386.6,127.6 386.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"440\" y=\"112\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Format</text><line x1=\"433\" y1=\"125\" x2=\"439.0\" y2=\"125.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"439.0,125.0 433.6,127.6 433.6,122.4\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"190\" y1=\"47\" x2=\"251.0\" y2=\"118.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"251.0,118.0 245.5,115.6 249.5,112.2\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"190\" y1=\"219\" x2=\"251.0\" y2=\"132.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"251.0,132.0 250.0,137.9 245.8,134.9\" fill=\"var(--wire)\" stroke=\"none\"></polygon><text x=\"413\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">Combine</text><rect x=\"540\" y=\"32\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WriteToText</text><rect x=\"540\" y=\"162\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WriteToPubSub</text><line x1=\"491\" y1=\"118\" x2=\"539.0\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"539.0,50.0 538.0,55.9 533.8,52.9\" fill=\"var(--wire)\" stroke=\"none\"></polygon><line x1=\"491\" y1=\"132\" x2=\"539.0\" y2=\"174.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"539.0,174.0 533.2,172.4 536.7,168.5\" fill=\"var(--wire)\" stroke=\"none\"></polygon><text x=\"540\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">totals + unreadable lines</text><text x=\"540\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">totals + unreadable lines</text></svg>", "caption": "The pipeline of this lesson. The middle is one composite transform, written once; a stream adds a window at its entrance, the one step a batch does not need."}
```

## Installing Beam

The terminal is the one from lesson 1, after "Every time you open a terminal", with the virtual
environment active. Beam's Python package, at a version pinned like the rest of the lab:

```sh
pip install -q apache-beam==2.76.0
```

```
ana@laptop:~/gcp$ pip install -q apache-beam==2.76.0
ana@laptop:~/gcp$ python3 -c "import apache_beam; print(apache_beam.__version__)"
2.76.0
ana@laptop:~/gcp$ pip list 2>/dev/null | grep -E '^protobuf '
protobuf                           6.33.6
```

**The plain package, without extras, is enough for this lesson.** Reading and writing Pub/Sub
needs Google's Pub/Sub library, which lesson 1 already put in the environment. What the plain
package lacks is the DataflowRunner's own client, which comes with `apache-beam[gcp]`; the fifth
section shows the command that would need it, and this lab never runs it. pip also replaces the
environment's `protobuf`, which lesson 1 installed at 7.36.2, with the older release on the last
line, the newest Beam 2.76.0 accepts. It says nothing about it, because `-q` asks it to be quiet,
and the Google libraries of lesson 1 work with that release too, as the Pub/Sub runs below show.

## The DirectRunner, and the runner it tries first

**Beam 2.76.0's `DirectRunner` is a switch, not one runner.** Asked to run a pipeline, it first
tries **Prism**, a newer local runner written in Go, which it downloads from GitHub the first time.
Only if Prism cannot run the pipeline does it fall back to the runners inside Python. A one-line
pipeline with Beam's own log turned on shows the switch, on a laptop with no route to GitHub:

```
ana@laptop:~/gcp$ python3 -c "import logging,apache_beam as beam; logging.basicConfig(level=logging.INFO); p=beam.Pipeline(); p|beam.Create([1])|beam.Map(print); p.run().wait_until_finish()" 2>&1 | head -20
INFO:root:Missing pipeline option (runner). Executing pipeline using the default runner: DirectRunner.
INFO:apache_beam.runners.direct.direct_runner:Running pipeline with PrismRunner.
INFO:apache_beam.runners.worker.worker_pool_main:Listening for workers at localhost:38895
INFO:apache_beam.runners.portability.prism_runner:Downloading prism from https://github.com/apache/beam/releases/download/v2.76.0/apache_beam-v2.76.0-prism-linux-amd64.zip
INFO:apache_beam.runners.direct.direct_runner:Exception with PrismRunner:
 Unable to fetch remote prism binary at https://github.com/apache/beam/releases/download/v2.76.0/apache_beam-v2.76.0-prism-linux-amd64.zip: <urlopen error [Errno -3] Temporary failure in name resolution>

INFO:apache_beam.runners.direct.direct_runner:Falling back to DirectRunner
INFO:apache_beam.runners.worker.statecache:Creating state cache with size 104857600
1
```

**That fallback depends on the network**, which makes it a bad thing for a lesson to rest on: on a
laptop that can reach GitHub, the same command downloads Prism and runs there, and Prism's
behaviour is not what these transcripts recorded. So the program of the next section names its
runner, `BundleBasedDirectRunner`, the DirectRunner that runs inside Python and supports streaming,
and every run in this lesson and the next uses it. **It is a runner for testing, not for volume**:
one process, a few threads, everything in memory. It is the right place to find out whether a
pipeline is correct, and the wrong place to find out whether it is fast.
