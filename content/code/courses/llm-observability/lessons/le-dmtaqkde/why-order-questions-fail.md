---
title: Why the order questions were refused
version: 1
---

A rate says that something is wrong with a feature. A trace says what. Take one of the week's order
messages and the same question with the customer's details taken out, and look at the search span of
each:

```
ana@lab:~/obs$ python assistant.py --feature order "Hi, I am Joana Prado (joana.prado@example.com). My order MG-20481937 has not arrived after 12 working days. Is it lost?" > /dev/null; python tree.py --attrs | grep -E "top_score|kept"
                       app.search.kept = 0
                       app.search.top_score = 0.539
ana@lab:~/obs$ python assistant.py "My order has not arrived after 12 working days. Is it lost?" > /dev/null; python tree.py --attrs | grep -E "top_score|kept"
                       app.search.kept = 0
                       app.search.top_score = 0.605
```

The same question, **0.539 with the name, the address and the order number in it, 0.605 without**.
The embedding of a message is the embedding of all of it, and a name, an e-mail address and an order
number pull it away from the documents, which contain none of those. Both scores are now below the
floor of 0.62, which is why both were refused. Under the old floor of 0.5, the first would have
squeaked past and the second comfortably.

That is a finding a dashboard could not have made and a trace made in two commands. It also points at
the fix, and it is not in the floor: **the search should be given the question, not the message**. A
step before retrieval that strips the customer's details, which lesson 2 already wrote (`redact()`), or
that asks a model to restate the question, as `rag` lesson 6 does when it rewrites questions, would
give the order questions the same chance as the help ones. Lesson 14 tests a change like that against
the evaluation set before letting it near production.

## The general move

The refusal rate was the **symptom**, measured over everything. The **cause** was found by going from
the rate to a few traces behind it and reading their attributes. That move, from a number to the traces
that make it up, is what every tool in lessons 6 and 7 is built around: a chart you can click to get
the traces under a point. It works only if the traces carry the attributes that explain them, here
`app.search.top_score`, which is why lesson 1 insisted on recording inputs as well as outputs.
