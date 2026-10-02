---
title: What examples leak
version: 1
---

The stand-in copies the shape of the first example's answer. **That includes things you did not
mean as shape.** Look at how `t17` came back under the prompt with examples:

```
ana@lab:~/triage$ pl show runs/v3.jsonl t17
│ {"category": "delivery", "urgency": "high", "summary": "Their order was dispatched ten days ago and still hasn't arrived."}
stop: end, tokens in 247, out 38
```

One line, the keys in the examples' order, a space after each colon. The prompt without examples
produced the same JSON across five lines. Nothing checks for that and nothing needs to, but it is
the first sign of what the next file does on purpose.

## One field nobody meant

`prompts/v3-leaky.txt` is `v3-examples.txt` with one change. Somebody copied the first example out
of a real ticket and kept the order number:

```
ana@lab:~/triage$ grep -n order prompts/v3-leaky.txt
9:Message: I paid for express delivery but the order came by normal post.
10:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "order": "4471"}
ana@lab:~/triage$ pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl
40 calls, prompt 0acdc3c7, written to runs/leaky.jsonl
ana@lab:~/triage$ pl check runs/leaky.jsonl
check      pass  fail
json         40     0
fields        0    40
labels        0    40
category      0    40
urgency       0    40
all           0    40
ana@lab:~/triage$ pl show runs/leaky.jsonl t04
│ {"category": "account", "urgency": "high", "summary": "They can't log in.", "order": "4471"}
stop: end, tokens in 246, out 39
```

**Every one of the forty replies carries `"order": "4471"`**, including the customer who cannot
log in and has no order at all. The model had no value for a field it was shown, so it copied the
one it had. In the stand-in that is a rule; in a real model it is a tendency: names, dates and numbers from examples turn up in answers about something else.

Two things in that transcript are worth keeping.

**The check caught it because it is strict.** `fields` fails a reply with a field nobody asked
for. A check that only looked for the fields it needed would have passed all forty, and the order
number would have reached whatever reads the JSON next.

**And every reply failed the same way.** A defect in an example is not an occasional error: it is
copied into every answer. That makes it loud in a test set and invisible in a demo, where you try
one message and the extra field looks like a feature.

## Keeping examples from teaching the wrong thing

- Vary whatever should vary. If all three summaries began with *Wants*, every summary would.
  The examples here start with *Wants*, *Wants* and *Asks*, and that is already a pattern.
- Remove what belongs to one customer: names, order numbers, dates, amounts. Replace them with
  values that are obviously examples, or leave them out.
- Make the examples answer exactly what the prompt asks for, field for field. An example is
  the strongest instruction in a prompt, so an example that disagrees with the description wins.
- Check strictly, so that what an example leaks fails a test instead of reaching a reader.
