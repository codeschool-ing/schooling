---
title: Choosing a temperature for the task
version: 1
---

A low temperature is not the safe choice and a high one is not the creative choice. **The right
temperature depends on whether the task has one right answer or many good ones.** Two runs of
six samples show the trade.

At 0.3, `seven` holds nearly all the share after `opens at`:

```
ana@lab:~/pe$ toylm dist "the café opens at" --temperature 0.3
context: trigram after 'opens at'
  seven     97.5%  #######################################
  eight      2.5%  #
```

Six draws, six of the same answer:

```
ana@lab:~/pe$ toylm generate "the café opens at" --temperature 0.3 --samples 6
[seed 1] seven.
[seed 2] seven.
[seed 3] seven.
[seed 4] seven.
[seed 5] seven.
[seed 6] seven.
```

At 1.5 the same six seeds give this:

```
ana@lab:~/pe$ toylm generate "the café opens at" --temperature 1.5 --samples 6
[seed 1] seven. question: when does the café opens at eight on sunday.
[seed 2] eight on sunday.
[seed 3] seven.
[seed 4] seven.
[seed 5] seven. question: when does it close? answer: yes.
[seed 6] eight on sunday.
```

**Variety came with nonsense in the same batch.** Two of the six say `eight on sunday`, which is
true of Sundays and is not when the café opens on the other six days. Seed 1 wanders into a
question with a grammar mistake in it, and seed 5 answers `yes` to a question about the time.
Each word followed the two before it somewhere in the file, which is all a trigram model checks,
and at 1.5 the unlikely continuations were drawn often enough to show.

`toylm` can only recombine pairs it has seen. A large model at a high temperature has its whole
vocabulary to draw from, so the drift goes further: a wrong name, an invented detail, a sentence
that changes subject halfway.

## Guidance by task

| the task | where to start | why |
|---|---|---|
| extracting fields, classifying, converting a format | 0, or close to it | there is one right output, and variation is only error |
| answering from documents you supplied | low | the answer is in the text; drawing an unlikely token only moves away from it |
| ordinary writing, explanation, conversation | the provider's default | defaults are chosen for this kind of use |
| brainstorming, names, alternatives to pick from | higher | you want different candidates on each run, and you will throw most of them away |

Start there and **change it while you watch the output**, one step at a time. The table gives no
numbers for "low" and "higher" because the scale is not shared: each API documents its own range
and its own default, and the same number does not mean the same thing on two models. Read the
range in the documentation of the API you call.

## What temperature cannot do

**Temperature does not make an answer more true.** It only decides how far down the list of
likely continuations a draw may reach. A low temperature gives you the model's most likely
answer, and lesson 5 showed that likely and true are not the same thing. A high temperature gives
you more of the unlikely ones, which are wrong more often, not wiser.

It also cannot fix a vague prompt. If the prompt leaves three readings open, temperature 0 picks
the most likely reading every time and the others never appear, so the ambiguity is hidden, not
removed. The fix for that is in the prompt, which is what most of this course is about.

Temperature is one of several controls on the same draw. Lesson 14 shows two more, top-k and
top-p, which cut words off the list before the draw instead of reshaping it.
