---
title: Balancing the examples
version: 1
---

Lesson 1 said that every example pulls answers towards its own label, whatever it says. That
section promised a measurement, and this is it. **The labels on a prompt's examples are a vote
cast before the message is read.**

```
ana@lab:~/triage$ grep -n "^EXAMPLE_PULL" promptlab/standin.py
86:EXAMPLE_PULL = 0.4      # what one example adds to its own label, whatever it says
ana@lab:~/triage$ grep -o '"category": "[a-z]*"' prompts/v18-skewed.txt
"category": "billing"
"category": "billing"
"category": "billing"
"category": "billing"
"category": "delivery"
ana@lab:~/triage$ grep -o '"category": "[a-z]*"' prompts/v18-balanced.txt
"category": "billing"
"category": "returns"
"category": "account"
"category": "other"
"category": "delivery"
```

`v18-skewed` has five examples: four billing and one delivery. It is what you get by copying
examples out of the queue somebody was working on that afternoon. `v18-balanced` has one example of
each category. In the stand-in each example adds 0.4 to its own label for every message, and more
when the message shares words with it, so the skewed prompt starts every message with 1.6 for
billing before a word of it is read.

## Twenty-three answers

```
ana@lab:~/triage$ pl run prompts/v18-skewed.txt cases/all.jsonl --out runs/skewed.jsonl
70 calls, prompt fa582afd, written to runs/skewed.jsonl
ana@lab:~/triage$ pl run prompts/v18-balanced.txt cases/all.jsonl --out runs/balanced.jsonl
70 calls, prompt f44acd73, written to runs/balanced.jsonl
ana@lab:~/triage$ pl compare runs/skewed.jsonl runs/balanced.jsonl --answers
70 cases, same answer 47, different answer 23
  t05  billing -> other
  t10  billing -> other
  t13  billing -> returns
  t21  billing -> returns
  t23  billing -> returns
  t29  billing -> account
  t33  billing -> returns
  t34  billing -> account
  t37  billing -> delivery
  h01  billing -> returns
  h06  billing -> delivery
  h07  billing -> account
  h09  billing -> account
  h10  billing -> account
  h13  billing -> other
  h15  billing -> delivery
  h16  billing -> delivery
  h18  billing -> returns
  h20  billing -> other
  h23  billing -> returns
  h26  billing -> delivery
  h28  billing -> delivery
  h30  billing -> other
```

Twenty-three of seventy answers differ, and **on every one of them the skewed prompt said
billing**. Not one moved in the other direction. That is what a bias looks like in a comparison of
answers: every change points the same way.

```
ana@lab:~/triage$ pl check runs/skewed.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     45    25
urgency      39    31
all          39    31
ana@lab:~/triage$ pl check runs/balanced.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     57    13
urgency      47    23
all          47    23
```

The category check goes from 45 to 57. Both prompts parse on all seventy replies, so all of that
difference is in the labels.

Be careful what this proves. The two prompts differ in more than the count of each label: they are
different messages, too, and an example also pulls by likeness. So the comparison measures one set
of examples against another, which is the decision you actually face. To measure the count alone,
you would keep the messages and change only the labels, and that would be a counterfactual test,
the subject of the next section.

## Real models

The stand-in's pull is a constant. For real models, the same Zhao and others paper from the first
section, *Calibrate Before Use* (2021), named this **majority label bias**: GPT-3 favoured whichever
label appeared most often among the examples in the prompt. Its remedy, which it called contextual
calibration, was to ask the model about a content-free input such as `N/A`, read how far its answer
leaned towards each label, and correct for that lean. It is worth knowing the idea exists. The
everyday version is simpler: **count the labels in your examples** before you count anything
else, with the same `grep` as above.

## Balanced is a choice too

One example per label is not neutral either. It tells the model that every category is equally
likely, which is false for most inboxes. If the real mix is half delivery, a set that matches it
leans towards delivery on purpose. Either can be right. What is wrong is a mix nobody chose,
because then the prompt's bias is whatever the last person to edit it happened to paste.
