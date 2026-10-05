---
title: Quality, and what stands in for it
version: 1
---

Quality is the criterion people most want a number for and the one no sheet can give. What stands
in for it, before anything is measured, falls into three groups, from least to most useful.

**Public leaderboards.** A model's score on a shared benchmark, or its rank where people vote
between two anonymous answers. They are real measurements of something, and good for one thing:
noticing that a model exists and is in the same league as the others. They measure somebody else's
tasks, mostly in English, with prompts written for the benchmark, and a model can be tuned towards a
popular benchmark until the score says more about the tuning than about the model.

**The provider's own tiers.** Every family in lessons 6 to 11 comes in sizes: a large, expensive,
slower model, and smaller, cheaper, faster ones. Within a family the ordering is reliable: the large
one is better on hard tasks. Across families it is not: one provider's small model may beat
another's medium one on your task, or lose to it badly.

**The task's difficulty.** The most useful prior of the three, and the one most often skipped.
Ana's sorting task is easy: five labels, short e-mails, clear cases. A small model is likely to do
it well, and paying for a large one buys accuracy on the five or six cases a person would also
hesitate over. Her drafting task is harder: tone, policy, Portuguese that has to sound natural.
That is where the larger models earn their price, if they do.

## What "good enough" means

A threshold for quality has to be written as a number on a set of cases, or it cannot be checked:
**"at least 35 of 40 sorted as a person sorted them"**, not "accurate". Choose it from the cost of
a mistake:

- a mislabelled e-mail lands in the wrong queue and is moved by hand, which costs a minute;
- a wrong order number in an extraction sends the wrong refund, which costs money and a customer;
- a draft with the wrong policy in it is caught by the agent who reads it before sending, if the
  agent reads it.

Different costs, different floors, and **one model can pass one task and fail another**. That is a
reason to choose per task rather than per company, and lesson 5 evaluates each task separately.

## What this lesson does with quality

Nothing yet, deliberately. Section 08 builds the matrix with a quality column left **empty**, to be
filled by lesson 5's measurements. A matrix with a quality column filled from leaderboards would
look finished, and it would be answering a question nobody asked.
