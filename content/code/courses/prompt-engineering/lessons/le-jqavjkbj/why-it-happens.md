---
title: Likely is not the same as true
version: 1
---

The word "hallucination" makes it sound like a fault: something in the model goes wrong now and
then, and it starts seeing things. **A hallucination is the model doing exactly what it always
does, writing the likeliest continuation, at a moment when the likeliest continuation is false.**
The correct answers and the invented ones come out of the same step, which is why the text alone
cannot tell you which one you got.

Lesson 1 ended on that point with one sentence, `the coffee is cold and the cat wakes`: every pair
of words in it came from the file, and the sentence as a whole came from nowhere. Two more
questions to `toylm` show the two common shapes of the problem.

## Several confident answers to one question

The café has a soup of the day, and the file `toylm` learnt from mentions three of them. Ask it
five times:

```
ana@lab:~/pe$ toylm generate "the soup of the day is" --samples 5
[seed 1] tomato. question: is the coffee is hot.
[seed 2] pumpkin.
[seed 3] tomato.
[seed 4] tomato.
[seed 5] lentil.
```

Tomato three times, pumpkin once, lentil once, and each one stated flatly, with nothing that says
"I am not sure". The scores explain it:

```
ana@lab:~/pe$ toylm next "the soup of the day is"
context: trigram after 'day is'
  tomato    50.0%  ####################
  lentil    25.0%  ##########
  pumpkin   25.0%  ##########
```

**Every one of those answers is likely, and none of them is known.** The file says what the soup
was on several days; nothing in it says what the soup is today, and nothing in the model could.
When you ask a large model about something that changes, such as a price, the latest version of a
library or who holds a job, it is in the same position. It can tell you what was common in the
text it learnt from, written in the present tense.

## A confident answer to a question nobody answered

Now ask about something the file never mentions at all:

```
ana@lab:~/pe$ toylm next "the owner of the café is"
context: trigram after 'café is'
  full     100.0%  ########################################
ana@lab:~/pe$ grep -c owner corpus.txt
0
```

The word `owner` does not occur once in the corpus, and the model gives its answer a score of
100%. Look at the context line: the window held `café is`, and in the file `café is` is always
followed by `full`. **The 100% measures how consistent the file is after those two words**, and
says nothing about whether the answer has anything to do with owners. A large model sees the
whole question, so it would not fall into this particular hole. It still produces a fluent answer
by the same rule whenever the honest one would be "nothing I have read says".

## The shapes it takes in large models

The same mechanism gives several familiar failures:

| what you ask for | what can come back | why it is likely |
|---|---|---|
| a fact that is rare in the training text | a plausible fact about something similar | the common pattern wins over the rare fact |
| a fact that has changed | the old value, in the present tense | the old value was in far more of the text |
| an answer to a question with a false premise | an answer that accepts the premise | text that answers a question is likelier than text that disputes it |
| a source, a link, a page number | **one that has the right shape and does not exist** | citations follow a pattern, and the pattern is easy to continue |

The last row is the one that has embarrassed people in public, because an invented citation looks
exactly like a real one. Here is the kind of reply that produces it. **The course wrote this as an
illustration, and every name, title and number in it was made up**, the same way a model makes
them up:

```localised
Question: Is there research showing that coffee improves memory?

Reply: Yes. A 2019 study by Hartley and Moreau, "Caffeine Intake and
Long-Term Memory Consolidation in Adults", published in the Journal of
Applied Café Science (vol. 14, pp. 211-228), found that 200 mg of
caffeine after learning improved recall the following day.
```

Nothing in the reply signals that it is invented. The authors have ordinary names, the title has
the vocabulary of a real paper, and the page range is the right length. That is the point: **a
model produces the form of a citation as fluently as the form of a sentence**, and the form is all
you can see.

## Why it is hard to train away

The models behind chat assistants are trained further to be helpful (lesson 1), and an answer
looks more helpful than "I don't know". Their makers also train them to admit uncertainty, and
models have become noticeably better at it; the problem shrinks, and it does not go away, because
the model has no separate store of facts to consult before it writes. **What it knows and what it
finds likely are the same thing inside it.** So the remedies in the next section do not ask the
model to try harder. They change what it is given, and they check what it returns.
