---
title: Stated and actual
version: 1
---

Ask a model how sure it is and it will tell you, in a number with two decimal places. The number
looks like a probability. **It is text the model wrote**, like the category beside it, and nothing
guarantees it was computed from anything. Calibration is the question of whether that number
matches how often the model is right when it says it.

The prompt for this lesson adds a fourth field:

```
ana@lab:~/triage$ grep -n confidence prompts/v9-confidence.txt
7:- "confidence": how sure you are of the category, from 0 to 1
11:Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back.", "confidence": 0.9}
16:Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book.", "confidence": 0.95}
21:Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name.", "confidence": 0.85}
```

The instruction asks for a number from 0 to 1, and the three examples show what one looks like.

## How the stand-in decides what to say

```
ana@lab:~/triage$ grep -n -A6 "^def confidence" promptlab/standin.py
242:def confidence(sc, label):
243-    """What it SAYS its confidence is. It is worked out from how much evidence
244-    it found FOR its answer, and never looks at the evidence for the others:
245-    a message full of billing words gets a confident billing, even when it is
246-    just as full of words for returns. That is the course's choice, made so
247-    that lesson 21 has an overconfident model to calibrate."""
248-    return min(0.99, round(0.62 + 0.1 * max(0.0, sc[label]), 2))
```

The stand-in states 0.62, plus a tenth of the score it found **for the label it chose**, and never
more than 0.99. It does not look at the scores of the other labels. A message with strong evidence
for two labels gets a confident answer for whichever one won, and that is the flaw the docstring
says was put there on purpose. It is one plausible way for a model to be overconfident, and it
gives this lesson something to measure.

## One confident mistake

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/all.jsonl --out runs/v9.jsonl
70 calls, prompt c31bed19, written to runs/v9.jsonl
ana@lab:~/triage$ pl check runs/v9.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     56    14
urgency      47    23
all          47    23
ana@lab:~/triage$ grep h04 cases/all.jsonl
{"id": "h04", "message": "I'd like to return the atlas, but the courier you use doesn't collect from my area.", "expect": {"category": "returns", "urgency": "normal"}}
ana@lab:~/triage$ pl show runs/v9.jsonl h04
│ {"category": "delivery", "urgency": "normal", "summary": "They'd like to return the atlas, but the courier you use doesn't collect from their area.", "confidence": 0.97}
stop: end, tokens in 287, out 54
```

Fifty-six of seventy categories are right, 80%. `h04` is one of the fourteen that are not, and it
was stated at **0.97**. The customer wants to return an atlas and cannot because the courier does
not collect from their area. A person called that returns. The stand-in found `courier` and
`collect`, two delivery words, and `return`, one returns word. It chose delivery and stated its
confidence from the delivery evidence alone, as if the returns evidence were not in the message.

One confident mistake is an anecdote. Whether the stand-in is overconfident in general is a
question about all seventy answers at once, and the next section asks it.
