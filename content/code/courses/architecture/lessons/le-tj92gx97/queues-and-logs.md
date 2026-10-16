---
title: Two ideas of a broker
version: 1
---

"Message broker" names two different machines, and treating them as one is the most common mistake
in choosing between them. **One is a queue, the other is a log**, and almost every difference between
RabbitMQ and Kafka follows from that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two drawings. Above, a queue: messages one to four wait in a line; consumer A takes message one and consumer B takes message two, and each message, once acknowledged, is removed from the queue. Below, a log: messages at offsets 0 to 5 stay in the log; reader group email is at offset 4 and reader group analytics at offset 2, each with its own position, and nothing is removed when it is read.\"><defs><marker id=\"l6-models-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">a queue: RabbitMQ, SQS</text><rect x=\"150\" y=\"46\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"160\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"186\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m4</text><rect x=\"222\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"248\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m3</text><rect x=\"284\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m2</text><rect x=\"346\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"372\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m1</text><rect x=\"520\" y=\"40\" width=\"150\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer A</text><rect x=\"520\" y=\"74\" width=\"150\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer B</text><path d=\"M412 62 L518 53\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><path d=\"M412 74 L518 87\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><text x=\"280\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">acknowledged, then deleted</text><text x=\"26\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">a log: Kafka</text><rect x=\"60\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 0</text><rect x=\"150\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 1</text><rect x=\"240\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 2</text><rect x=\"330\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 3</text><rect x=\"420\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 4</text><rect x=\"510\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 5</text><path d=\"M460 250 L460 212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><text x=\"460\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">group email: 4</text><path d=\"M280 250 L280 212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><text x=\"280\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">group analytics: 2</text><text x=\"620\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing deleted</text></svg>", "caption": "A queue gives each message to one consumer and deletes it when acknowledged. A log keeps every message, and each reader keeps its own place."}
```

## The queue

A **queue** holds messages until a consumer takes them. Each message goes to one consumer; when the
consumer acknowledges it, the broker deletes it. Several consumers on one queue are **competing
consumers**: they share the work, each message handled once, by whichever of them takes it. A message
nobody has acknowledged is still the broker's responsibility, and it hands it to someone else if its
consumer disappears.

The queue's model is **work to be done**. Once done, there is no reason to keep it. RabbitMQ, ActiveMQ,
Amazon SQS and Azure Service Bus queues are queues.

## The log

A **log** is an append-only sequence of messages, each at a numbered position, its **offset**. Reading
a message does not remove it; messages leave only when they are older than the retention period, seven
days by default in Kafka, or when the log outgrows a size limit. Each reader remembers its own offset,
so any number of readers can go through the same messages at their own pace, and a reader can go back
and read them again.

The log's model is **a record of what happened**. The same `OrderPlaced` events can feed the e-mail
service today and, next month, a fraud model that did not exist when they were written, reading from
the beginning. Apache Kafka, Redpanda, Amazon Kinesis and Azure Event Hubs are logs.

| question | queue | log |
| --- | --- | --- |
| what happens to a message once it is processed? | deleted | kept until retention expires |
| how do two services both get every message? | one queue each, both bound to the same source | each reads the same log with its own position |
| can a consumer re-read last week's messages? | no; they are gone | yes, by moving its offset back |
| what is the unit of parallel work? | consumers on one queue, any number | partitions of the log, later in this lesson |
| what does the broker track? | each message's state | each reader's offset |

The two have borrowed from each other, RabbitMQ now has **streams**, which are logs, and Kafka has
been getting queue-like sharing, but the defaults of each still follow its original idea, and the
defaults are what a system mostly runs on.
