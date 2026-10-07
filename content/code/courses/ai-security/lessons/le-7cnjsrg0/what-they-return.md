---
title: What a moderation endpoint answers, and where it goes
version: 2
---

A moderation endpoint is usually pictured as a yes or no: send it a message and it says whether the
message is acceptable. **What it returns is a score per category**, sometimes a probability between
0 and 1 and sometimes a severity on a short scale. Whether a message is acceptable on your platform
is a decision your code makes from those scores, with a line you chose, and the line is where
nearly all of the work in this lesson is.

Every provider of this product class answers in roughly that shape. The one in this course is
`moderation.py`, which lesson 5 gave you along with `guard moderate`. **It is a stand-in and not a
moderation model**: a list of English words and phrases per category, each with a weight the course
chose, combined into a score that behaves like one. The comment at its top lists the mistakes it
makes on purpose. It answers like this:

```
ana@lab:~/guard$ guard moderate 'Shut up, you clown'
{"harassment": 0.84, "threat": 0.0, "spam": 0.0}
ana@lab:~/guard$ guard moderate 'Deliver tomorrow or you will regret it'
{"harassment": 0.0, "threat": 0.82, "spam": 0.0}
ana@lab:~/guard$ guard moderate 'Click here to claim your prize'
{"harassment": 0.0, "threat": 0.0, "spam": 0.84}
ana@lab:~/guard$ guard moderate 'He called me an idiot in the chat, can a moderator look?'
{"harassment": 0.9, "threat": 0.0, "spam": 0.0}
```

The last message is the one to keep in mind. It scores 0.9 for harassment, higher than the insult at
the top, and it is somebody asking for help. A word list cannot tell an insult from a
report of one. A trained classifier gets that case right far more often, and still gets some wrong,
on messages your users write and nobody tested.

## Three places to call it

An application built on a model has three kinds of text worth sending to a moderation endpoint, and
each answers a different risk:

| what is checked | when | the risk it answers |
|---|---|---|
| the user's message, before the model sees it | before the call | abuse aimed at the model, or a request the platform will not serve |
| the model's reply, before the user sees it | after the call | the model producing something the platform must not say |
| anything users publish to other users | before it is shown | one user harming another, with the platform as the carrier |

At Tarefa the forum is the third case, and it is the one this lesson measures. The second deserves a
sentence because teams forget it: **the model's output is text the platform publishes**, and a
system prompt saying *"never be rude"* is a request to the model, not a guarantee about what it
writes.

## The categories are the vendor's, the policy is yours

A provider's categories are designed for many customers at once, and Tarefa's rules will not match
them exactly. Tarefa forbids sharing a phone number to take a job off the platform, which no
moderation product has a category for; and it may tolerate rough language between two freelancers
arguing about kerning that a general harassment score would flag. So the scores are inputs to a
policy written down at Tarefa, with a mapping from each category to what happens, and with the rules
the vendor does not cover enforced by something else.

The scores of two categories are also not comparable. A 0.6 for spam and a 0.6 for threats came from
different parts of the classifier, trained on different examples, and the right line for each is
found separately. The next section is how.
