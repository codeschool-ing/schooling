---
title: Reading a claim about a model
version: 1
---

An announcement says a model scores near-perfectly on a well-known test, and a video shows it
solving a hard problem in one go. The natural reading is that the model can now do that kind of
problem. **A score says how the model did on one set of questions, and a demo says it succeeded at
least once.** Neither says what it will do on your problem, and the gap between them is where most
disappointment comes from.

Five questions take a claim apart. The first two are about the test, the next two about the demo,
and the last about who is speaking.

## What was measured, and on what

A benchmark is a fixed set of questions with known answers, and a score is the share answered
correctly. **The score is only as meaningful as the questions**: a test that rewards the wrong
thing can be passed without the ability it claims to measure.

`toylm` makes this concrete. `bench.txt` is a three-question test of whether it knows the café:

```
is the coffee hot
is the bread fresh
is there cake
```

```
ana@lab:~/pe$ grep -c "question : is the bread fresh" corpus.txt
2
ana@lab:~/pe$ while read q; do echo "$q -> $(toylm generate "question : $q ? answer :" --temperature 0 | head -1)"; done < bench.txt
is the coffee hot -> yes.
is the bread fresh -> yes.
is there cake -> yes.
```

Three out of three. Now three questions it has never seen, from `new.txt`:

```
is the café open at midnight
is the soup free
is the cat a dog
```

```
ana@lab:~/pe$ while read q; do echo "$q -> $(toylm generate "question : $q ? answer :" --temperature 0 | head -1)"; done < new.txt
is the café open at midnight -> yes.
is the soup free -> yes.
is the cat a dog -> yes.
```

It answers `yes` to everything, because after `answer :` the word `yes` is what its corpus says
most often. Two things went wrong with the first test, and both happen to real benchmarks:

- every answer was the same, and a test whose answers are all `yes` measures whether the model
  says `yes`. Real benchmarks are built more carefully than this, and a model can still learn a
  pattern in how the questions are written that has nothing to do with the skill;
- the questions were in the training data: `grep` found the bread question twice in the corpus.
  This is called **contamination**: when a test's questions are published, they can end up in the
  text the next model is trained on, and a high score then measures memory, not ability.

So the questions to ask are what the benchmark measures, whether its questions could have been in
the training data, and how the model did on questions written after it was trained.

## A demo is a selected example

The same question, asked ten times with sampling, from ten seeds:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --samples 10
[seed 1] yes. question: is the coffee is hot.
[seed 2] tomato.
[seed 3] yes.
[seed 4] yes.
[seed 5] at six.
[seed 6] at six.
[seed 7] yes.
[seed 8] yes.
[seed 9] yes.
[seed 10] at seven.
```

Seed 10 is right: the corpus says the café opens at seven. **A recording of seed 10 alone would
make a convincing demo**, and it would be honest about that run and silent about the other nine.
Every demo is chosen by somebody, from runs they saw, and nobody records the run that failed for a
launch video. That does not make demos lies. It makes them evidence that something *can* happen.

## "Can" and "reliably does"

The distinction is the one that matters for anything you build. **"Can" means it happened at
least once. "Reliably does" means it happens on most attempts, on inputs like yours**, and the only
way to find out is to try many inputs and count. `toylm` *can* answer the opening-hours question;
it reliably does not, one run in ten. A large model is far better than this, and the question is the
same one: how often, on what. Lesson 27 is a technique that turns the variation between runs into
a vote, and the `prompt-reliability` course is about measuring it properly.

## Who measured it

A score in a vendor's announcement was chosen by the vendor, on tests the vendor picked, under
settings the vendor tuned. That does not make it false, and it is not independent evidence either.
A comparison made by somebody with no stake, with the method published so others can repeat it, is
worth more. So is a measurement you make yourself, on your own task.

The five questions, as a list to keep:

| ask | because |
|---|---|
| what exactly was measured? | a test can reward something other than the skill it names |
| could the questions have been in the training data? | contamination turns a test of ability into a test of memory |
| is this one run, or many? | a demo shows the run somebody chose |
| does it say "can" or "reliably"? | once is not most of the time |
| who measured it, and can it be repeated? | a vendor's number is a claim until somebody else gets it |
