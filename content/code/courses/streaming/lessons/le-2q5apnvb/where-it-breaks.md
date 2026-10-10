---
title: The two places a message is lost or doubled
version: 1
---

**A message from a till to a database crosses two gaps, and each gap is a moment where one side
has done its part and the other does not know it yet.** Every delivery guarantee is a decision
about what to do in those two moments, and nothing else. The network, the disks and Kafka itself
can all be perfect; the gaps are still there, because they are made of two programs that do not
share a memory.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A sale travels from the till's producer to Kafka and from Kafka to a consumer that writes to a database. Two gaps are marked. The first is between the leader writing the sale and the producer receiving the acknowledgement: if the acknowledgement is lost, a retry may write the sale twice. The second is between the consumer processing the sale and committing its offset: depending on which comes first, a crash loses the sale or processes it again.\" data-fig=\"l7-gaps\"><defs><marker id=\"l7-gaps-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l7-gaps-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">till · producer</text><rect x=\"250\" y=\"30\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Kafka</text><rect x=\"470\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">consumer</text><rect x=\"600\" y=\"30\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">database</text><line x1=\"130\" y1=\"42\" x2=\"248\" y2=\"42\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l7-gaps-ah-726)\"></line><text x=\"189\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1  write</text><line x1=\"248\" y1=\"60\" x2=\"132\" y2=\"60\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l7-gaps-ah-0)\"></line><text x=\"189\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2  acknowledge</text><line x1=\"390\" y1=\"50\" x2=\"468\" y2=\"50\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l7-gaps-ah-726)\"></line><line x1=\"580\" y1=\"42\" x2=\"598\" y2=\"42\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l7-gaps-ah-726)\"></line><text x=\"625\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3  process</text><path d=\"M 525 72 Q 460 120 392 72\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l7-gaps-ah-0)\"></path><text x=\"460\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4  commit offset</text><rect x=\"110\" y=\"140\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"200\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">gap 1: ack lost</text><text x=\"200\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">retry → written twice</text><rect x=\"440\" y=\"140\" width=\"220\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">gap 2: crash between 3 and 4</text><text x=\"550\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lost, or processed again</text><line x1=\"189\" y1=\"86\" x2=\"189\" y2=\"138\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><line x1=\"550\" y1=\"124\" x2=\"550\" y2=\"138\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "Two programs that do not share a memory, joined twice: every guarantee is a choice about these two gaps."}
```

## Gap one: the producer and its acknowledgement

The producer sends a sale; the leader writes it and replies; the reply is lost, because a
connection dropped or the leader was replaced before answering. From the producer's side the sale
is in one of two states and it cannot tell which: **written and unacknowledged, or never
written**. It has two choices:

- **send it again**, and if it had been written, the topic now holds it twice;
- **give up**, and if it had not been written, it is gone.

A client with retries switched on, which the Python client has by default, chooses the first.
Lesson 5 watched it do so while a leader died: `acks.py` lost nothing, and nothing promised it
had not written something twice. The cure for this gap belongs to Kafka, and it is the
idempotent producer, two sections on.

## Gap two: the consumer and its commit

A consumer reads a sale, does something with it, and tells Kafka how far it has got by
**committing an offset**, the position of the next message it wants. Lesson 4 met the commit; here
is what it means. The committed offset is the only thing that survives the consumer: start it
again, or start another member of the group in its place, and it resumes from there.

So the order of two steps decides the outcome of a crash between them:

| order | a crash between the two steps | the guarantee |
|---|---|---|
| commit, then process | the sales after the commit are never processed | **at most once** |
| process, then commit | the processed sales are read again after the restart | **at least once** |

Neither order is a bug. **Each one chooses which failure it prefers**, and the next two sections
crash a consumer each way and count the result.

## And what "exactly once" would need

Exactly once is the wish that a crash at either gap changes nothing. It needs the two steps of
each gap to become one step that happens or does not: the write and its acknowledgement, the
processing and its commit. Inside Kafka, where the processing is writing to another topic and the
commit is writing to `__consumer_offsets`, both steps are writes to Kafka and can share a
transaction. Outside Kafka, where the processing is a row in a database or an email, they cannot,
and that edge is the last section of this lesson and the whole of lesson 8.

What none of this covers is a crash that loses the data itself. That was lesson 5: a sale
acknowledged with `acks=all` on three replicas is not lost by a crash, and the gaps here assume
that much.
