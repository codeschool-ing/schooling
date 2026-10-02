---
title: Choosing the examples, and paying for them
version: 1
---

Since the model continues the pattern it is shown, **the examples teach everything they have in
common, whether you meant them to or not**. Four examples that are all short teach short. Four that
are all positive teach positive. Choosing examples is choosing what the pattern says.

## Five rules for a set of examples

This is the few-shot prompt for the café's labeller, written to a file on the workbench. It is the
zero-shot prompt of lesson 20 with four labelled examples added before the message to label:

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

## Examples are paid for on every request

A prompt is sent in full with every request, so its examples are too. `tok` counts both versions
with the tokenizer of lesson 3:

```
ana@lab:~/pe$ tok count prompt-zero.txt prompt-few.txt
tokens  words  chars  file
    87     57    407  prompt-zero.txt
   172    105    750  prompt-few.txt
```

The four examples took the prompt from 87 tokens to 172, almost double, before any message is
added. At illustrative prices given on the command line, 2.50 per million input tokens and 10 per
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
