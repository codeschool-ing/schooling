---
title: The format is a contract
version: 2
---

A prompt that asks for JSON is making a promise to whatever reads the reply next. Three lines of
`v2-json.txt` are the promise:

```
ana@lab:~/triage$ sed -n 3,6p prompts/v2-json.txt
Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs
```

**The checks are the other side of it**: what the program reading the reply relies on, written as
code. They are in `pl.py`, in one function:

```
ana@lab:~/triage$ grep -n -A20 "^def judge" pl.py
130:def judge(row, expect, lenient=False):
131-    """The first check a reply fails, and why; (None, None) if it passes them all."""
132-    obj = parse(row["text"], lenient)
133-    if obj is None:
134-        return "json", "cut off at num_predict" if row["stop"] == "length" else "not a JSON object"
135-    missing = [k for k in LABELS if k not in obj]
136-    extra = [k for k in obj if k not in LABELS and k != "summary"]
137-    if missing:
138-        return "fields", "missing " + ", ".join(missing)
139-    if extra:
140-        return "fields", "unexpected " + ", ".join(extra)
141-    for k in LABELS:
142-        if obj[k] not in LABELS[k]:
143-            return "labels", "%s %r" % (k, obj[k])
144-    for k in LABELS:
145-        if obj[k] != expect[k]:
146-            return k, "%s, expected %s" % (obj[k], expect[k])
147-    return None, None
148-
149-
150-def verdicts(path, lenient=False):
```

The `fields` check requires two keys, `category` and `urgency`, and refuses any key outside them
and `summary`. `labels` requires each value to come from its list. Those are the three things a
JSON schema says most often: **which keys must be there, which may be there, and which values each
one may take.** The check of lesson 1 that caught an order number copied out of an example was the
second of them, and it still does:

```
ana@lab:~/triage$ pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl
40 calls, prompt 0acdc3c7, llama3.2:3b, written to runs/leaky.jsonl
ana@lab:~/triage$ pl check runs/leaky.jsonl --failures | grep fields
fields       34     6
t01    fields    unexpected order
t08    fields    unexpected order
t16    fields    unexpected order
t31    fields    unexpected order
```

## Read the contract, not the prompt

The check is not a copy of the prompt, and the differences are decisions. The prompt asks for three
fields; the check requires two. A reply with no `summary` passes `fields`, because the program that
routes a message needs the category and the urgency and nothing else, and the summary is there for
the person who opens the ticket. **Writing down what the reader actually requires is how you find
out what the prompt can afford to be loose about.**

Once a reply has passed the first three checks, the program may assume an object, the two keys, a
value from each list, and no keys it has never heard of. It may not assume the summary is there,
that it is accurate, or that the category is right.

## Two checks that run in production, and two that do not

The last two checks, `category` and `urgency`, compare a reply with the answer a person gave. In
the test set that answer exists. **In production nobody has labelled the message yet**, which is the
whole reason a model is sorting it. So `json`, `fields` and `labels` are checks the consuming program
can run on every reply it ever receives, and should. `category` and `urgency` can only be
measured on a test set; lessons 11 and 12 are about doing that well.

That split is the practical meaning of a contract. **The format can be verified on every call; the
content can only be estimated.** A reply that breaks the format is caught at the door. A reply with
a confident wrong category walks straight through it.
