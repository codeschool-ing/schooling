---
title: What a cap does to JSON
version: 2
---

`num_predict`, which most APIs call `max_tokens`, reads like a request for a short answer. **It is
the point at which writing stops, wherever the writing has got to.** The model writes until it
finishes or until the limit arrives, and the limit does not wait for a sentence, a string or a
brace to close.

First the prompt without a cap, then the same prompt with one, set to 25 with `--set`:

```
ana@lab:~/triage$ pl check runs/v4.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      20    20
all          20    20
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --set num_predict=25 --out runs/cap25.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/cap25.jsonl
ana@lab:~/triage$ pl check runs/cap25.jsonl
check      pass  fail
json         10    30
fields       10    30
labels       10    30
category      9    31
urgency       4    36
all           4    36
```

The prompt id, `651820d7`, is the same in both runs, so the only difference is the cap. Without it,
20 replies passed everything. With it, **four pass**, and only ten are even JSON. `--failures` lists
each failure with its reason, and `grep -c` counts the lines that give this one:

```
ana@lab:~/triage$ pl check runs/cap25.jsonl --failures | grep -c 'cut off at num_predict'
29
ana@lab:~/triage$ pl show runs/cap25.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "Refund duplicate payment for order 447
stop: length, tokens in 123, out 25, 3.3 s
```

Twenty-nine of the thirty `json` failures were cut off; the thirtieth is `t38`, which breaks on its
apostrophe with or without a cap. `t01` stops in the middle of its order number, `447`, and the
closing quote and the closing brace were never written. Everything in the reply up to there is
correct, and **the reply is not JSON**, so a program that reads it gets an exception and nothing
else. The cap made nothing shorter. It removed the end of everything that was longer, and the
replies run longer than 25:

```
ana@lab:~/triage$ python3 stats.py runs/v4.jsonl
runs/v4.jsonl, 40 calls
  tokens in    mean  121.2   total   4846
  tokens out   mean   28.8   total   1153   max 38
  seconds      p50   3.5   p95   4.4   total  143.1
```

A mean of 28.8 tokens and a longest of 38, against a cap of 25: most replies were always going to
be cut.

## The stop reason

Every reply comes back with the reason it stopped, and `pl show` prints it on the last line.
`stop` means the model finished on its own; `length` means the limit finished it. Hosted APIs report
the same thing under their own names: in Anthropic's Messages API it is a `stop_reason` of
`max_tokens`, and in OpenAI's Chat Completions API a `finish_reason` of `length`. **The stop reason
is the one field that says whether a reply is complete**, and reading it costs nothing. `judge()` in
`pl.py` reads it, which is how it can say *cut off* instead of *not a JSON object*.

## What a cap is for

**A cap is a guard against runaway output, never a way to ask for brevity.** Replies that repeat
themselves or keep writing past the format are a familiar failure in practice, and a cap stops one
before it fills a log or a bill. A guard that fires on ordinary traffic is in the wrong place, and
25, here, fired on twenty-nine messages out of forty. Asking for a shorter answer is a different
tool, and it is the next section.
