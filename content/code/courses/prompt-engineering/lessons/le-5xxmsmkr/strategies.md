---
title: Working inside the limit
version: 1
---

The obvious answer to a full window is a bigger one, and windows have grown enormously. It helps
less than it sounds. A bigger window costs more on every request (lesson 3), it still has an edge,
and a model does not read a very long context evenly. **The useful question is not how much fits,
but what the model needs to see for this request**, and five habits follow from it.

## Keep the instruction

The section before showed `tok fit` keeping the system prompt whatever else it dropped. Do the
same in anything you build: the rules and the format go in every request, and they are the last
thing to cut. When the context is long, it also helps to repeat the one instruction that matters
most right before the question, where the model reads it last. Lesson 22 is about writing the
system prompt itself.

## Carry a note forward

Dropping old turns loses whatever was said in them. The fix is to **keep what mattered in a form
that costs less than the turns did**: a short note, written when the turns are about to go, that
travels in the part that is never cut. Here is the same conversation with one sentence added to
the system prompt, "Noted earlier in this conversation: the customer is Bruno and he is allergic to
nuts.", cut to the same budget of 120:

```
ana@lab:~/pe$ tok fit chat-noted.json -b 120
budget 120, system prompt 71
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 116 tokens, 3 of 7 turns
```

The same four turns were dropped, the system prompt grew from 53 tokens to 71, and **the allergy
survived**, because it is no longer in a turn. The note cost 18 tokens on each request; the four
turns it replaced cost 75.

In a real application the note is written by a second, cheaper request to a model: summarise the
turns about to be dropped, keeping anything the user said about themselves. A summary can leave
out the one detail that mattered as easily as truncation can, so the summarising prompt has to say
what must survive. This one was written by the course as an illustration:

```localised
These turns are about to be removed from the conversation. In at most
two sentences, write down anything the customer said about themselves
(name, allergies, preferences) and any promise the assistant made.
Write nothing else.
```

## Send what the question needs, not everything you have

The café's staff handbook is six short files:

```
ana@lab:~/pe$ tok count handbook/*.md
tokens  words  chars  file
    70     55    310  handbook/allergens.md
    60     44    249  handbook/deliveries.md
    65     46    261  handbook/hours.md
    58     50    260  handbook/loyalty.md
    74     62    318  handbook/refunds.md
    48     35    209  handbook/wifi.md
```

Between 48 and 74 tokens each. Pasting all of it into every request is affordable here and wasteful
anywhere real, where a handbook runs to hundreds of pages. A question about the guest Wi-Fi needs
one line of `wifi.md`, and the other files cost tokens and are also **text the model has to read
past** to find the line that answers. Retrieval finds the passages that match the question
and sends only those.

::: track ai
Lesson 11 introduces retrieval, and the `rag` course in your track builds it properly, with search
by meaning and not only by words.
:::

::: track *
Lesson 11 introduces retrieval: searching the material for the passages that match the question,
and putting only those in the prompt.
:::

## Cut a long document into chunks

Some jobs need all of a document: a summary of a contract, every date in a year of minutes. When
it does not fit, **split it into chunks that each fit with room for the reply, give every chunk the
same instruction, and combine the answers** in a last request. Two things go wrong. A fact can be cut in half at a chunk boundary, which is
why chunks usually overlap by a few sentences. And a question that needs two distant parts of the
document at once, such as "does clause 9 contradict clause 2?", cannot be answered from either
chunk alone.

## Do not trust the middle of a long context

A model with a huge window can take in a whole book, and it does not follow that it reads every
page equally well. A 2023 study, "Lost in the Middle: How Language Models Use Long Contexts",
gave models a long set of documents with the answer placed at different points. They used
information at the **beginning and the end** of the context much better than information in the
middle. Models have improved since, and the advice it led to is still cheap to follow:

- put the instruction and the most important material at the start or the end, not buried between
  other documents;
- send fewer, better-chosen passages rather than many loosely related ones;
- if you need a fact from a long context, test with that fact at different positions before you
  trust the result.

All five habits come back to `toylm` asked about Sunday. The model can only answer from what is in
front of it, and deciding what is in front of it is your job, not the model's.
