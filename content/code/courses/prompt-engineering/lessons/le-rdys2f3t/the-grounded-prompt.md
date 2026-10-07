---
title: The grounded prompt
version: 2
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
and the question last. This whole text is what is sent to the model, and it is the only thing the
model knows about the café. Pipe it into `ask`:

```
ana@lab:~/pe$ retrieve --prompt "when does the café open on sundays" | ask - --temperature 0
According to the sources, the café opens on Sundays at 08:00. [1]
-- llama3.2:3b, finish: stop, prompt 153 tokens, output 20 tokens
```

Right, and cited, and half the hours: the closing time is in the same source and the reply left it
out, because the question only asked when it opens.

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

The instruction asks for one reply here, that the handbook does not say. The model gave another:

```
ana@lab:~/pe$ retrieve --prompt "can I bring my dog" | ask - --temperature 0
I don't have enough information to answer your question. Could you please provide more context or clarify what you are referring to? Are you asking about bringing a dog into a specific location, such as a building or a park?
-- llama3.2:3b, finish: stop, prompt 82 tokens, output 46 tokens
```

It did not invent a policy on dogs, which is the outcome that matters most, and it did not say the
handbook was silent either. With no sources under the instruction, it read the prompt as a question
with something missing and asked for more. A program that checks replies would have to treat this
as a refusal too, and a test that only looks for the exact words "does not say" would miss it.

**Without that permission, a model asked a question tends to produce an answer**, because an answer
is the likely continuation of a question (lesson 1), and the likely answer about dogs in cafés is
not the café's policy. Saying "the handbook does not say" is the system working, and a support
assistant that can say it is one that can be trusted on the questions it does answer. Lesson 5 is
about the wider problem of answers with nothing behind them.
