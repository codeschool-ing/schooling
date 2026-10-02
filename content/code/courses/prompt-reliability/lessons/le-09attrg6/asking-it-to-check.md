---
title: Asking it to check
version: 1
---

Self-evaluation is the step that sends a model's answer back to it with a question: is this right?
It sounds like a second opinion. **It is the same opinion asked for twice**, and what it can add
depends entirely on what differs between the first reading and the second.

The review prompt in the lab shows the model the customer's message and the answer it gave, and asks
for one word back:

```
ana@lab:~/triage$ cat prompts/review.txt
You check answers given by a triage assistant for Folio, an online bookshop.

<message>
{{message}}
</message>

<answer>
{{answer}}
</answer>

Is the answer valid JSON with the right category? Reply OK, or WRONG and the reason.
```

It asks about the format and the category, and not about the urgency, so a reply counts as wrong
here when it fails `json`, `fields`, `labels` or `category`.

## What the stand-in does with it

A review needs a rule like everything else the stand-in does, and its rule is written beside the
function that applies it:

```
ana@lab:~/triage$ grep -n -A5 "^def review" promptlab/standin.py
416:def review(message, answer):
417-    """Asked to check an answer, it re-reads the message the way it read it
418-    the first time. So it catches what it can SEE, a broken format, and a
419-    label that differs from what it would say itself, and it doubts an answer
420-    when its own two best labels were close. It cannot catch a mistake it
421-    would make again."""
```

It scores the message again with the same keyword table it answered with. That reading leaves out
whatever the triage prompt added, its examples and the order of its list, since the review prompt
carries neither. Then it says WRONG in three cases: the answer does not parse, its own top label
differs from the answer's, or its two best labels are close. Otherwise it says OK.

That rule was chosen to resemble one honest account of self-checking. **A reviewer can only flag
what looks wrong to it**, and an answer it would give again does not look wrong.

## Measuring a check

`pl selfcheck RUN` sends every reply in a run through `review.txt`, one more call per reply, and
holds each verdict against the person's label: was the reply flagged, and was it really wrong? That
is the same measurement lesson 13 made of a model judging two replies, and it has the same
reference point. **A check is only as good as its agreement with the labels a person gave**, and
the next section reads that agreement as a table.
