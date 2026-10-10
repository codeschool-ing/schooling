---
title: Check with code first
version: 2
---

Two replies in the temperature-0 run are not JSON. A program finds them without asking anybody:

```
ana@lab:~/triage$ pl check runs/v6.jsonl --failures | grep json
json         68     2
t38    json      not a JSON object
h28    json      not a JSON object
```

`json.loads` fails on `t38` and `h28`, every time, for the reason that is actually there:

```
ana@lab:~/triage$ pl show runs/v6.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 145, out 22, 2.5 s
```

The summary stops at the apostrophe of *won't* and a second brace closes the object, the failure
lesson 15 logged as F-0001. The reviewer read this reply and said OK. It flagged `h28`, which has
the same defect, with *the category is missing a value*, which is not the defect. **A check written
as code is exact and costs nothing**: it never doubts a valid reply, never passes a broken one, and
adds no call. The model's review of the same seventy replies cost seventy calls and flagged 45 of
them as wrong.

## What code can see

Most of what goes wrong with this course's answers is visible to a program:

- Parsing: the reply is JSON, and nothing else.
- Fields: the fields asked for, and no others. That is what caught the copied order number in
  lesson 1.
- Labels: each value is from its list. That is what caught *events* in lesson 18.
- A canary: a reply that repeats a word the prompt must never reveal, the test lesson 10 used for
  leaked instructions.
- Length and words: lesson 6 counted lengths and lesson 12 checked tone with rules.

Every one of those is a line of code with a right answer, and none of them should be a question for
a model.

## What only a model can see

What code cannot see is whether `returns` is the right reading of a message about a parcel that never
came. That is the one question a self-check is for, and on this lab's numbers this reviewer answers
it hardly better than chance. Before a check like that goes into a pipeline, decide what a flag
does. Overwriting the answer would act on 27 false alarms in seventy. **Routing a flagged reply to a
person** turns a flag into a message somebody reads, and here that is 45 messages to find 18.

The order follows from the costs:

1. Code checks every reply, exactly and for free, and sends the ones that fail back or to a person.
2. A model's check reads what passed, and flags what it doubts, once it has been measured and found
   better than a coin.
3. A person reads what was flagged.

**Measure the model's check like any other check**: against labels a person gave, as precision and
recall, on the configuration you run, and against a coin. And remember lesson 19 when choosing the
checker. A reviewer that shares the answering model's blind spots shares its misses, and a different
model, or the same one given evidence the first call did not have, is the way to make its mistakes
different.
