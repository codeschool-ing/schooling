---
title: Three kinds of learning
version: 1
---

**Machine learning writes a program from examples instead of rules.** A rule-based churn alert says
"flag a customer silent for 42 days", a rule somebody wrote in lesson 13. A learnt one is shown
thousands of past customers, each with what was known about them and whether they then left, and
works out its own rule. What makes the three kinds of learning different is what the examples
contain.

| kind | the examples contain | it learns | a Panela question |
|---|---|---|---|
| **supervised** | inputs and the right answer | to predict the answer for new inputs | which customers will stop ordering next quarter? |
| **unsupervised** | inputs only | structure: groups, unusual points, simpler descriptions | which customers behave alike? (lesson 15) |
| **reinforcement** | the results of its own actions | which action earns the most reward | which page should the next visitor see? |

**Supervised learning** splits further by the kind of answer. A category, such as "will leave" or
"will stay", is **classification**; a number, such as next quarter's spend, is **regression**. Lesson
17 does one of each.

**Unsupervised learning** has no right answer to learn from, which is both its strength and its
difficulty: it can find what nobody was looking for, and nothing in the data says whether what it
found is useful. Lesson 15's clustering needed a person to name the clusters and to decide that four
were worth having.

**Reinforcement learning** learns by acting and watching what happens. Its examples are produced by
its own choices, so what it learns depends on what it chose to try. The last section of this lesson
shows the smallest useful version of it.

## Where this course stops

::: track data-science
On your track `machine-learning` came just before this course and covers all of this at depth:
algorithms, evaluation, tuning. These four lessons are a review from the BI side. What they add is the
business question each technique answers, and in lessons 18 and 19 what can go wrong when a model's
output decides something about people. Skim what you know and spend your time on the parts that use
Panela's data.
:::

::: track bi
On your track there is no course on machine learning, so these four lessons are where you meet it.
They aim at what a BI analyst needs: knowing which kind of question a model can answer, reading a
model's results without being fooled by them, and recognising when a model is treating some people
unfairly. Building and tuning models is a specialist's job, and the vocabulary here is what lets you
work with one.
:::

::: track *
These four lessons are an overview from the BI side: which kind of question each technique answers,
how to read a model's results without being fooled, and when a model's decisions are unfair. The
`machine-learning` course covers the algorithms at depth.
:::
