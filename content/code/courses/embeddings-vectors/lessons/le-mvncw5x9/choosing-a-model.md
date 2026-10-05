---
title: Choosing a model
version: 1
---

The usual way to choose an embedding model is to open a leaderboard and take the model at the top.
A leaderboard averages scores over many public datasets, and lesson 9 showed why that is a starting
point and not an answer: your texts are not its datasets. This lesson's own measurements say the
same thing from another side. WordLlama, a far smaller model, beat MiniLM on the help-centre
search and lost to it on the tickets, with the same 40 articles, the same customers and the same
machine.

**Choose in two passes.** The first rules models out on questions that have a yes or no answer, and
needs no measurement. The second measures the few that survive, on your own data, and only then
looks at the price.

## The questions that rule a model out

| question | what to check | where this course met it |
|---|---|---|
| Which languages are the texts in? | the languages it was trained on, on its model card | lesson 1: an English model scored a Portuguese title as unrelated to its own translation |
| What kind of text is it? | whether it was trained on that domain; a domain model exists for code, law and finance | this lesson's sheet |
| How long is each text? | the maximum input; anything longer is cut off or refused | lesson 9: MiniLM ignores what is past its limit; the sheet lists 8191 tokens for OpenAI and 32000 for Voyage |
| May the text leave your machines? | a hosted API receives every text you embed | lesson 9 runs an open model locally |
| May you use it commercially? | the licence of the weights, which is not always the licence of the code | below |
| How fast must it be? | texts per second on your hardware, or the provider's rate limit | this lesson: WordLlama 128 times faster than MiniLM here |
| How much can you store? | dimensions × 4 bytes per vector, before any index | lesson 1 measured one vector; lesson 18 measures the rest |

**A licence is a yes or no question, and open weights do not answer it by themselves.** WordLlama's
package declares the MIT licence, and all-MiniLM-L6-v2 is published under Apache 2.0: both allow a
shop to use them commercially. Jina publishes the weights of jina-embeddings-v3 under CC BY-NC 4.0,
a non-commercial licence. A shop can read and test them, but to run them in production it needs an
agreement with Jina, or pays for the API instead. Read the licence on the model card before the
first benchmark, because a model you may not use is not worth measuring.

**Privacy is also a yes or no question.** Lesson 1 showed that a vector of a customer's message is
personal data. Sending the message to a hosted API to get that vector is sending the message, and
whether that is allowed is a decision for whoever answers for the data, made before the first
request.

## Measure what survives, then price it

For the models still standing, measure them the way this lesson did: your own questions, the
answers you decided are right, and the share that lands first and in the top few. Twenty-four
questions are enough to catch a model that is clearly wrong for the job, and too few to separate
two that are close; a difference of one or two questions is noise. Look at the failures one by
one, as `misses.py` did, because a pattern in them (shared words, a language, long texts) says more
than the count.

Price comes last because it is the easiest to read and the easiest to over-weigh. A cheaper model
that sends customers to the wrong article is not cheaper once somebody has to answer the questions
it lost. And price includes what lesson 18 adds: storage for every vector, and the whole bill
again on the day you switch.

## Marginalia's case

Marginalia's help centre is mostly English, with some articles in Portuguese:

```
ana@lab:~/emb$ jq -r .lang data/help.jsonl | sort | uniq -c
     37 en
      3 pt
```

A help centre with Portuguese articles will be asked Portuguese questions. That rules out every
English-only model before anything is measured, including both of the lab's: the lab uses them
because they run on this machine, not because they fit the shop. The survivors are multilingual
models, hosted or open. Whether the texts may go to a hosted API is the shop's decision about its
customers' messages, and if the answer is no, the list shrinks to open multilingual models with a
licence that allows commercial use. The shop measures those few on the 24 questions, with Portuguese
questions added, and prices the best of them last.
