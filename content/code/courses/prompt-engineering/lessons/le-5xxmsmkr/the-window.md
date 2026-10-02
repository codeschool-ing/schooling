---
title: Everything the model can see at once
version: 1
---

A long chat looks like a conversation with somebody who remembers it, so it is natural to think the
model keeps what you told it an hour ago. It keeps nothing. Lesson 2 showed that the application
sends the whole conversation again with every request; **the context window is the most the model
can take in on one request, counted in tokens**, and anything outside it has no effect on what
comes next.

## A window of two words

`toylm` has the smallest window there is that still makes sentences: the last two words (lesson 1).
The file it learnt from says when the café opens, and says it two ways:

```
ana@lab:~/pe$ grep "opens at" corpus.txt | sort | uniq -c
      2 the café opens at eight on sunday .
      6 the café opens at seven .
```

Six times at seven, twice at eight on Sunday. Ask it about Sunday:

```
ana@lab:~/pe$ toylm generate "on sunday the café opens at" --temperature 0
seven.
-- finish: end, prompt 6 tokens, output 2 tokens
ana@lab:~/pe$ toylm next "on sunday the café opens at"
context: trigram after 'opens at'
  seven     75.0%  ##############################
  eight     25.0%  ##########
```

`seven`, and the context line says why. **`toylm` saw `opens at` and nothing else.** The one word
that should decide the answer, `sunday`, is four words back, outside the window, and as far as the
model is concerned it was never written. It answered the question it could see, and that question
was about an ordinary day.

A large model's window is enormous by comparison, and the rule is the same at its edge: text that
did not make it into the window does not exist for the model. Nothing in the reply tells you
something was missing; the answer is fluent either way.

## What has to fit

The window is shared by everything in the request, including the part that has not been written
yet:

| | what it is | grows when |
|---|---|---|
| system prompt | the application's instructions (lesson 22) | somebody adds a rule |
| history | every earlier turn, both sides | the conversation goes on |
| input | the new message, and anything pasted or fetched into it | a document or a tool result is included |
| output | **the reply, token by token** | the model writes |

The last row catches people out. **The reply is written inside the same window**, so a request
whose input fills the window leaves no room to answer. At the time of writing (2026) providers
publish two numbers for each model, the size of the window and a separate, smaller limit on how
many tokens one reply may have, and both are in the model's documentation. They change between
models and versions, so read them from the page for the model you are using, with its date, never
from a list somebody made last year.

## What happens at the edge

Three different things, depending on who notices first:

- an **API** given a request that is too long refuses it with an error, and nothing is generated;
- a reply that runs out of room **stops in the middle**, and the API reports why it stopped, the
  `length` reason that lesson 15 is about;
- a **chat application** usually avoids both by cutting the conversation itself before it sends
  it, quietly, which is the subject of the next section.

The first two are loud. The third is the dangerous one, because the model answers normally, from
whatever was left.
