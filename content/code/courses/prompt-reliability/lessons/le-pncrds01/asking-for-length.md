---
title: Asking for a shorter answer
version: 1
---

The way to get a shorter answer is to ask for it in the prompt, where the model reads it.
`prompts/v4-words.txt` is `v4-only-json.txt` with one line changed:

```
ana@lab:~/triage$ diff prompts/v4-only-json.txt prompts/v4-words.txt
6c6
< - "summary": one sentence saying what the customer needs
---
> - "summary": what the customer needs, in under 12 words
ana@lab:~/triage$ pl run prompts/v4-words.txt cases/dev.jsonl --out runs/words.jsonl
40 calls, prompt d6ee7191, written to runs/words.jsonl
ana@lab:~/triage$ pl show runs/v4.jsonl t37
│ {
│   "category": "delivery",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."
│ }
stop: end, tokens in 101, out 46
ana@lab:~/triage$ pl show runs/words.jsonl t37
│ {
│   "category": "delivery",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says…"
│ }
stop: end, tokens in 103, out 39
```

In the stand-in the rule is crude: it finds the number and cuts the summary at that many words, with
an ellipsis. Count them and it kept twelve where *under 12* allowed eleven, because it reads the
number and not the word in front of it. A language model would more often write a different, shorter
sentence than chop a long one, and it would also miss a word limit now and then. **A length you ask
for is a length you check**, the same way you check a label.

The reply is still JSON, though. The request changed
what was written, and the closing brace was part of what was written. **Asking shapes the answer; the
cap only cuts it.**

## How much shorter

```
ana@lab:~/triage$ pl latency runs/v4.jsonl
calls 40
p50 1170 ms   p95 1324 ms   max 1473 ms
output tokens: mean 38.0, max 50
ana@lab:~/triage$ pl latency runs/words.jsonl
calls 40
p50 1136 ms   p95 1255 ms   max 1323 ms
output tokens: mean 36.8, max 48
ana@lab:~/triage$ pl compare runs/v4.jsonl runs/words.jsonl --answers
40 cases, same answer 40, different answer 0
```

`pl latency` prints the stand-in's computed response times, and on its last line the output tokens of
the run. The mean went from 38.0 to 36.8, a little over one token a reply, and the longest reply from
50 to 48. That is small, and the figure in *Tokens, not words* says why: the summary is the only part
of the reply that can shrink, and plenty of summaries were under twelve words already. `--answers`
compares what each reply said rather than whether it passed: all forty categories came out the same,
so the change touched the length and nothing else.

## You need both

A request does not replace the cap. Here is the shorter prompt under the same cap of thirty:

```
ana@lab:~/triage$ pl run prompts/v4-words.txt cases/dev.jsonl --set max_tokens=30 --out runs/words30.jsonl
40 calls, prompt d6ee7191, written to runs/words30.jsonl
ana@lab:~/triage$ pl check runs/words30.jsonl
check      pass  fail
json          1    39
fields        1    39
labels        1    39
category      1    39
urgency       1    39
all           1    39
```

One pass in forty, the same as before. Twelve words of summary inside its frame are still more than
thirty tokens, and a reply that obeys the request exactly is still cut by a cap set below it. **Ask
for the length you want, then set the cap well above it.** The request decides how long the answer
is; the cap exists for the reply that ignores the request.
