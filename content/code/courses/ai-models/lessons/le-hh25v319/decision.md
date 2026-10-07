---
title: Deciding, and deciding again
version: 1
---

Everything is now on the table: lesson 4's thresholds, and this lesson's scores. Ana's floor for
sorting was 35 of 40, and for extraction ana sets it at **no invented or altered numbers at all**,
with misses allowed only if they are rare.

| task | llama3.2:3b | qwen2.5:3b | llama3.2:1b |
|---|---|---|---|
| sorting floor, 35 of 40 | fails, 19 | fails, 30 | fails, 5 |
| extraction, no wrong numbers | fails: two invented, one altered | fails: one altered, 14 missed | fails |
| in memory, from lesson 1 | 2.6 GB | not measured here | 1.5 GB |

**No candidate passes either floor.** That is not the evaluation failing; it is the evaluation doing
the one thing it is for, before Lantern Books depended on any of them. It also says what to try
next, and in what order, which is lesson 1 section 11's ladder:

1. **The prompt and examples.** qwen2.5:3b's sorting errors are boundaries drawn elsewhere, which
   labelled examples move, and llama3.2:3b's are lists, which an instruction or a structured-output
   feature removes. Both are hours of work and a re-run of this file.
2. **A larger model.** Three billion parameters is small; lesson 3 priced what a larger one asks of
   a machine, and lesson 4's matrix lists hosted ones that a key reaches. Each is a new row in the
   same run.
3. **Per task, not per shop.** If the re-run puts qwen2.5:3b over the sorting floor and llama3.2:3b
   over the extraction one, the answer is two models, and lesson 1 section 03 already had two loaded
   at once.

The rule that decides stays the same whatever the rows are: **the cheapest candidate that passes
every floor, per task**. Here the honest result is "none yet", with the reasons written down.

## The run is a baseline

The run that decided is kept, with the date, the exact model identifiers, the prompt and the
version of the cases. It becomes the **baseline** the next run is compared with, and there will be
a next run. Lesson 2 section 06 listed what triggers one: a model retired on the provider's date,
an alias that starts answering with a different model, a new candidate worth trying, a prompt
edited to fix the borderline cases. Each of those is a change to one input of the evaluation, and
the cases answer whether it made things worse.

`evalkit gate` makes that check something a program can refuse. It compares a model's loose score
in a new run with the baseline and fails, with exit status 1, if the new one is worse by more than
the cases allowed, one unless told otherwise:

```
ana@desk:~/desk$ cp runs/triage.jsonl runs/baseline.jsonl
ana@desk:~/desk$ python evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl qwen2.5:3b; echo "exit $?"
qwen2.5:3b: 30 before, 29 now, 1 allowed: pass
exit 0
ana@desk:~/desk$ python evalkit.py gate runs/baseline.jsonl runs/hot-b.jsonl qwen2.5:3b; echo "exit $?"
qwen2.5:3b: 30 before, 30 now, 1 allowed: pass
exit 0
```

Both runs at temperature 1 from section 08 pass: 29 and 30 against a baseline of 30, with one case
allowed. Allow none, and the first is refused:

```
ana@desk:~/desk$ python evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl qwen2.5:3b 0; echo "exit $?"
qwen2.5:3b: 30 before, 29 now, 0 allowed: FAIL
exit 1
```

**Exit status 1** is what lets a script, a scheduled job or a CI pipeline stop a change from going
out. How many cases to allow is a decision with the same shape as the floor: section 08 saw four
answers move between two runs of one model, so a gate that allows nothing at temperature 1 refuses
changes that changed nothing.

## What makes this the lesson that lasts

Every model this course names in lessons 6 to 20 will be replaced. The forty cases, the decision
about what counts as right, the harness, the intervals and the gate will not need to be. When the
next model arrives, the work of choosing it is to add a row and run the file: **an afternoon,
because the evaluation was already written**.
