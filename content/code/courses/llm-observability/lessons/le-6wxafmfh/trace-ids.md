---
title: The trace id is a handle
version: 1
---

`assistant.py` prints a trace id under every reply. In production it goes further than the terminal:
**it is returned to whatever called the assistant**, and from there it ends up on the customer's
screen, in the support ticket, and in every log line written while the request ran. It is the one
value that joins all of those to the record of what happened.

## Finding a trace again

After this lesson's three questions, the file holds sixteen spans from three traces:

```
ana@lab:~/obs$ wc -l spans.jsonl
16 spans.jsonl
ana@lab:~/obs$ python -c "import json; print(sorted({json.loads(l)[\"trace\"] for l in open(\"spans.jsonl\")}))"
['1a218c3902fa97519a4b28d0bd1f155f', '8caa5cd5a78cdc79d1b3e420a1e2399f', 'ce0b5661415f1a83fc75d4de2668184a']
```

A trace id is 32 hexadecimal characters, and nobody reads that out on the telephone. The first
eight are enough to find one trace among thousands, which is what a support screen shows as a
reference:

```
ana@lab:~/obs$ grep -c 8caa5cd5 spans.jsonl
6
ana@lab:~/obs$ python tree.py 8caa5cd5
trace 8caa5cd5a78cdc79d1b3e420a1e2399f   start(ms) took(ms)
      0   1,237 ms  ask
      0      51 ms    embed
     52       5 ms    search
     57   1,180 ms    generate
     57   1,180 ms      chat extract-1
  1,237       0 ms    check_citations
```

A customer writes in to say the assistant gave a strange answer to their gift card question. If the
screen showed them a reference, the support team types it and gets the tree above: the release, the
chunks, the reply, the time. Without it, they search by time and by words, among everybody else who
asked about gift cards that afternoon.

## What gets joined by it

The trace id is the key everything in the next lessons hangs from:

- **Feedback** (lesson 5). A thumbs down arrives seconds after the reply, from the browser. It
  carries the trace id it is about, and the join is exact. Joining it by time or by user instead
  attaches it to the wrong answer whenever the same person asked twice in a minute.
- **Scores** (lessons 8 and 9). An evaluation of a reply is recorded against the trace, so that a
  low score leads straight to the inputs that produced it.
- **Log lines.** OpenTelemetry's logging integration puts the current trace id and span id on every
  log record written inside a span; `observability` lesson 8 sets it up. A log line with the trace id
  on it is a log line that can be found from the trace and the other way round.

The rule this course follows from here on is the one the whole catalogue follows for its own data:
**things join by a stable id, never by a time, a position or a piece of text**. Two requests can have
the same words and the same second. They never have the same trace id.

## What a trace id is not

It is not a secret and not a permission: knowing one should let a member of staff find a trace, and
nothing else. Anything that shows traces to someone has to check who is asking, exactly as it would
for the conversation itself, because a trace with the question on it is the conversation. Lesson 2
is about what that implies for what is kept.
