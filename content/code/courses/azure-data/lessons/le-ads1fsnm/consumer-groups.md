---
title: Consumer groups, one position per reader
version: 1
---

**A consumer group is one application's view of the whole event hub**: its own position in every
partition, kept apart from every other application's. Quitanda has two readers of `clicks` that want
nothing to do with each other. The fraud check reads every click within seconds and looks for a
pattern of checkouts; the copy into the lake reads every click too, in its own time, and falls hours
behind on a busy night without anybody minding. If they shared a position, whatever one read the
other would skip. With a group each, both see every event, and neither knows the other exists.

The emulator's configuration declared one group besides `$Default`, the one every hub has, and it is
called `fraud`. `read_clicks.py` from the last section takes the group as its first argument:

```
ana@laptop:~/azure$ python read_clicks.py fraud
partition 0  seq  0  offset    0  c-05  #4  /bakery
partition 0  seq  1  offset  144  c-05  #8  /cart
partition 1  seq  0  offset    0  c-02  #2  /search?q=banana
partition 1  seq  1  offset  152  c-02  #5  /cart
partition 3  seq  0  offset    0  c-17  #1  /fruit
partition 3  seq  1  offset  144  c-17  #3  /fruit/banana
partition 3  seq  2  offset  296  c-17  #6  /cart
partition 3  seq  3  offset  440  c-03  #7  /dairy
partition 3  seq  4  offset  584  c-17  #9  /checkout
partition 3  seq  5  offset  728  c-03  #10 /cart
```

**The same ten clicks, in the same partitions, at the same sequence numbers**, for the second time.
`$Default` read them all a minute ago and nothing in the hub changed. That is the whole idea, and it
is the opposite of a queue, where the second reader would have found an empty one.

## A group that does not exist

The emulator was told about two groups, `$Default` and `fraud`. Ask it for a third:

```
ana@laptop:~/azure$ python read_clicks.py analytics
```

**Nothing at all: no clicks and no error**, even with `on_error` in the program. The reader listened
for five seconds and heard nothing, which looks exactly like a hub with no traffic. On Azure the
service refuses a consumer group that does not exist, and Microsoft's documentation describes a
not-found error naming the entity; this emulator, in this run, answered silence instead. **A reader
that hears nothing has proved nothing**, and the habit worth taking from this is to check, before
trusting a silent reader, that the hub has events: `partitions.py` would have said ten.

On Azure a group is created like any other part of the hub, from the portal, the command line or a
declaration such as the Terraform in the Capture section of this lesson, and not by the first reader
that names it. The tier limits how many a hub may have: Microsoft's documentation gives one on
Basic, which is `$Default` alone, and twenty on Standard, with more on Premium and Dedicated. One
group per application that reads the stream is the rule of thumb, and twenty runs out sooner than
it sounds once every team wants its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"One partition, partition 3 of clicks, drawn as a row of events numbered 0 to 11. New events are appended on the right; events older than the retention are dropped on the left. Two consumer groups point at different places in the same row: $Default has a checkpoint at sequence number 11, and fraud has read up to sequence number 5. Neither position moves the other.\" data-fig=\"l22-groups\"><text x=\"360\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partition 3 of clicks</text><rect x=\"20\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"80\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">older events: dropped</text><text x=\"80\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">after the retention</text><rect x=\"150\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"167\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"190\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"207\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"230\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"247\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"270\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"287\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"310\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"327\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"350\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"367\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><rect x=\"390\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"407\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"430\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"447\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><rect x=\"470\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8</text><rect x=\"510\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"527\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9</text><rect x=\"550\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"590\" y=\"44\" width=\"34\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11</text><line x1=\"632\" y1=\"60\" x2=\"646.0\" y2=\"60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"652,60 646.0,63.0 646.0,57.0\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"700\" y=\"32\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">new events</text><line x1=\"607\" y1=\"140\" x2=\"607.0\" y2=\"86.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"607,80 610.0,86.0 604.0,86.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"597\" y=\"154\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">$Default: checkpoint at 11</text><line x1=\"367\" y1=\"110\" x2=\"367.0\" y2=\"86.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"367,80 370.0,86.0 364.0,86.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"367\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fraud: has read up to 5</text></svg>", "caption": "One log, two positions: each consumer group keeps its own place in every partition, and reading moves nothing in the log."}
```

## How many readers in one group

**Within one group, each partition should have one reader at a time.** Several programs of the same
application, sharing a group, split the partitions between them: with four partitions and two
copies of the fraud check, each copy reads two. The service allows up to five readers on one
partition in one group, and Microsoft's documentation recommends one, because each of the five
receives every event of that partition: five readers is five copies of the work, not a fifth each.

**This is why the number of partitions is the ceiling on parallel reading.** A hub with four
partitions can keep at most four readers of one group busy; a fifth copy of the fraud check gets no
partition of its own and only waits for one of the others to die. Quitanda's choice of four
partitions for `clicks` is therefore also a choice that the fraud check will never run on more than
four machines at once.

Splitting the partitions between copies is a job of its own, called load balancing, and nobody
should write it by hand. The library does it through the same place it keeps its checkpoints, which
is the next section: each copy records which partitions it owns, and takes over a partition whose
owner has stopped renewing its claim.
