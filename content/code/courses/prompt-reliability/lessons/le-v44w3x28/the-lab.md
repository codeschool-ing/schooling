---
title: The lab, and what in it is real
version: 1
---

A prompt that worked when you tried it has been tested once. **This course is about testing it the
other thirty-nine times**: writing down what a good answer is, running the prompt over messages it
has not seen, and counting. Everything after this section is a way of making that count more
honest, cheaper or harder to fool.

The whole course follows one prompt. Folio is an online bookshop, invented for the course, and its
support inbox needs every message sorted before a person reads it: a **category** (billing,
delivery, returns, account or other), an **urgency** (low, normal or high) and a one-sentence
**summary**. The answer is JSON, because a program reads it next.

## The harness

The lab is a directory, `~/triage`, built by `lab.sh` beside this course's `course.json`. It
needs Python and git, and nothing else:

```
ana@lab:~/triage$ ls
bin
cases
checks
prices.json
promptlab
prompts
runs
ana@lab:~/triage$ head -n 2 cases/dev.jsonl
{"id": "t01", "message": "I was charged twice for order 4471. Please refund the second payment.", "expect": {"category": "billing", "urgency": "high"}}
{"id": "t02", "message": "My parcel was meant to arrive on Monday and the tracking hasn't moved since Friday.", "expect": {"category": "delivery", "urgency": "normal"}}
ana@lab:~/triage$ wc -l cases/dev.jsonl
40 cases/dev.jsonl
```

`cases/dev.jsonl` is the **test set**: forty messages, one per line, each with the answer a person
decided was right. `prompts/` holds the prompts. `pl` is the command that joins them, and three of
its subcommands do most of the work in this course:

| command | what it does |
|---|---|
| `pl run PROMPT CASES --out RUN` | fills the prompt with each message, calls the model, and writes every reply to a file |
| `pl check RUN` | holds every reply to five checks and counts the passes |
| `pl show RUN ID` | prints one reply exactly as the model wrote it |

The checks run in order, and a reply that fails one fails every check after it: `json` (does it
parse), `fields` (does it have the fields and no others), `labels` (are the values from the
lists), `category` and `urgency` (do they match the person's answer). `all` counts the replies
that passed everything.

## The model is a stand-in

**The model in this lab is not a language model.** It is `promptlab/standin.py`, about four
hundred lines of Python written for the course, and its opening comment lists every rule it
answers by: it sorts a message by keywords, leans towards the labels its examples show, writes the
shape its first example has, and has a handful of formatting habits at fixed rates.

It is there for three reasons. It needs no API key and costs nothing. It answers the same way every
time, so the numbers in these lessons are the numbers you get when you run them. And its failures
were put there on purpose, so the harness always has something to find.

What that means for what you read: **every number in a transcript was computed by the harness,
and every reply was written by the stand-in.** The numbers are real arithmetic about made-up
behaviour. When a lesson says something about real models, it says so in the prose, and says
where the claim comes from. The harness does not care which is which; `promptlab/model.py` is the
one function that calls a model, and pointing it at a real one changes nothing else.

::: track ai
You wrote Python in `python`, so read `promptlab/cli.py` when a number surprises you: each check
is a few lines, and knowing exactly what it counts is half of trusting it.
:::

::: track *
You do not need to read the harness's code to use it. Each lesson says what a command counts, and
that is enough to argue with the number.
:::

## Where this course starts

`prompt-engineering` introduced the techniques: few-shot examples in its lessons 20 and 21,
temperature in lesson 13, injection in lesson 7. **This course takes several of them again on
purpose**, with a different question. There the question was what a technique is. Here it is
whether it still works on the fortieth message, and how you would know if it stopped.
