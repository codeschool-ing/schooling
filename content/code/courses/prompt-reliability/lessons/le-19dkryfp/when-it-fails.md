---
title: When a reply does not parse
version: 2
---

One reply in forty did not parse under every prompt in this lesson that asks for JSON. At a thousand messages a day,
that rate is about twenty-five replies a day the router cannot read. **The consuming program needs
a decision for that case written down before it happens**, because the alternative is whatever the
code does by accident.

There are three reasonable decisions and one bad one.

## Retry

Call the model again with the same message. That works only if the second call can come back
different, and at temperature 0 it cannot. `--samples 3` asks three times, with three seeds:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/retry.jsonl --samples 3
120 calls, prompt 651820d7, llama3.2:3b, written to runs/retry.jsonl
ana@lab:~/triage$ pl check runs/retry.jsonl --failures | grep json
json        117     3
t38    json      not a JSON object
t38#1  json      not a JSON object
t38#2  json      not a JSON object
```

`t38` fails all three times, with the same broken object. At temperature 0 the model always takes
its most likely next token, so the seed has nothing to choose between, and asking again asks the
same question and gets the same answer. Raise the temperature and the draws differ:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/warm.jsonl --samples 3 --set temperature=0.8
120 calls, prompt 651820d7, llama3.2:3b, written to runs/warm.jsonl
ana@lab:~/triage$ pl check runs/warm.jsonl --failures | grep json
json        118     2
t13#2  json      not a JSON object
t17#2  json      not a JSON object
ana@lab:~/triage$ pl check runs/warm.jsonl
check      pass  fail
json        118     2
fields      118     2
labels      117     3
category     93    27
urgency      58    62
all          58    62
```

At 0.8, `t38` parsed on all three tries, and two other replies, `t13` and `t17`, broke on their
third. The failures moved; they did not go away. And look at the bottom line: 58 passes in 120,
against 19 in 40 at temperature 0, about the same rate with more of it left to chance. Lesson 8 is
about what temperature does to the labels.

So **a retry is a fresh chance only when something changes**: the draw, the prompt, or the model. A
second call that includes the failed reply and the parser's complaint is a different prompt, and
is the retry worth trying first. Whatever you choose, cap the number of retries, and count them.

## Fall back

Have a path that does not need the model's answer. For triage, that is the unsorted queue, where a
person reads the message. **A message in the wrong queue is worse than a message in no queue**:
the second is late, and the first is late and also lost among the messages somebody else is
working.

## Route to a person

For a reply that parses but fails `labels`, a category nobody has heard of, the right destination
is the same. Send the raw reply with the message, so the person can see what went wrong and so the
case can be added to the test set later.

## Never guess

The bad decision is the one that looks clever: search the unparseable text for `billing` or
`high` and act on what you find. It turns every format failure into a content decision nobody
checked, and it is the lenient parser of the last section moved into production, where nothing
counts what it does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"What the consuming program does with a reply, left to right. The reply goes through a repair step that strips a code fence and counts how often it does, then a strict parse, then the fields and labels checks, and is routed by its category. A reply that fails the strict parse, or fails fields or labels, goes down to the unsorted queue, where a person reads the message. Nothing guesses.\"><defs><marker id=\"l03a-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">One reply, through the consuming program</text><rect x=\"20\" y=\"44\" width=\"100\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reply</text><path d=\"M122 70.0 L146 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"150\" y=\"44\" width=\"130\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">repair step</text><text x=\"215.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">counted</text><path d=\"M282 70.0 L306 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"310\" y=\"44\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">strict parse</text><path d=\"M432 70.0 L456 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"460\" y=\"44\" width=\"110\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fields, labels</text><path d=\"M572 70.0 L596 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"600\" y=\"44\" width=\"100\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">route</text><text x=\"650.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">by category</text><rect x=\"300\" y=\"160\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">unsorted queue: a person reads it</text><path d=\"M370 98 L370 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><text x=\"378\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fails</text><path d=\"M515 98 L515 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><text x=\"523\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fails</text></svg>", "caption": "Every path ends somewhere decided. The repair step is part of the program and is counted; the measurement in the harness stays strict and never sees it."}
```

## Structured-output modes

Several providers' APIs offer a JSON mode or a structured-output mode, in which the model's
decoding is constrained so that the reply is valid JSON, or matches a schema you supply. Ollama
has one: its `format` field takes a JSON schema. This program sends one case with the schema of
this course's answer. Save it as `schema.py`:

```python
"""schema: one case through Ollama's structured-output mode, which constrains
the reply to a JSON schema while the model writes it."""
import json
import sys
import urllib.request

from pl import DEFAULTS, LABELS, OLLAMA, read_jsonl, read_prompt, render

SCHEMA = {"type": "object", "required": ["category", "urgency", "summary"],
          "additionalProperties": False,
          "properties": {"category": {"enum": LABELS["category"]},
                         "urgency": {"enum": LABELS["urgency"]},
                         "summary": {"type": "string"}}}

prompt, cases, case_id = sys.argv[1:4]
case = next(c for c in read_jsonl(cases) if c["id"] == case_id)
_, template = read_prompt(prompt)
body = {"model": DEFAULTS["model"], "stream": False, "format": SCHEMA,
        "options": {"temperature": 0, "seed": 1},
        "messages": [{"role": "user", "content": render(template, {"message": case["message"]})}]}
req = urllib.request.Request(OLLAMA + "/api/chat", json.dumps(body).encode(),
                             {"Content-Type": "application/json"})
print(json.load(urllib.request.urlopen(req))["message"]["content"])
```

```
ana@lab:~/triage$ python3 schema.py prompts/v2-json.txt cases/dev.jsonl t38
{"category": "returns", "urgency": "high", "summary": "Ebook won't open on reader, needs replacement or refund"}
ana@lab:~/triage$ python3 schema.py prompts/v2-json.txt cases/dev.jsonl t17
{"category": "delivery", "urgency": "high", "summary": "Order has not arrived ten days after dispatch and is needed for a birthday on Saturday"}
```

`t38` comes back whole, apostrophe and all, because the decoder was not allowed to close the string
early: a token that would have broken the schema was never a candidate. `t17` comes back word for
word as it did without the schema. **It constrains the format and not the answer.** A reply that is
perfect JSON with the wrong category still passes every check the program can run in production,
which is why the test set and its person-given labels stay. Lesson 6 shows the other way a reply
fails to parse, cut off at the output limit, and no format mode can complete an object the model
was stopped from finishing.
