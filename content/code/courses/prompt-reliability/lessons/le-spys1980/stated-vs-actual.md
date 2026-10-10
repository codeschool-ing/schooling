---
title: Stated and actual
version: 2
---

Ask a model how sure it is and it will tell you, in a number with a decimal point. The number looks
like a probability. **It is text the model wrote**, like the category beside it, and nothing
guarantees it was computed from anything. Calibration is the question of whether that number
matches how often the model is right when it says it.

Lesson 6 saved a prompt with a fourth field, `prompts/v9-confidence.txt`. These are its lines about
confidence:

```
ana@lab:~/triage$ grep -n confidence prompts/v9-confidence.txt
7:- "confidence": how sure you are of the category, from 0 to 1
11:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "confidence": 0.9}
16:Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book.", "confidence": 0.95}
21:Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name.", "confidence": 0.85}
```

The instruction asks for a number from 0 to 1, and the three examples show 0.9, 0.95 and 0.85.

## What it said

Run it over the seventy cases:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/all.jsonl --out runs/v9.jsonl
70 calls, prompt c31bed19, llama3.2:3b, written to runs/v9.jsonl
ana@lab:~/triage$ pl check runs/v9.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     52    18
urgency      37    33
all          37    33
```

Fifty-two of seventy categories are right, 74%. Now look at the numbers it stated, all seventy of
them:

```
ana@lab:~/triage$ grep -o 'confidence\\": [0-9.]*' runs/v9.jsonl | sort | uniq -c
      1 confidence\": 0.0
     46 confidence\": 0.8
     22 confidence\": 0.9
      1 confidence\": 0.95
```

**Four different values, and 68 of the 70 replies say 0.8 or 0.9.** The examples showed 0.9, 0.95
and 0.85, and the model wrote numbers next to them. Whether it chose between 0.8 and 0.9 for any
reason the message gave is the question the rest of this lesson measures.

## One confident mistake, one strange zero

```
ana@lab:~/triage$ grep h03 cases/all.jsonl
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl show runs/v9.jsonl h03
│ {"category": "account", "urgency": "high", "summary": "Wants to know about a suspicious order on their account.", "confidence": 0.9}
stop: stop, tokens in 291, out 38, 4.6 s
```

A charge for an order the customer never placed. The person who labelled it called that billing:
money taken that should not have been. The model called it account and stated 0.9, the higher of the
two values it almost always uses.

```
ana@lab:~/triage$ pl show runs/v9.jsonl t35
│ {"category": "other", "urgency": "low", "summary": "Compliments the shop and its service.", "confidence": 0.0}
stop: stop, tokens in 290, out 35, 4.2 s
```

A thank-you note, labelled `other`, right, and stated at **0.0**. A confidence of zero on a right
answer is either a model that is never sure about praise or a model that read the field as
something else, how much of a problem the message is, perhaps. The run cannot tell you which, and
that is the point: the field is a number the model wrote, and what it means is whatever the model
meant.

One confident mistake is an anecdote. Whether the stated numbers mean anything is a question about
all seventy answers at once, and the next section asks it.
