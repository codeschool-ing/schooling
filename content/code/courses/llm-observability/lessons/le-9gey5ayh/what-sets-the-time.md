---
title: What sets the time
version: 2
---

A percentile says how slow; it does not say why. For a model call, two things are worth checking first,
because they are on every span already: how much was read and how much was written. `drivers.py`
groups the week's calls by each and takes the median of each group:

```python
"""drivers.py: what the length of a model call goes with, in the week's spans."""
import json
from statistics import median

chats = [s for s in map(json.loads, open("spans.jsonl"))
         if s["name"].startswith("chat ") and s["status"] != "ERROR"]
a = lambda s, k: s["attributes"][k]


def table(title, key, value, edges):
    print(title)
    for lo, hi in zip(edges, edges[1:]):
        xs = [value(s) for s in chats if lo <= key(s) < hi]
        if xs:
            print(f"  {lo:4} to {hi - 1:4}  {len(xs):5} calls  median {median(xs):6.0f} ms")


table("whole call, by output tokens", lambda s: a(s, "gen_ai.usage.output_tokens"),
      lambda s: (s["end"] - s["start"]) / 1e6, [0, 20, 40, 60, 80, 100, 200])
table("first token, by input tokens", lambda s: a(s, "gen_ai.usage.input_tokens"),
      lambda s: a(s, "app.time_to_first_token_ms"), [0, 100, 200, 300, 400, 600])
cold = [s for s in chats if a(s, "app.time_to_first_token_ms") > 3000]
print(f"first token over 3 s: {len(cold)} of {len(chats)} calls")
```

```
ana@dev:~/obs$ python drivers.py
whole call, by output tokens
     0 to   19    112 calls  median   2095 ms
    20 to   39     63 calls  median   3250 ms
    40 to   59     72 calls  median   4929 ms
    60 to   79      3 calls  median   8068 ms
    80 to   99     15 calls  median   9482 ms
first token, by input tokens
     0 to   99     21 calls  median    237 ms
   100 to  199    109 calls  median    744 ms
   200 to  299    125 calls  median    829 ms
   300 to  399     10 calls  median   1358 ms
first token over 3 s: 0 of 265 calls
```

**The whole call follows the output.** From under 20 tokens to 80 or more, the median goes from
2,095 ms to 9,482, a near-straight line of about 100 ms a token. That is the second clock,
multiplied. A long answer is a slow answer, whatever else is true.

**The first token follows the input.** From 100 input tokens to over 300, the median first token
goes from 744 ms to 1,358. Reading is faster than writing, but on four cores not by as much as on a
provider's hardware: a prompt three times as long costs more than half a second. The smallest
prompts, under 100 tokens, are the support team's summaries, and they come back fastest for a second
reason besides their size. Only two conversations recur all week, and Ollama keeps what it computed
for the start of the last prompt and reuses it when the next one starts the same way; that is the
cache count lesson 1's instrumented span reported. With prompts of tens of thousands of tokens, as
in an agent carrying a long history, the same slope adds up to minutes on a machine like this one.

And **not one call in 265 waited over three seconds** for its first token. In production that line
is rarely empty: a few calls wait far longer than their size explains, in every group, which is the
signature of a cause outside the request, the provider, the network, a queue. Here the model had the
machine to itself and never left memory, so there were none. When there are, no change to the prompt
will remove them.

## What this decides

Lesson 3 found that the input was most of the **cost**. This section finds that the output is most of
the **time**. The two levers are different, and which one to pull depends on which complaint is being
answered:

| to make it | change | because |
|---|---|---|
| cheaper | the input: fewer sources, a shorter system prompt | input tokens are most of the bill |
| feel faster | the time to the first token: shorter prompt, a nearer region, streaming to the screen | it is the empty-screen wait |
| finish sooner | the output: ask for shorter answers, cap `max_tokens` | every token adds its 100 ms |
| hurt less in the tail | timeouts and a retry, the last sections | the tail is not caused by the request |

`prompt-reliability` lesson 16 and `agents-mcp` lesson 18 pull these levers on their own systems and
measure the result. What this course adds is that the spans already hold what is needed to choose: no
separate experiment, just a group-by on a week of production.
