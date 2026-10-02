---
title: Propose many prompts, score each one, keep the best
version: 1
---

The usual way to improve a prompt is to read it, decide what sounds clearer, and rewrite it. That
works up to a point, and it rests on an assumption: that the prompt which reads best to you is the
one that works best on the model. Lesson 30 showed that the best prompt need not be words at all.
**Automatic prompt engineering drops the assumption and measures instead: generate many candidate
prompts, score each one on examples whose answers you know, and keep the one that scores highest.**

The method has four parts. Proposing needs a model that writes prompts; scoring needs the
model you will use, run by a program that counts:

1. Propose. A model is shown a few examples of the task and asked to write instructions that
   would produce them, many times over.
2. Score. Each candidate is run on a set of labelled examples, and a metric counts how many of
   its answers are right.
3. Keep. The highest score wins.
4. Refine, if you want. The model is asked for variations of the winner, and those are scored
   in turn.

The name comes from a 2022 paper, "Large Language Models Are Human-Level Prompt Engineers", which
called the method APE.

## Asking a model for instructions

The proposing step is itself a prompt, a *meta-prompt*: a prompt whose output is a prompt. It shows
input and output pairs and leaves the instruction for the model to fill in. This one, and the
candidates under it, were written by the course as an illustration:

```localised
I gave a friend an instruction and four inputs. The friend read the
instruction and wrote one output for each input. Here are the pairs:

Input: coffee     Output: hot
Input: tea        Output: hot
Input: bread      Output: fresh
Input: terrace    Output: open

The instruction was:

  - Describe the item in one word.
  - Give the adjective a café would use for each item.
  - Say how each thing usually is at the café.
```

Asked again with sampling on (lesson 13), the same meta-prompt gives other wordings, and that is
what you want here: **the proposer's job is variety, and the scorer's job is judgement.**

## Scoring, for real

`ape` does the scoring half on the workbench. It takes a file of prompt templates, one per line,
with `{x}` where the input goes, and a file of examples, the input and the expected first word
separated by a tab. It fills each template with each input, lets `toylm` continue at temperature 0,
and gives a point when the first word of the reply is the expected one.

The candidates below are what a person might write, plus two plain ones:

```
ana@lab:~/pe$ cat candidates.txt
Describe the {x} in one word:
question : what is the {x} like ? answer :
{x}
it is a cold day and the {x} is
the {x} is
ana@lab:~/pe$ cat tests.tsv
coffee	hot
tea	hot
bread	fresh
terrace	open
ana@lab:~/pe$ ape candidates.txt tests.tsv
0/4  Describe the {x} in one word:
        coffee  wanted hot     got is
        tea     wanted hot     got is
        bread   wanted fresh   got is
        terrace wanted open    got is
0/4  question : what is the {x} like ? answer :
        coffee  wanted hot     got yes
        tea     wanted hot     got yes
        bread   wanted fresh   got yes
        terrace wanted open    got yes
0/4  {x}
        coffee  wanted hot     got is
        tea     wanted hot     got is
        bread   wanted fresh   got is
        terrace wanted open    got is
4/4  it is a cold day and the {x} is
4/4  the {x} is
best: it is a cold day and the {x} is
```

The instruction a person would write first scored nothing. So did the question in the format the
café's own file uses, which looks like the cleverest of the five. **The templates that won are the
ones that suit this model, and nobody would have picked them by reading.**

The reason is in what `toylm` can see. It looks at the last two words (lesson 1), so after the
question template it sees `answer :` and nothing else, and it answers `yes` whatever the item was.
The instruction ends in `word:`, and that is not a pair it has ever seen:

```
ana@lab:~/pe$ toylm next "describe the coffee in one word :"
context: bigram after ':'
  is        25.0%  ##########
  yes       25.0%  ##########
  at        16.7%  #######
  when      16.7%  #######
  tomato     8.3%  ###
  what       8.3%  ###
```

It falls back to what follows a colon anywhere in its file, and `is` and `yes` tie at the top. Only
the two templates ending in `the {x} is` put the item where the model can see it.

A large model sees far more than two words, and it would follow the instruction well. **The lesson
carries over all the same: the prompt that suits a model is a fact about that model, found by
testing it.** A wording that reads well and a wording that scores well can differ on a large model
too, in ways much harder to explain than this one. Measuring finds them without needing the
explanation.
