---
title: The trace id is a handle
version: 2
---

`assistant.py` prints a trace id under every reply. In production it goes further than the terminal:
**it is returned to whatever called the assistant**, and from there it ends up on the customer's
screen, in the support ticket, and in every log line written while the request ran. It is the one
value that joins all of those to the record of what happened.

## Finding a trace again

One more question, the one a customer might ask about a gift card, and the file holds sixteen spans
from three traces:

```
ana@dev:~/obs$ python assistant.py "How long is a gift card valid?"
According to [1], a gift card is valid for two years from the day it was bought.
trace 7816f4d9ea7282a767b310a42b569fd3
ana@dev:~/obs$ wc -l spans.jsonl
16 spans.jsonl
ana@dev:~/obs$ python -c "import json; print(sorted({json.loads(l)[\"trace\"] for l in open(\"spans.jsonl\")}))"
['5ea30205e6a9ef29c4b98b45d1595ab9', '7816f4d9ea7282a767b310a42b569fd3', 'b0f29bf4b40469cb859c35e290b1bcec']
```

A trace id is 32 hexadecimal characters, and nobody reads that out on the telephone. The first
eight are enough to find one trace among thousands, which is what a support screen shows as a
reference:

```
ana@dev:~/obs$ grep -c 5ea30205 spans.jsonl
6
ana@dev:~/obs$ python tree.py 5ea30205
trace 5ea30205e6a9ef29c4b98b45d1595ab9   start(ms) took(ms)
      0   3,021 ms  ask
      0      25 ms    embed
     26       4 ms    search
     31   2,990 ms    generate
     31   2,990 ms      chat llama3.2:3b
  3,021       0 ms    check_citations
```

A customer writes in to say the assistant told them they would have to pay for the postage of a
return, and the website says returns are free. If the screen showed them a reference, the support
team types it and gets the tree above, and with `--attrs` everything section 08 read: the release,
the chunk, the reply, the time. Without it, they search by time and by words, among everybody else
who asked about returns that afternoon.

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
