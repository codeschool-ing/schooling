---
title: Choosing the examples, and paying for them
version: 2
---

Since the model continues the pattern it is shown, **the examples teach everything they have in
common, whether you meant them to or not**. Four examples that are all short teach short. Four that
are all positive teach positive. Choosing examples is choosing what the pattern says.

## Five rules for a set of examples

This is the few-shot prompt for the café's labeller, a template like lesson 20's. Save it as
`~/pe/prompt-few.txt`. It is a zero-shot labelling prompt with four labelled examples added before
the message to label:

```
ana@lab:~/pe$ cat prompt-few.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>Oh lovely, a cold croissant again. Truly the highlight of my week.</message>
negative

<message>Can I book the terrace for six people on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud to talk.</message>
mixed

<message>Melhor café da rua, e o bolo de laranja é perfeito.</message>
positive

<message>
{message}
</message>
```

Each example is there for a reason, and the reasons are the rules:

1. Cover the classes. There is one example of each of the four labels, so no label looks like
   the default and none looks forbidden.
2. Include a hard case. The first example is sarcastic, the case lesson 20's test set caught
   the zero-shot prompt missing. An easy example of `negative` would have taught nothing the
   description had not.
3. Vary the order. The labels do not appear in the order of the list in the instructions, and
   the hard case is not last. A model can pick up on the position of examples as well as their
   content, and the label of the last example has an easy route into the next answer.
4. Balance the labels. One of each here. Three `negative` examples and one `positive` would
   make `negative` look like the usual answer, whatever the definitions say.
5. Keep them out of the test set. None of the four is `r1` to `r8` of lesson 20. If they
   were, the test set would contain the answers it is checking, and a score of 8 of 8 would
   measure memory, not labelling.

There is a sixth that the file shows rather than states: **the examples use exactly the output
format asked for**. A bare label in lower case, on its own line. An example that answered
`Negative (sarcastic)` would contradict the instruction a few lines above it, and leave the model
two signals that disagree.

The fourth example is in Portuguese for the same reason as `r8` in the test set: messages arrive in
more than one language, and the labels stay in English.

## What the count said

Lesson 20's method decides whether the examples earned their place: the same eight tests, with the
same `label.py` and `score.py`, once without the examples and once with them. `prompt-zero.txt` is
the same prompt with the four examples taken out, and without lesson 20's list of edge cases:

```
ana@lab:~/pe$ cat prompt-zero.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>
{message}
</message>
ana@lab:~/pe$ python3 label.py prompt-zero.txt tests.tsv > replies-zero.txt; python3 score.py tests.tsv replies-zero.txt
r5  wanted negative      got positive
r8  wanted positive      got mixed
6 of 8 right
ana@lab:~/pe$ python3 label.py prompt-few.txt tests.tsv > replies-few.txt; python3 score.py tests.tsv replies-few.txt
r1  wanted positive      got negative not_a_review mixed positive not_a_review
r2  wanted mixed         got negative not_a_review mixed positive not_a_review
r3  wanted negative      got negative not_a_review mixed positive negative
r4  wanted positive      got negative not_a_review mixed positive not_a_review
r5  wanted negative      got negative not_a_review mixed positive not_a_review
r6  wanted not_a_review  got negative not_a_review mixed positive not_a_review
r7  wanted mixed         got negative not_a_review mixed positive not_a_review
r8  wanted positive      got negative not_a_review mixed positive not_a_review
0 of 8 right
```

**Six of eight without the examples, none of eight with them.** Every reply to the few-shot prompt
is five labels, the four examples labelled again and then the message, the failure the section
before showed on one message, now on all eight. The examples and the input were written the same
way, so the model treated them the same way.

So mark the boundary. The same four examples, set out as examples, with an instruction to label only
the message in the tags:

```
ana@lab:~/pe$ cat prompt-few2.txt
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

These four messages are already labelled, as examples:

  Oh lovely, a cold croissant again. Truly the highlight of my week. -> negative
  Can I book the terrace for six people on Saturday? -> not_a_review
  Friendly staff, but the music was far too loud to talk. -> mixed
  Melhor café da rua, e o bolo de laranja é perfeito. -> positive

Label only the message between the tags below. Reply with the label
only, in lower case, nothing else.

<message>
{message}
</message>
ana@lab:~/pe$ python3 label.py prompt-few2.txt tests.tsv > replies-few2.txt; python3 score.py tests.tsv replies-few2.txt
r4  wanted positive      got mixed
r5  wanted negative      got positive
r6  wanted not_a_review  got mixed
r8  wanted positive      got mixed
4 of 8 right
```

Four of eight: the form is fixed, and the labels are worse than the prompt with no examples at all.
`r5`, the sarcastic message, is still `positive` though a sarcastic example sits in the prompt, and
three messages became `mixed`, the label of the one example closest to them in the list. **On this
model, these examples made the labeller worse**, and only the count says so: every one of the
replies is a tidy lower-case label. A larger model may well gain from the same four examples. That
is the reason to measure with your model, not to take this lesson's word for it, or anyone's.

## Examples are paid for on every request

A prompt is sent in full with every request, so its examples are too. `tok` counts both versions
with the tokenizer of lesson 3:

```
ana@lab:~/pe$ tok count prompt-zero.txt prompt-few.txt prompt-few2.txt
tokens  words  chars  file
    87     57    407  prompt-zero.txt
   172    105    750  prompt-few.txt
   179    125    794  prompt-few2.txt
```

The four examples took the prompt from 87 tokens to 172, almost double, before any message is
added, and marking them as examples took it to 179. At illustrative prices given on the command line, 2.50 per million input tokens and 10 per
million output tokens, with a two-token reply:

```
ana@lab:~/pe$ tok cost prompt-zero.txt -o 2 -i 2.50 -p 10
input  87 tokens x 2.5 per million = 0.000218
output 2 tokens x 10 per million = 0.000020
one request: 0.000237
10,000 requests: 2.38
ana@lab:~/pe$ tok cost prompt-few.txt -o 2 -i 2.50 -p 10
input  172 tokens x 2.5 per million = 0.000430
output 2 tokens x 10 per million = 0.000020
one request: 0.000450
10,000 requests: 4.50
```

Per request it is under a thousandth either way. **Over 10,000 messages, the few-shot prompt costs
4.50 against 2.38**, and the difference grows with every example added and every request sent. Lesson 15
is about controlling the other side of that bill, the output.

That cost is the reason to stop adding examples when the test set stops improving, rather than
adding them on principle. Two or three well-chosen examples that fix a measured failure are worth
their tokens. Twenty examples that repeat the easy cases cost far more and teach the pattern
nothing new. Lesson 20's method decides: **run the test set with and without each change,
and keep what moves the count.**
