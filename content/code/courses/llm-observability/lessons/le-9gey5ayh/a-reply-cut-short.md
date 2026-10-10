---
title: A reply cut short
version: 2
---

A streamed reply can stop in the middle. The connection drops, a proxy times out a long response, the
provider restarts the machine generating it. What arrives is a beginning, and then nothing: no final
chunk, no finish reason, no usage.

The assistant treats a stream with no finish reason as a failed attempt (`IncompleteReply`), records
how many pieces it got, and tries again. flaky.py can be told to cut the next stream after six
pieces, with the SDK still pointed at it from the previous section:

```
ana@dev:~/obs$ curl -s -X POST 127.0.0.1:11435/flaky -d '{"cut_after": 6}'; echo
{"fail_rate": 0, "fail": 0, "status": 503, "cut_after": 6, "seed": 7}
ana@dev:~/obs$ rm -f spans.jsonl; python assistant.py "How long is a gift card valid?"
According to [1], a gift card is valid for two years from the day it was bought.
trace 756285d53ceba6e75566de58790eaa52
ana@dev:~/obs$ python tree.py --attrs | grep -E " ms |ERROR|partial|attempts"
      0   4,373 ms  ask
      1      26 ms    embed
     27       0 ms    search
     28   4,345 ms    generate
                       app.attempts = 2
     28   1,433 ms      chat llama3.2:3b  ERROR IncompleteReply: stream ended after 6 pieces with no finish reason
                         app.partial_pieces = 6
  1,961   2,411 ms      chat llama3.2:3b
  4,372       0 ms    check_citations
```

The customer got the right answer, after 4,373 ms, where the second attempt alone took 2,411. The
first attempt delivered six pieces in 1,433 ms and stopped; the second, after the backoff, delivered
the whole reply.

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
