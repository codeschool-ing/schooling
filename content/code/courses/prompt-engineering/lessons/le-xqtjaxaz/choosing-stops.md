---
title: Choosing a stop sequence
version: 1
---

A stop sequence looks like a safe thing to add: it only ends text early. The trouble is the word
*early*. **A stop fires on the text, wherever it appears, including inside an answer you wanted
whole.** Choosing one is choosing a string that marks the end and never occurs before it.

## A stop inside a legitimate answer

Somebody worried that `toylm` runs on with `and the cat sleeps and the cat...` might reach for
`and` as a stop. On a different prompt that breaks a correct answer:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0 --stop and
soup, bread
-- finish: stop, prompt 3 tokens, output 4 tokens
```

The menu has soup, bread **and** cake, and the stop removed the cake. The finish reason says
`stop`, which looks like a normal ending. It is harder to notice than `length`, because a stop is
supposed to end the text.

A stop is matched as text, not as a word. In `toylm` it is a plain substring test on what has
been written so far, so a short stop can fire inside a longer word:

```
ana@lab:~/pe$ toylm generate "the coffee is" --seed 2
cold and the cat wakes.
-- finish: end, prompt 3 tokens, output 6 tokens
ana@lab:~/pe$ toylm generate "the coffee is" --seed 2 --stop at
cold and the c
-- finish: stop, prompt 3 tokens, output 4 tokens
```

`at` is inside `cat`, so the answer was cut in the middle of a word. Model APIs also match stop
sequences against the generated text, and the details, such as where a match across two tokens
is cut, are the provider's. **The longer and more distinctive the stop, the less likely it is to
appear by accident.**

## The stop text is not in the output

In every run above the stop text itself is missing: `yes.` and not `yes. question`, `is there
cake?` and not `is there cake? answer`. That is the usual behaviour of model APIs too, and it has
a consequence: **if your program needs the marker, add it back yourself.** The output count still
includes the token that triggered the stop. In the café run, `toylm` reported 3 output tokens for
the two shown (`yes` and the full stop) because it wrote `question` before the check removed it.

## Stops for turn markers

Chat-shaped text is the common case. A transcript where each turn starts with a label, such as
`question :` and `answer :`, or `User:` and `Assistant:`, has a natural stop: the label that
starts the other side's turn. Here `toylm` is asked to write a question, and without a stop it
also writes the answer:

```
ana@lab:~/pe$ toylm generate "question :"
is there cake? answer: at six.
-- finish: end, prompt 2 tokens, output 9 tokens
```

Stopping at the label of the next turn keeps only the turn you asked for:

```
ana@lab:~/pe$ toylm generate "question :" --stop answer
is there cake?
-- finish: stop, prompt 2 tokens, output 5 tokens
```

A model that writes the other side's turn is putting words in somebody else's mouth. In a
program, that invented turn can be read as if the user had said it. A stop on the next turn's
label is a cheap guard against that.

Chat APIs that take a list of messages mark turns with tokens of their own, and they end the
assistant's turn without you writing a stop. Stop sequences matter most where the text you send
is plain text with your own markers, and in templates where one prompt holds many examples
(lesson 21).

## Several stops at once

APIs that support stop sequences usually accept a short list, and generation ends at whichever
appears first. In `toylm`, `--stop` can be repeated:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --stop question --stop answer
yes.
-- finish: stop, prompt 10 tokens, output 3 tokens
```

Here `question` arrived first. With both set, a reply that starts a new question or a new answer
label is cut at that point. Each provider caps how many stops one request may carry and how long
each may be; the API reference says what yours allows.

**Choose stops that mark the end of the unit you want, that cannot occur inside it, and test
them on real replies** before trusting them. A stop you never saw fire has not been tested, and a
stop that fires inside answers will look, in the finish reason, exactly like one that works.
