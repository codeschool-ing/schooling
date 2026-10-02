---
title: Stopping at a piece of text
version: 1
---

A model does not know where your answer ends. It knows what text usually comes next, and after
an answer in a list of questions and answers, what usually comes next is **the next question**.
So a model asked to continue a question-and-answer text will often answer, and then carry on
writing the following question, and its answer, until it picks the end or hits the limit of
lesson 15.

**A stop sequence is a piece of text that ends generation the moment it appears in the output.**
It is checked by the loop, not understood by the model, and it is the cheapest way to say "one
answer, and no more".

## A model that runs on

`toylm`'s corpus has lines of the form `question : … ? answer : … .`, several to a line. Here is
a prompt in that shape, and what the model sees of it:

```
ana@lab:~/pe$ toylm next "question : when does the café open ? answer :"
context: trigram after 'answer :'
  yes       50.0%  ####################
  at        33.3%  #############
  tomato    16.7%  #######
```

At temperature 0 it takes `yes`, then the full stop, and then the end, which here wins over a new
question:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --temperature 0
yes.
-- finish: end, prompt 10 tokens, output 2 tokens
```

At the default temperature, with seed 1, the draw after the full stop goes the other way:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :"
yes. question: is the coffee is hot.
-- finish: end, prompt 10 tokens, output 10 tokens
```

The answer is followed by a whole new question it invented, and the run ends only because the
model then drew the end. **Nothing in the model treats one answer as the unit of work.** Add a
stop sequence:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --stop question
yes.
-- finish: stop, prompt 10 tokens, output 3 tokens
```

`finish: stop` is the third reason a loop can end, beside `end` and `length`. The output stops
just before `question`, and the word itself is not shown.

The stop changes only the runs that reach it. Eight seeds, without and with it:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --samples 8
[seed 1] yes. question: is the coffee is hot.
[seed 2] tomato.
[seed 3] yes.
[seed 4] yes.
[seed 5] at six.
[seed 6] at six.
[seed 7] yes.
[seed 8] yes.
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --samples 8 --stop question
[seed 1] yes.
[seed 2] tomato.
[seed 3] yes.
[seed 4] yes.
[seed 5] at six.
[seed 6] at six.
[seed 7] yes.
[seed 8] yes.
```

Seven of the eight are identical. Seed 1 lost its invented second question and kept its answer.

## What the trigram actually answered

Look at those eight answers again: `yes`, `tomato`, `at six`. **None of them says `seven`**,
though the corpus says `answer : at seven` twice in reply to exactly this question. The reason is
in the first capture: `toylm` sees only `answer :`, the last two words, and after `answer :` its
file has `yes` most often, `at` next and `tomato` last. The question fell outside its window.
`at six` is the closing time, picked up from the next question in the corpus.

So the stop sequence did its job, and the job is narrow. **A stop decides where an answer ends;
it does nothing for whether the answer is right.** A large model reads the whole question, so it
would at least answer with a time. It could also carry on into the next question when the text
invites it, and that is the half the stop sequence fixes.
