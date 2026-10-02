---
title: Where it fails
version: 1
---

A grounded prompt makes an answer only as good as the passages in it. Most RAG failures are not
the model's at all: **the search returned nothing, the wrong passage, or half of the right one,
and the model wrote faithfully from what it was given.** Each of the three can be seen with
`retrieve` alone.

## Different words find nothing

The handbook has a whole file about the guest network. Asked in other words, the search finds none
of it:

```
ana@lab:~/pe$ retrieve "is there wireless internet for customers"
query words: there wireless internet customers
no passage shares a word with the question
ana@lab:~/pe$ retrieve "what is the wifi password"
query words: wifi password
  2.80  wifi.md        The guest network is called aurora-guests and needs no password.
```

`wireless internet` and `Wi-Fi` mean the same thing to a person. To a keyword search they share no
word, so the first question scores zero against every line. **The answer existed,
and retrieval reported that nothing did.** With the grounded prompt from the last section, the
model would do as it was told and say the handbook does not say, which is false.

## A passage cut in the wrong place

Every line of the handbook is a passage, and one line depends on another:

```
ana@lab:~/pe$ retrieve "what time does the café open on public holidays"
query words: time caf open public holidays
  8.71  hours.md       On public holidays the café follows the Sunday hours.
  2.07  hours.md       Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
```

The first passage is exactly right and says nothing about times: the hours are on another line,
`On Sundays it opens at 08:00`, which shares no word with the question and was not retrieved. The
only times in the sources are the weekday ones. **A model answering from these two passages has
every reason to say 07:00**, and it would be citing real sources while doing it.

Where text is cut into passages, called chunking, decides what can be found together. A cut that
separates a rule from the detail it points to is the commonest version of this failure, and the
fix is in how the documents are cut, not in the prompt.

## The wrong passage, retrieved confidently

```
ana@lab:~/pe$ retrieve "can I get a refund for a cold coffee"
query words: get refund cold coffee
  2.67  refunds.md     A refund above R$ 100 needs the shift manager's approval.
  2.17  loyalty.md     The tenth coffee is free; stamps are counted per card, not per person.
  1.98  allergens.md   Oat, soya and lactose-free milk are available for every coffee at no extra cost.
ana@lab:~/pe$ retrieve "my drink was wrong, can I get my money back"
query words: drink wrong get money back
  5.35  refunds.md     A drink or a dish that is wrong or not as described is replaced or refunded on the spot.
  2.67  refunds.md     Money loaded onto a loyalty card is not refundable, but it never expires.
```

The first question is answered by the handbook's first refund rule: a drink that is not as
described is replaced or refunded on the spot. That line says `refunded`, not `refund`, and
`drink`, not `coffee`, so it shared no word with the question and was left out. In its place came
three passages that each share one word and answer something else. The second question, with the
handbook's own words in it, puts the right rule first.

The search has no way to know the difference. **There is no score that means "not relevant"**: the
top three are returned whatever they are, and a model told to answer from them will.

## Keyword search and meaning search

All three failures come from the same root: this search compares words, and people ask with
different words from the ones a document uses. The usual remedy is to search by meaning. Each
passage and each question is turned into a list of numbers, an **embedding**, by a model trained so
that texts with similar meanings get similar numbers, and the search returns the passages whose
numbers are closest. `wireless internet` and `Wi-Fi` then land near each other.

Meaning search has failures of its own, and real systems often combine both kinds. This lesson
names it and stops there.

::: track ai
The `embeddings-vectors` and `rag` courses, which follow this one in the track, build both halves properly: how
embeddings are made and compared, how documents are cut into passages, and how to measure whether
retrieval found the right one.
:::

::: track prompt security
In this track, this lesson is the whole of RAG: the idea, the grounded prompt, and the three ways
it fails. That is enough to read a RAG system's answers critically and to ask the right first
question when one is wrong: was the right passage retrieved?
:::

::: track *
Building retrieval properly, with embeddings, chunking and measurement, is a subject of its own
beyond this course. What this lesson gives you is the idea, the grounded prompt, and the first
question to ask when an answer is wrong: was the right passage retrieved?
:::
