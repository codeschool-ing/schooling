---
title: Three clocks, and one timestamp field
version: 1
---

**Every sale has at least three times, and a stream processor that does not say which one it
means will use whichever is nearest.** The nearest is almost always the wrong one.

The common picture is that a timestamp is a timestamp: the sale happened at 10:21, so everything
downstream sees 10:21. In a batch that picture costs nothing, because the job runs hours after the
day ended and every sale is already in. In a stream the three times are pulled apart by networks,
outages and queues, and each answers a different question:

| clock | what it records | who writes it | in Ponto Final |
|---|---|---|---|
| **event time** | when the thing happened | the source, inside the event | the sale's `at`, written by the till |
| **ingestion time** | when the log stored it | the broker, as it appends | Kafka's `LogAppendTime` |
| **processing time** | when a program handled it | the reading program's own clock | whenever your consumer gets to it |

Event time is the only one that belongs to the sale. The other two belong to the machinery, and they
change if you replay the same sales tomorrow: the event time of a sale rung up at 10:21 is 10:21 for
ever, and its processing time is every moment anybody reads it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of one sale from Natal. Event time: the sale at 11:08. Ingestion time: Kafka stores it at 14:00, when the till reconnects. Processing time: a reader keeping up handles it a second later, and somebody replaying the topic in April handles it then, so the same sale has many processing times.\" data-fig=\"l9-three-clocks\"><defs><marker id=\"l9-three-clocks-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"40\" y1=\"110\" x2=\"690\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"70\" y=\"104\" width=\"400\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"330\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">till offline</text><text x=\"40\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 March</text><circle cx=\"160\" cy=\"110\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"160\" y1=\"102\" x2=\"160\" y2=\"62\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><text x=\"160\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">event time</text><text x=\"160\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">11:08, sold in Natal</text><text x=\"160\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the till's clock</text><circle cx=\"480\" cy=\"110\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"480\" y1=\"102\" x2=\"480\" y2=\"62\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"480\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">ingestion time</text><text x=\"480\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">14:00:07, appended</text><text x=\"480\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the broker's clock</text><circle cx=\"520\" cy=\"110\" r=\"5\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"520\" y1=\"118\" x2=\"520\" y2=\"132\" stroke=\"var(--paper)\" stroke-width=\"1\"></line><text x=\"520\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">processing time</text><text x=\"520\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">14:00:08, a reader keeping up</text><text x=\"520\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the reader's clock</text><line x1=\"560\" y1=\"110\" x2=\"680\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\" marker-end=\"url(#l9-three-clocks-ah-8343)\"></line><circle cx=\"668\" cy=\"110\" r=\"4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></circle><text x=\"668\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a replay in April</text></svg>", "caption": "Event time belongs to the sale and never changes. Ingestion time is fixed once the log has it. Processing time is every moment anybody reads it."}
```

## The field Kafka keeps

A Kafka record carries one timestamp of its own, beside its key and value, and a topic decides what
it means. The setting is `message.timestamp.type`, and it has two values. **`CreateTime`**, the
default, keeps whatever the producer put there; a producer that sets nothing puts its own clock's
reading at the moment it called `produce`. **`LogAppendTime`** throws the producer's value away and
writes the broker's clock at the moment it appended the record.

Make one topic of each, and send two sales from lesson 1's till to both:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic clocks --partitions 1
```

```
ubuntu@stream:~/work$ python tills.py --count 2 --topic clocks
```

The console consumer prints the record's timestamp when asked with `print.timestamp=true`:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic clocks --from-beginning --max-messages 2 --formatter-property print.timestamp=true
```

`CreateTime:` followed by a number is the record's timestamp, in milliseconds since the start of
1970, and the `date` line turns its first ten digits, the seconds, into a date. **Two clocks
disagree by seven months.** The sale says it happened on 2 March 2026 at nine; the record says it
was created on the day the command was run. Both are true. `tills.py` invents its shop clock and
leaves the record's timestamp to the client, which reads the real clock of the machine.

The `appended` topic shows the third possibility:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic appended --from-beginning --max-messages 2 --formatter-property print.timestamp=true
```

Here the label is `LogAppendTime`, and the number is the broker's clock. For a producer that sends
each record the moment it makes it, `CreateTime` and `LogAppendTime` are a few milliseconds apart
and it hardly matters which a topic keeps. **They separate when the producer stamps something other
than its own present**, which is exactly what the till in the next section does.

Processing time never appears in the record at all. It is the clock of the program reading, at the
moment it reads: for the consumer above, a second or two after the sales were sent; for somebody
who replays the topic next month, next month. A result computed by processing time therefore
depends on **when** it was computed, which is the property a batch never had and nobody expects.
