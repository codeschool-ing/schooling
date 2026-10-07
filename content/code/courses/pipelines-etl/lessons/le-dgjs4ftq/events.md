---
title: Events: at least once, roughly in order
version: 1
---

The website's collector writes one line per click, view and purchase, and the lab drops a day of
them in `landing/events/`. An event is a fact about a moment: it is never updated and never
deleted, which makes it the easiest source to read and the easiest to count wrong.

```
ana@vm:~/etl$ wc -l landing/events/2026-03-05.jsonl
2438 landing/events/2026-03-05.jsonl
ana@vm:~/etl$ python -c "import json,collections; ids=collections.Counter(json.loads(l)['event_id'] for l in open('landing/events/2026-03-05.jsonl')); print(sum(1 for c in ids.values() if c > 1), 'event ids appear twice')"
23 event ids appear twice
ana@vm:~/etl$ python -c "import json; ev=[json.loads(l) for l in open('landing/events/2026-03-05.jsonl')]; late=[e for e in ev if not e['occurred_at'].startswith('2026-03-05')]; print(len(late), 'events from another day'); print(late[0])"
3 events from another day
{'event_id': 'e0010088', 'occurred_at': '2026-03-04T23:01:17-03:00', 'session': 's283220', 'type': 'view', 'book_id': 65}
```

Two of the three numbers are the reason events need handling of their own.

## Twice

**Twenty-three event ids appear twice.** Nobody clicked twice: the collector sent an event, did
not hear back in time, and sent it again, and both copies landed. That behaviour has a name,
*at-least-once delivery*, and it is what almost every event system guarantees, because the
alternative — at most once — loses events whenever a network hiccups, and a lost event leaves no
trace to find.

So the pipeline gets the job of making "at least once" into "exactly once", and it can only do
that with an identifier that the producer gave the event. **`event_id` is the most important field
in the file**: without it, two identical clicks a second apart and one click sent twice are
indistinguishable. Lesson 15 uses it to load events so that a duplicate does no harm.

## Late

**Three events in the file for 5 March happened on the 4th.** A phone on a train sent its clicks
when it found a signal; the collector wrote them when they arrived, into the file of the day they
arrived. That gives every event two times:

- **event time**, `occurred_at`, when it happened;
- **processing time**, when the pipeline saw it — here, which file it landed in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-late\" aria-label=\"Two time lines, one above the other. The top one is when events happened, the bottom one is which file they landed in. Most events drop straight down into the file of their own day. One event that happened at 23:01 on 4 March slants across midnight and lands in the file for 5 March.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><path d=\"M60.0 60.0 L690.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"60.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">event time: when it happened</text><path d=\"M60.0 190.0 L690.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"60.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">processing time: the file it landed in</text><path d=\"M380.0 40.0 L380.0 210.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"220.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 March</text><text x=\"535.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5 March</text><path d=\"M110.0 66.0 L110.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"110.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M170.0 66.0 L170.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"170.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M240.0 66.0 L240.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"240.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M300.0 66.0 L300.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"300.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M430.0 66.0 L430.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"430.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M500.0 66.0 L500.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"500.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M560.0 66.0 L560.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"560.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M630.0 66.0 L630.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"630.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"350.0\" cy=\"60.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M350.0 66.0 L455.0 182.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"350.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">23:01, sent from a train</text></svg>", "caption": "Group by when it happened, not by where it landed, or a late event counts on the wrong day."}
```


A report of views per day must group by event time, or a late event counts on the wrong day. And
then the 4th is never quite finished: an event about it can still arrive tomorrow. Streaming
systems close a period after a fixed delay they call a *watermark* and either drop or separately
handle what arrives later; a nightly batch can do the simpler thing and reload the last few days
each night. **Either way the decision is how late is too late**, and it has to be written down.

## In order, roughly

Events within a file are in the order they were written, which is close to the order they
happened and not the same. A pipeline that assumes "the last event for a session is its latest
state" will one day be wrong by one event. Sort by event time when the order matters; it is cheap,
and it is never wrong.

Kafka, Kinesis and Pub/Sub are what carry events between systems at scale, with partitions,
consumer offsets and retention instead of a file. By default they keep the same three properties — at least
once, late, roughly in order — and the lab's file shows all three without any of the machinery. None
of them is installed here, and nothing in this course ran on them.
