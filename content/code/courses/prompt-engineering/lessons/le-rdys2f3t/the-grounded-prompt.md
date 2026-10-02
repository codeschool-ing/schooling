---
title: The grounded prompt
version: 1
---

Pasting passages above a question is not enough on its own. A model given some sources and a
question will happily mix the sources with whatever it finds likely, and the reader cannot tell
which sentence came from where. **A grounded prompt tells the model to answer only from the sources,
to cite them, and to say so when they do not contain the answer.** `retrieve --prompt` builds one:

```
ana@lab:~/pe$ retrieve --prompt "when does the café open on sundays"
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.

[1] (hours.md) On Sundays it opens at 08:00 and closes at 12:00.
[2] (hours.md) On public holidays the café follows the Sunday hours.
[3] (hours.md) Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.

Question: when does the café open on sundays
```

Three parts, in a fixed order: the instruction, the numbered sources with the file each came from,
and the question last. This whole text is what would be sent to the model, and it is the only
thing the model would know about the café.

What a model might reply to it was written by this course as an illustration; no model was run:

```localised
On Sundays the café opens at 08:00 and closes at 12:00 [1].
```

## Why the citation matters

The `[1]` is the part that makes the answer checkable. **A cited answer can be traced back to a
line of the handbook**, by a person or by a program that checks every cited number exists and
that the quoted hours appear in that source. An answer with no citation has to be trusted, and lesson
5 explained why fluent text does not earn that.

Citations are also how you notice the model went beyond the sources. A sentence with no citation
in a grounded answer is a sentence to look at.

## "The handbook does not say" is a correct answer

The instruction allows one more outcome, and it is the one that protects you. The handbook says
nothing about dogs, so the search finds nothing, and the prompt goes out with no sources at all:

```
ana@lab:~/pe$ retrieve --prompt "can I bring my dog"
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.


Question: can I bring my dog
```

The reply the instruction asks for, again written by the course as an illustration:

```localised
The handbook does not say whether dogs are allowed in the café.
```

**Without that permission, a model asked a question tends to produce an answer**, because an answer
is the likely continuation of a question (lesson 1), and the likely answer about dogs in cafés is
not the café's policy. Saying "the handbook does not say" is the system working, and a support
assistant that can say it is one that can be trusted on the questions it does answer. Lesson 5 is
about the wider problem of answers with nothing behind them.
