---
title: Check with code first
version: 1
---

The self-check's first two catches on the temperature-0 run were replies that did not parse. A
program finds those without asking anybody:

```
ana@lab:~/triage$ pl check runs/v6.jsonl --failures | grep json
json         68     2
t26    json      not JSON
t39    json      not JSON
```

The same two, `t26` and `t39`, found by `json.loads` failing. **A check written as code is exact and
costs nothing**: it never doubts a valid reply, never misses a broken one, and adds no call. The
model's review of the same two replies cost two calls and was no more right.

## What code can see

Most of what goes wrong with this course's answers is visible to a program:

- **Parsing**: the reply is JSON, and nothing else.
- **Fields**: the fields asked for, and no others. That is what caught the copied order number in
  lesson 1.
- **Labels**: each value is from its list.
- **A canary**: `pl check --canary` fails a reply that repeats a word the prompt must never reveal,
  the test lesson 10 used for leaked instructions.
- **Length and words**: lesson 6 counted lengths and lesson 12 checked tone with rules.

Every one of those is a line of code with a right answer, and none of them should be a question for
a model.

## What only a model can see

What code cannot see is whether `billing` is the right reading of a message about a gift card. That
is the one question a self-check is for, and on this lab's numbers it answers it with precision 0.73
and recall 0.57. Before a check like that goes into a pipeline, decide what a flag does. Overwriting
the answer with the reviewer's suggestion would have replaced six wrong labels with six other wrong
labels. **Routing a flagged reply to a person** turns a shaky flag into eleven messages somebody
reads, eight of them worth reading.

The order follows from the costs:

1. Code checks every reply, exactly and for free, and sends the ones that fail back or to a person.
2. The model's check reads what passed, and flags what it doubts.
3. A person reads what was flagged.

**Measure the model's check like any other check**: against labels a person gave, as precision and
recall, on the configuration you run. And remember lesson 19 when choosing the checker. A reviewer
that shares the answering model's blind spots shares its misses, and a different model, or the same
one given evidence the first call did not have, is the way to make its mistakes different.
