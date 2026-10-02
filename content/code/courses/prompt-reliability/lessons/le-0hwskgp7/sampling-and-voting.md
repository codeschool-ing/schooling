---
title: Sampling and voting
version: 1
---

The other way to get several voters is to ask one prompt several times at a temperature above 0,
so that each answer is a fresh sample. It is the form self-consistency takes, and **in this lab it
does worse than not voting at all**:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
350 calls, prompt fbc4c9b1, written to runs/s5.jsonl
ana@lab:~/triage$ pl vote runs/s5.jsonl
runs/s5.jsonl              229/350 right
majority of the samples    52/70 right
unanimous on 27 cases, a tie on 6
```

Five samples of each of seventy messages, 350 calls. Each sample on its own was right 229 times in
350, about 65%. The vote of five per message was right on **52 of 70**. The same prompt at
temperature 0, in the last section's run, was right on 56.

Look at what sampling did to one message that temperature 0 got right:

```
ana@lab:~/triage$ pl show runs/s5.jsonl t37 --sample 0
│ {
│   "category": "other",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."
│ }
stop: end, tokens in 128, out 46
ana@lab:~/triage$ pl show runs/s5.jsonl t37 --sample 1
│ {
│   "category": "returns",
│   "urgency": "normal",
│   "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week."
│ }
stop: end, tokens in 128, out 46
```

`t37` is a late order, labelled delivery. Two samples, two different wrong labels.

## Why the vote lost

In the stand-in, temperature 0 picks the label with the highest score. Above 0, it draws a label at
random, with the highest-scoring label the likeliest draw and the others possible; `promptlab/sample.py`
says how. So each sample is the temperature-0 answer with **mistakes added around it**, and a vote
of samples is an attempt to take those mistakes away again. The most it can recover is the label
the draw favours, which is the label temperature 0 already gave, apart from ties.

With five samples it does not always recover even that. On a message where the favoured label comes
up less than half the time, the arithmetic from the first section runs backwards and the majority
lands elsewhere. Six of the seventy votes were ties, which `pl vote` settles by taking the first
sample. **Sampling added errors and voting took most of them away**, and most is less than all.

There is a trap in how this gets reported. Compared with a single sample at temperature 0.8, about
65% right, the vote looks like a gain. Compared with the answer you would have got by not sampling
at all, it is a loss. **Always compare an ensemble with the best single call**, not with one of its
own members.

## Where self-consistency comes from

The gains that made the technique known were real, and they came from a different kind of task.
*Self-Consistency Improves Chain of Thought Reasoning in Language Models* (Wang and others, 2022)
sampled several chains of reasoning for the same problem, arithmetic and commonsense questions
among them, and took a majority over their final answers. Its argument was that a problem has many
ways of reasoning to the right answer, and that wrong chains tend to scatter across different
wrong answers, so the right one collects the most votes.

A one-word classification has no chain. The sample is the answer, there is one way to reach it, and
the samples share every reason the prompt gives the model to lean one way. Before you pay for a
vote of samples, ask whether your task has **many different paths to one answer**. If it does not,
measure it against temperature 0 first, as above.
