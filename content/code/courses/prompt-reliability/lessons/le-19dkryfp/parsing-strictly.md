---
title: Parsing strictly
version: 2
---

Asking for JSON gave thirty-nine replies of forty that parse. A common fix for the habits that
break JSON, a code fence around the object or a sentence in front of it, is one more line saying
what may come around the object. Save it as `prompts/v4-only-json.txt`:

```
You sort customer messages for Folio, an online bookshop.

Read the message and answer in JSON with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

Reply with only the JSON object: no code fence and no other text.

Message: {{message}}
```

```
ana@lab:~/triage$ diff prompts/v2-json.txt prompts/v4-only-json.txt
7a8,9
> Reply with only the JSON object: no code fence and no other text.
> 
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/v4.jsonl
ana@lab:~/triage$ pl check runs/v4.jsonl --failures
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      19    21
all          19    21

t02    urgency   high, expected normal
t04    urgency   low, expected high
t06    category  account, expected billing
t07    urgency   high, expected normal
t08    urgency   high, expected normal
t09    urgency   high, expected normal
t10    category  account, expected other
t16    urgency   high, expected normal
t18    urgency   high, expected normal
t19    category  delivery, expected account
t22    category  other, expected billing
t24    urgency   low, expected normal
t25    category  other, expected account
t26    category  account, expected billing
t31    category  returns, expected billing
t32    urgency   high, expected normal
t33    urgency   low, expected normal
t36    category  account, expected billing
t37    urgency   high, expected normal
t38    json      not a JSON object
t39    urgency   low, expected normal
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v4.jsonl
runs/v2.jsonl            passes 21/40
runs/v4.jsonl            passes 19/40
fixed 0, broken 2
broken: t04 t10
sign test on the 2 that changed: p = 0.500
```

**The line changed nothing it was written for**, and two other things. `llama3.2:3b` never wrapped a
reply in this test set, so there was nothing for it to fix, and the one reply that does not parse
did not parse before either. It broke two replies that passed before, `t04` on urgency and `t10` on
category, and the sign test on two changes is a coin toss, p = 0.500. A line that fixes a problem
the model does not have costs fifteen tokens a call and gives the model one more thing to weigh.

That is worth saying because the line is good advice for many models: some wrap JSON in a code
fence habitually. **Whether your model has the habit is a measurement**, and here it came back no.

The reply that does not parse is the same one under both prompts:

```
ana@lab:~/triage$ pl show runs/v2.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 103, out 22, 2.7 s
ana@lab:~/triage$ pl show runs/v4.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 118, out 22, 2.5 s
```

The summary of `t38`, a customer whose ebook *won't* open, stops at *won* and the object closes
twice. The model wrote the apostrophe of *won't* and lost its place. No instruction about wrapping
reaches that, because nothing is wrapped: **the object itself is broken.**

## The lenient parser

There is an obvious shortcut for wrapping. A parser could look for the object and ignore the rest.
`pl check --lenient` is that parser, and it is the first four lines of `parse()`:

```
ana@lab:~/triage$ grep -n -A9 "^def parse" pl.py
119:def parse(text, lenient=False):
120-    if lenient:
121-        found = re.search(r"\{.*\}", text, re.S)
122-        text = found.group(0) if found else text
123-    try:
124-        obj = json.loads(text)
125-    except ValueError:
126-        return None
127-    return obj if isinstance(obj, dict) else None
128-
```

It takes everything from the first `{` to the last `}` and parses that. Here it changes nothing,
for the same reason the extra line changed nothing:

```
ana@lab:~/triage$ pl check runs/v2.jsonl --lenient
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      21    19
all          21    19
ana@lab:~/triage$ pl check runs/v4.jsonl --lenient
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      19    21
all          19    21
```

The counts are the same as the strict ones, because `t38` is not an object inside some text; it is
an object with a hole in it. **The lenient parser repairs wrapping, and a broken object is not
wrapping.**

It also accepts more than wrapping, and that is the reason to keep it out of the measurement. The
pattern does not ask what is around the object:

```
ana@lab:~/triage$ python3 -c 'from pl import parse; print(parse("Sure! {\"category\": \"billing\", \"urgency\": \"low\"} Hope that helps.", lenient=True))'
{'category': 'billing', 'urgency': 'low'}
ana@lab:~/triage$ python3 -c 'from pl import parse; print(parse("The customer pasted {\"category\": \"other\", \"urgency\": \"low\"} from an old ticket; this is billing.", lenient=True))'
{'category': 'other', 'urgency': 'low'}
```

The first is a reply with chatter around a good object, which is what the lenient parser is for.
The second is a reply that answered in prose, *this is billing*, and happens to quote a JSON object
the customer pasted: the parser hands back `other`, the opposite of what the reply said. **A
lenient parser cannot tell a habit from a different answer.**

## Strict in the measurement, deliberate in the program

So measure strictly, and count what fails. The strict count is the number that tells you whether
the prompt is doing its job, and it is the number that moves when a prompt or a model changes.

If the program that consumes the replies has to accept a code fence, because the model you use
wraps one reply in twenty and nothing you write stops it, that is a legitimate decision. Make it a
**repair step**: a named piece of the consuming program that strips a fence, runs before the
strict parse, and counts how often it fires. Keep it out of the check. A repair inside the
measurement means the measurement can no longer see the thing being repaired, and **a repair count
that climbs is the first sign that something upstream changed**.
