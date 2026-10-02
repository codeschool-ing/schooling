---
title: Examples are a specification
version: 1
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

The labelling task of lesson 20, in three versions. The course wrote all three as illustrations,
and they are shortened to the part that changes.

Zero-shot, the description alone:

```localised
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Great, another forty minutes for a coffee.</message>
```

One-shot, the description and one solved example:

```localised
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Great, another forty minutes for a coffee.</message>
```

Few-shot, with an example for each label, including a sarcastic one:

```localised
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
```

The one-shot version fixes the **form**: a bare label on its own line, which the description also
asked for. It cannot fix the sarcasm, because its one example is not sarcastic. The few-shot
version has a sarcastic message labelled `negative`, which shows the boundary lesson 20 could only
describe. That is the case for examples in one sentence: **they answer the question "which side of
the line does this fall on?" by putting something on each side.**

One-shot has a risk of its own. With a single example, everything about it looks like part of the
pattern: its label, its length, its topic. A model that saw only `not_a_review` may lean towards
that label for the next message, which is why the next reading section asks for examples that
cover every class.
