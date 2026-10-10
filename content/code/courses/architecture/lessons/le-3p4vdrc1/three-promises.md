---
title: At most once, at least once, exactly once
version: 1
---

A consumer receives a message, does some work, and tells the broker it is done. Each of those three
steps can be interrupted by a crash, a network failure or a timeout. **Which step the
acknowledgement sits after decides what a crash costs**, and the three delivery guarantees are the
three answers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two timelines for one message. In the first, the consumer acknowledges before doing the work; it crashes during the work, and the message is gone without being processed: at most once. In the second, the consumer does the work and then acknowledges; it crashes after the work and before the acknowledgement, and the broker delivers the message again, so the work happens twice: at least once.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">at most once: ack first</text><rect x=\"40\" y=\"48\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">receive</text><rect x=\"170\" y=\"48\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ack</text><rect x=\"270\" y=\"48\" width=\"170\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">work…  crash</text><rect x=\"470\" y=\"48\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">message gone, never done</text><text x=\"26\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">at least once: work, then ack</text><rect x=\"40\" y=\"148\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">receive</text><rect x=\"170\" y=\"148\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">work: done</text><rect x=\"300\" y=\"148\" width=\"90\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">crash</text><rect x=\"400\" y=\"148\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">redelivered</text><rect x=\"530\" y=\"148\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">work done twice</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">exactly once needs the work itself to recognise a repeat</text></svg>", "caption": "Where the acknowledgement sits decides which failure you get. Before the work, a crash loses the message; after it, a crash repeats the work."}
```

| guarantee | how it is built | what a crash costs |
| --- | --- | --- |
| **at most once** | acknowledge on receipt, then work | a message that is never processed |
| **at least once** | work, then acknowledge | a message processed twice |
| **exactly once** | at least once, plus a way to recognise and ignore a repeat | only the bookkeeping |

At most once is right when losing a message is cheaper than handling it twice: a metric sample, a
"user is typing" indicator. For anything that changes money, stock or a customer's view of their
order, it is the wrong default, because the loss is silent.

At least once is what RabbitMQ, Kafka and every managed queue give you when a consumer acknowledges
after its work. **It is the honest default**, and the price is duplicates, which arrive in the normal
course of things: a consumer that crashes before its acknowledgement, a network that drops the
acknowledgement on its way, a visibility timeout shorter than a slow handler, a replay like lesson 6's.

## Exactly once is built, not bought

The common belief is that some brokers deliver exactly once. **No broker can, end to end**, because the
end is your code: between "the charge is written" and "the broker hears about it" there is always a
moment in which a crash leaves the two disagreeing, and the broker cannot see inside your transaction
to know which side of that moment it was.

What brokers do offer is narrower and still useful. Kafka's **exactly-once semantics** make a producer's
retries and a read-process-write loop that stays inside Kafka free of duplicates. SQS FIFO queues drop
a repeated message id within five minutes. Both are real, and **neither covers the database your
consumer writes to**, which is where the money is. Effectively-once processing is assembled from at
least once delivery and an idempotent consumer, and the rest of this lesson builds it.
