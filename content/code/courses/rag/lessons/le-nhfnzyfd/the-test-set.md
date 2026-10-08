---
title: The test set
version: 2
---

Every lesson since the fourth has measured something against `data/eval.jsonl`, and every
measurement was only as good as that file. This lesson makes the file the centre of the pipeline:
the thing that says whether a change made the system better, before any customer finds out.

## What is in it

```
ana@vm:~/rag$ head -n 3 data/eval.jsonl
{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": [["returns-policy", "The return window"]], "facts": ["30 days from delivery"]}
{"id": "e02", "question": "Who pays for the return postage?", "gold": [["returns-policy", "How to start a return"]], "facts": ["Returns are free"]}
{"id": "e03", "question": "How long after my return arrives will I get the refund?", "gold": [["returns-policy", "Refunds"]], "facts": ["within three working days"]}
ana@vm:~/rag$ tail -n 2 data/eval.jsonl
{"id": "e29", "question": "Which carrier do you use in Portugal?", "gold": [], "facts": []}
{"id": "e30", "question": "Is there a student discount?", "gold": [], "facts": []}
```

Each line is a question as a customer or an agent might ask it, the documents and sections that
answer it, and **facts**: a few words the passage that answers it contains, exactly. Thirty
questions, 26 with an answer in the documents and four with none, which must be refused. All of them
were written for the course, by reading the documents and asking what someone would want from them.

A fact is a deliberately blunt instrument. It works when the reply quotes its source, and
llama3.2:3b often does: *30 days from delivery* comes back as it was written. When the model
paraphrases, *10 days* does not match *waits there for ten days*, and the section on model judges says
what can replace it. Even so, a fact is worth writing
for every question: it is what turns "does the reply look right" into a check a program can run on
every commit.

## What a good test set contains

**Questions people actually ask, in their words.** The best source is the log of a system already in
use, or the support inbox before there is one. Questions written by whoever wrote the documents use
the documents' words and flatter any search.

**Questions with no answer.** A test set without them cannot measure refusing, and lesson 7 showed
refusing is where a pipeline fails most visibly. Four is the bare minimum to see the behaviour; a
real set wants a tenth or more.

**Each kind of question the users ask.** Lesson 6 needed a second file, `identifiers.jsonl`, because
the customer questions had no error codes in them. A test set that only covers one kind of question
reports on that kind only.

**The awkward cases**: two documents that disagree, a question whose answer is in a table, a question
that needs two sections. They are where the failures are.

## Keeping part of it aside

Lesson 7 chose a threshold by looking at all thirty questions, and called the result optimistic: a
number fitted to a set always looks better on that set. The defence is to **keep part of the test
set aside** and look at it only to confirm a decision already made. `evaluate.py` holds out every
third question by id:

```
ana@vm:~/rag$ python -c "import json; qs = [json.loads(l) for l in open(\"data/eval.jsonl\")]; print(\" \".join(q[\"id\"] for q in qs if int(q[\"id\"][1:]) % 3 == 0))"
e03 e06 e09 e12 e15 e18 e21 e24 e27 e30
```

Ten held out, two of them unanswerable; twenty in the **dev** split, used for every comparison in
this lesson. The rule is the discipline: try ideas on dev as often as you like, and run held-out once
a decision is made. A team that tunes on held-out has no held-out.

Thirty questions is small. Each one is three or four percentage points of any score, and lesson 4
already warned against reading much into one question's difference. A real system grows its test set
from its logs, a few questions a week, every one a case that went wrong once.
