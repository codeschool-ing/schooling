---
title: Freshness
version: 1
---

Marginalia's returns policy changed on 2 February 2026, from fourteen days to thirty and from paid to
free return postage. For a support assistant, the question is how long after the policy changed the
assistant started giving the new answer.

## With retrieval: re-embed what changed

In a RAG system the new policy is a new document. Cutting it into sections and embedding them is the
whole of the change, and `reindex_cost.py` counts and times it on this machine, rounding the time
up to the second because it changes a little from run to run:

```
ana@lab:~/rag$ python reindex_cost.py
the returns policy     9 sections    973 tokens  under 1 s
every document        92 sections   7855 tokens  under 7 s
```

**Under a second for the policy that changed, under seven for the entire corpus**, on one processor
core with a small model, and 973 tokens against 7,855, which is what a hosted provider would bill. A hosted embedding model would add network time and a few
cents; neither changes the order of magnitude. The new answer is live from the next question, and the
old one is gone the moment the old chunks leave the index, which is the subject of the section on
deleting.

The time is so short that the bottleneck is never the embedding. It is noticing that a document
changed. Lesson 5 records a hash of each chunk's text, so that a nightly job re-embeds exactly the
chunks whose text is different and nothing else.

## With fine-tuning: retrain

A fine-tuned model knows the old policy until a new model is trained without it. That means building a
dataset that teaches the new facts, including enough examples to overwrite the old ones, which the
model learnt with the same strength; running the training, which takes from minutes to hours on a
provider's service; evaluating the new model against the old one so that nothing else broke; and
switching production to the new model's name.

None of those steps is hard, and all of them are a release. A team that would re-index a document the
afternoon it changed will batch fine-tuning runs weekly or monthly, and in between the model answers
with confidence from a policy that no longer applies. **The staleness of a fine-tuned model is
measured in release cycles, and that of a retrieval system in minutes.**

## The questions where freshness is everything

Some answers change faster than any release cycle: prices, delivery times during a carrier strike,
stock, the status of an outage. The warehouse runbook in this corpus asks support to put a delays
banner in the help centre when a carrier is down. A retrieval assistant reads that banner from the
next question; a fine-tuned one never learns it existed. For answers like these, even a nightly
re-index can be too slow, and lesson 2 sent the fastest-changing of them, an order's status, to a
live API call instead of any document.
