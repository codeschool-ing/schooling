---
title: A reply cut short
version: 1
---

A streamed reply can stop in the middle. The connection drops, a proxy times out a long response, the
provider restarts the machine generating it. What arrives is a beginning, and then nothing: no final
chunk, no finish reason, no usage.

The assistant treats a stream with no finish reason as a failed attempt (`IncompleteReply`), records
how many pieces it got, and tries again. labobs can be told to cut the next stream after six pieces:

```
ana@lab:~/obs$ rm -f spans.jsonl; python assistant.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [2]
trace 3a3d425f632e77475611cb4af2f6aa74
ana@lab:~/obs$ python tree.py --attrs | grep -E " ms |ERROR|partial|attempts"
      0   2,313 ms  ask
      0      43 ms    embed
     44       4 ms    search
     48   2,264 ms    generate
                       app.attempts = 2
     48     410 ms      chat extract-1  ERROR IncompleteReply: stream ended after 6 pieces with no finish reason
                         app.partial_pieces = 6
    959   1,353 ms      chat extract-1
  2,312       0 ms    check_citations
```

The customer got the right answer, after 2,313 ms, where the second attempt alone took 1,353. The first attempt delivered
six pieces in 410 ms and stopped; the second, after the backoff, delivered the whole reply.

## What the customer saw depends on the screen

This is where a model call differs from almost any other request. **If the pieces were being shown as
they arrived, the customer read six of them**, perhaps "A gift card is valid for", and then watched
the text disappear and start again, or worse, watched the second attempt get appended to the first.
A retry is invisible for a request whose response is shown only when complete. For a streamed one, it
is a visible stutter, and the screen has to be built to handle it: clear what was shown, or mark the
retry, or not retry at all and offer a button.

So two things belong on the span, and the assistant writes both: **the failure**, with what it was,
and **how far it got** (`app.partial_pieces`). The first counts toward the attempt error rate of the
previous section. The second says whether the customer saw anything before it failed, which is the
difference between a slower answer and a broken one.

## And what it cost

The cut attempt has no usage on its span, because the usage comes in the last chunk and the last
chunk is what was lost. A provider generated those tokens, and may well charge for them. Lesson 3's
bill would count only the second attempt. When the attempt error rate is high and the failures are
mid-stream rather than up front, the bill from the spans undercounts by roughly the same proportion,
and the monthly reconciliation in lesson 3 is where that shows.
