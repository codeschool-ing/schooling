---
title: What a cap does to JSON
version: 1
---

`max_tokens` reads like a request for a short answer. **It is the point at which writing stops,
wherever the writing has got to.** In the lab, the stand-in writes its whole reply and the harness
cuts it at the cap. A hosted model is stopped the same way: it writes until it finishes or until the
limit arrives, and the limit does not wait for a sentence, a string or a brace to close.

First the prompt without a cap, then the same prompt with one:

```
ana@lab:~/triage$ pl check runs/v4.jsonl
check      pass  fail
json         37     3
fields       37     3
labels       37     3
category     37     3
urgency      34     6
all          34     6
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --set max_tokens=30 --out runs/cap30.jsonl
40 calls, prompt 651820d7, written to runs/cap30.jsonl
ana@lab:~/triage$ pl check runs/cap30.jsonl
check      pass  fail
json          1    39
fields        1    39
labels        1    39
category      1    39
urgency       1    39
all           1    39
ana@lab:~/triage$ pl check runs/cap30.jsonl --failures | grep -c 'cut off at max_tokens'
39
```

`--set` changes a parameter for one run. The prompt id, `651820d7`, is the same in both runs, so
the only difference is the cap. Without it, 34 replies passed everything. With it, **one passes**.
`--failures` lists each failure with its reason, and `grep -c` counts the lines that give this one:
all 39 failures are the same failure, `json`, because the reply was `cut off at max_tokens`.

```
ana@lab:~/triage$ pl show runs/cap30.jsonl t01
│ {
│   "category": "billing",
│   "urgency": "high",
│   "summary": "They were charged twice for order 4471.
stop: max_tokens, tokens in 93, out 30
ana@lab:~/triage$ pl show runs/cap30.jsonl t35
│ {
│   "category": "other",
│   "urgency": "low",
│   "summary": "They love the shop."
│ }
stop: end, tokens in 95, out 29
```

`t01` stops after the full stop of its summary. The closing quote and the closing brace were never
written. Everything in the reply is correct, and **the reply is not JSON**, so a program that reads
it gets an exception and nothing else. `t35` survived for one reason: its summary is four words long,
and the whole reply came to 29 tokens, one under the cap. The cap made nothing shorter. It removed
the end of everything that was longer.

## The stop reason

Every reply comes back with the reason it stopped, and `pl show` prints it on the last line. `end`
means the model finished on its own; `max_tokens` means the limit finished it. Hosted APIs report the
same thing under their own names: in Anthropic's Messages API it is a `stop_reason` of `max_tokens`,
and in OpenAI's Chat Completions API a `finish_reason` of `length`. **The stop reason is the one
field that says whether a reply is complete**, and reading it costs nothing.

## What a cap is for

**A cap is a guard against runaway output, never a way to ask for brevity.** Replies that repeat
themselves or keep writing past the format are a failure every practitioner has seen, and a cap
stops one before it fills a log or a bill. A guard that fires on ordinary traffic is in the wrong
place, and thirty, here, fired on thirty-nine messages out of forty. Asking for a shorter answer is a
different tool, and it is the next section.
