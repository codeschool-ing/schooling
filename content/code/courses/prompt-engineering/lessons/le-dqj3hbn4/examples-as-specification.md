---
title: Examples are a specification
version: 2
---

It is natural to treat examples as a nice extra, a way of being friendly to the model after the
real instructions. They are more than that. **An example is a specification you do not have to put
into words**: it shows the exact form of the answer, and it shows where a boundary falls, both of
which are hard to describe and easy to see.

A prompt with one solved example is one-shot; with several, few-shot. Lesson 20's prompts
had none, which made them zero-shot.

## A model continues the pattern in front of it

The reason examples work is lesson 1's loop: the model writes whatever is likely to come next, and
what is likely depends on the text already there. Text that sets up a pattern makes the
continuation of that pattern likely.

`toylm` shows this in miniature. Given two words of a statement, it continues the statement:

```
ana@lab:~/pe$ toylm generate "the bread" --temperature 0
is fresh.
-- finish: end, prompt 2 tokens, output 3 tokens
```

Given the same words inside the question-and-answer pattern that its corpus contains, it fills the
answer slot instead, in the corpus's format:

```
ana@lab:~/pe$ toylm generate "question : is the bread fresh ? answer :" --temperature 0
yes.
-- finish: end, prompt 9 tokens, output 2 tokens
```

Nothing told it to answer. The text in front of it was shaped like a question awaiting an answer,
and the likeliest continuation of that shape is an answer. That is the whole mechanism of few-shot
prompting, and in a large model it works over many lines: show three questions answered in one
format, and the fourth is answered in the same format.

## Where the toy stops, and why that is worth seeing

Now a question whose answer is a time, not yes or no:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --temperature 0
yes.
-- finish: end, prompt 10 tokens, output 2 tokens
ana@lab:~/pe$ toylm next "question : when does the café open ? answer :"
context: trigram after 'answer :'
  yes       50.0%  ####################
  at        33.3%  #############
  tomato    16.7%  #######
```

`yes.`, to a question about opening hours. The reason is on the context line: **`toylm` sees only
the last two words, `answer :`**, and after `answer :` its corpus says `yes` half the time. The
question had scrolled out of its view before the answer began. It picked up the format from the
pattern and none of the content.

A large model sees the whole prompt, so it does read the question, and the time can come from it.
The useful part of the toy's failure is the split it makes visible. **The pattern controls the
form of the answer; the content still has to come from the model's reading of the input.** Few-shot
examples are strongest at the first and give no guarantee about the second.

## The same task, zero-, one- and few-shot

The labelling task of lesson 20, in three short versions, all ending on the same sarcastic message.
Zero-shot, the description alone:

```
ana@lab:~/pe$ cat prompts/shot-zero.txt
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Great, another forty minutes for a coffee.</message>
ana@lab:~/pe$ ask - --temperature 0 < prompts/shot-zero.txt
negative
-- llama3.2:3b, finish: stop, prompt 58 tokens, output 2 tokens
```

Right, with no example at all: this model read the sarcasm in this message. One-shot, the
description and one solved example:

```
ana@lab:~/pe$ cat prompts/shot-one.txt
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Great, another forty minutes for a coffee.</message>
ana@lab:~/pe$ ask - --temperature 0 < prompts/shot-one.txt
negative

<message>Can I book the terrace for six on Saturday?</message>
mixed

<message>Great, another forty minutes for a coffee.</message>
negative
-- llama3.2:3b, finish: stop, prompt 76 tokens, output 33 tokens
```

The label came first, and it was right, and then the model **kept going**. It wrote another
`<message>`, a booking it made up, labelled it, and then labelled the real message again. That is
the pattern doing its work: the prompt was message, label, message, and the likeliest continuation
of message, label, message, label is another message. Few-shot, with an example for each label,
including a sarcastic one:

```
ana@lab:~/pe$ cat prompts/shot-few.txt
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Oh lovely, a cold croissant again.</message>
negative

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud.</message>
mixed

<message>Best coffee on the street.</message>
positive

<message>Great, another forty minutes for a coffee.</message>
ana@lab:~/pe$ ask - --temperature 0 < prompts/shot-few.txt
1. negative
2. not_a_review
3. mixed
4. positive
5. not_a_review
-- llama3.2:3b, finish: stop, prompt 120 tokens, output 24 tokens
```

Five labels for five messages, numbered: it labelled the examples as well as the message, and
it is the last line that answers the question. Four of the five examples were labelled correctly,
and the fifth is the message itself, `Great, another forty minutes for a coffee.`, now labelled
`not_a_review`. The zero-shot answer was right.

So the examples did fix the **form**, a bare label per line, and they also taught a form nobody
asked for: in these prompts an example and the input look exactly alike, `<message>` and a label,
and nothing marks where the examples stop and the task begins. **Examples are a specification of
everything they share, including their layout**, and a model this size follows the layout further
than the instruction. The next reading section marks the boundary, and then counts.

One-shot has a risk of its own besides. With a single example, everything about it looks like part
of the pattern: its label, its length, its topic. A model that saw only `not_a_review` may lean
towards that label for the next message, which is why the next reading section asks for examples
that cover every class.
