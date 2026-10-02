---
title: What makes it engineering
version: 1
---

"Prompt engineering" is often heard as a collection of magic phrases: the wording that unlocks a
better answer, passed from person to person. Some phrasings do work better than others, and a list
of them is not engineering. **Engineering is a stated goal, a test that says whether the goal was
met, and changes measured against that test.** The wording is what you change; the test is what
tells you whether the change helped.

Five habits make the difference, and every lesson after this one leans on them:

| habit | what it means for a prompt |
|---|---|
| a stated goal | one sentence saying what a good reply is, written before the prompt |
| test cases | inputs you send every time, each with what an acceptable reply must contain |
| iteration | one change at a time, each run against the same tests |
| versioning | every version kept and named, so a regression can be traced to the change that caused it |
| measuring | a count of passes over many runs, not your impression of one reply |

## Three versions of one prompt, measured

Here is the whole cycle on `toylm`, small enough to watch. The goal: **a customer asks when the
café opens, and the reply must be the weekday time, `seven`.** The three versions are kept in files,
one per version:

```
ana@lab:~/pe$ cat prompts/v1.txt prompts/v2.txt prompts/v3.txt
question : when does the café open ? answer :
question : when does the café open ? answer : at
the café opens at
```

`v1` is the question as a customer would ask it, and the section before this one showed what it
gets: `yes.` `v2` adds the first word of the answer, `at`, so that the only likely continuation is
a time. Four draws from it look promising:

```
ana@lab:~/pe$ toylm generate "$(cat prompts/v2.txt)" --samples 4
[seed 1] seven. question: is the coffee is hot.
[seed 2] six.
[seed 3] seven.
[seed 4] seven.
```

Three out of four, and one `six`, which is the closing time. Four replies are an impression, not a
measurement. The test runs each version twenty times and counts the replies that contain `seven`:

```
ana@lab:~/pe$ for v in v1 v2 v3; do echo "$v $(toylm generate "$(cat prompts/$v.txt)" --samples 20 | grep -c seven)/20"; done
v1 1/20
v2 12/20
v3 16/20
```

**The numbers settle what reading a few replies could not.** `v2` is a real improvement on `v1`
and still misses eight times in twenty, because after `: at` the model cannot see whether
the question was about opening or closing. `v3` puts the word `opens` right where the model looks,
and passes sixteen times in twenty. Without the files, `v2`'s fixed form would be lost the moment
somebody "improved" it, and without the count, `v2` would have looked finished after four draws.

A large model is not tested with `grep` for one word, and the test is harder to write. The cycle is
the same.

::: track ai prompt
Lesson 19 checks a reply's structure with a schema, and the `prompt-reliability` course, next in
your track, builds the evaluation of prompts properly.
:::

::: track *
Lesson 19 checks a reply's structure with a schema, and lesson 31 scores whole prompt templates
against a set of labelled tests.
:::

## A vague prompt and a specific one

The first draft of a prompt is usually the request as you would say it to a colleague who already
knows the context. The model knows none of it. Two prompts for the same job, written by the course
as an illustration:

```localised
Vague:
  Write something about our opening hours.

Specific:
  You are writing the notice for the door of Café Aurora.
  Opening hours: Monday to Saturday 07:00 to 18:00; Sunday 08:00 to 12:00.
  The kitchen stops taking hot food orders 30 minutes before closing.
  Write the notice in English, at most four lines, one line per rule.
  Do not add any information that is not in these hours.
```

The vague one can be answered in a thousand ways and all of them pass, because nothing says what a
good answer is. **The specific one is longer because it carries the four parts a prompt can have**,
and each one closes a way the reply could go wrong:

| part | in the example | what goes wrong without it |
|---|---|---|
| instruction | write the notice for the door | the model guesses the task: an advert, a tweet, an essay |
| context | Café Aurora, the kitchen rule | the model fills the gap with what is typical, which may be false (lesson 5) |
| input data | the hours themselves | there is nothing to be right about |
| output format | English, four lines, one per rule | a reply that is correct and cannot be used where it is going |

Not every prompt needs all four, and longer is not better on its own: every word is something the
model continues from. The question to ask of each line is the one the test answers. **Does the
reply get better when it is there, and worse when it is not?**
