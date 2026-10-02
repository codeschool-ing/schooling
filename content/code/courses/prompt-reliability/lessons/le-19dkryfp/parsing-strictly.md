---
title: Parsing strictly
version: 1
---

Lesson 1 found thirteen replies to `v2-json.txt` with the right content in the wrong wrapping: a
code fence around the object, or a sentence in front of it. The description said JSON and never
said what may come around it. `v4-only-json.txt` says it, in one line:

```
ana@lab:~/triage$ diff prompts/v2-json.txt prompts/v4-only-json.txt
7a8,9
> Reply with only the JSON object: no code fence and no other text.
> 
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl
40 calls, prompt 651820d7, written to runs/v4.jsonl
ana@lab:~/triage$ pl check runs/v4.jsonl --failures
check      pass  fail
json         37     3
fields       37     3
labels       37     3
category     37     3
urgency      34     6
all          34     6

t08    json      not JSON
t14    urgency   normal, expected low
t19    json      not JSON
t22    json      not JSON
t24    urgency   low, expected normal
t28    urgency   normal, expected low
ana@lab:~/triage$ pl compare runs/v2.jsonl runs/v4.jsonl
runs/v2.jsonl            passes 24/40
runs/v4.jsonl            passes 34/40
fixed 11, broken 1, still passing 23, still failing 5
broken: t19
sign test on the 12 that changed: p = 0.006
```

Thirty-seven of forty parse now, against twenty-seven, and the sign test puts the change at p =
0.006. **The line made the habits rarer, not gone**: three replies still came back wrapped, and
`t19` is one of them, a reply that parsed under `v2-json.txt` and broke under the stricter prompt:

```
ana@lab:~/triage$ pl show runs/v4.jsonl t19
│ ```json
│ {
│   "category": "account",
│   "urgency": "high",
│   "summary": "Someone else seems to have logged into their account and changed the delivery address."
│ }
│ ```
stop: end, tokens in 94, out 46
```

## The lenient parser

There is an obvious shortcut. Most of the failures are a good object with something around it, so
a parser could look for the object and ignore the rest. `pl check --lenient` is that parser, and it
is short:

```
ana@lab:~/triage$ grep -n -A12 "^def parse" promptlab/cli.py
188:def parse(text, lenient=False):
189-    """The reply as a dict, or (None, why)."""
190-    t = text
191-    if lenient:
192-        m = re.search(r"\{.*\}", text, re.S)
193-        if m:
194-            t = m.group(0)
195-    try:
196-        obj = json.loads(t)
197-    except ValueError:
198-        return None, "not JSON"
199-    if not isinstance(obj, dict):
200-        return None, "not an object"
```

It takes everything from the first `{` to the last `}` and parses that. Run over both prompts:

```
ana@lab:~/triage$ pl check runs/v2.jsonl --lenient
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     40     0
urgency      37     3
all          37     3
ana@lab:~/triage$ pl check runs/v4.jsonl --lenient
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     40     0
urgency      37     3
all          37     3
```

**Under the lenient parser the two prompts are the same prompt**: forty of forty parse in both,
and thirty-seven pass everything in both. The improvement the strict check measured at p = 0.006
has disappeared, because the lenient parser measures the content and throws the wrapping away
before counting. If you had only ever looked at lenient numbers, you would never have written the
line in `v4-only-json.txt`, and you could not tell whether a later edit undid it.

It also accepts more than wrapping. The pattern does not ask what is around the object, so a reply
that apologises for a paragraph and puts an object in the middle of it passes, and so does a reply
that answers in prose and happens to quote a JSON object from the customer's message. **A lenient
parser cannot tell a habit from a different answer.**

## Strict in the measurement, deliberate in the program

So measure strictly, and count what fails. The strict count is the number that tells you whether
the prompt is doing its job, and it is the number that moves when a prompt or a model changes.

If the program that consumes the replies has to accept a code fence, because the model you use
wraps one reply in twenty and nothing you write stops it, that is a legitimate decision. Make it a
**repair step**: a named piece of the consuming program that strips a fence, runs before the
strict parse, and counts how often it fires. Keep it out of the check. A repair inside the
measurement means the measurement can no longer see the thing being repaired, and **a repair count
that climbs is the first sign that something upstream changed**.
