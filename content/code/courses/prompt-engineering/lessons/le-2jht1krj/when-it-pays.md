---
title: The model as proposer and judge, and when it pays
version: 1
---

`tot` does its proposing and judging with exact arithmetic. In the method as published, and in the
paper that introduced it with this same puzzle, **a language model does both jobs, and an ordinary
program around it does the searching**: it keeps the list of states, decides which to expand,
counts levels and stops. The model is called many times, once for each proposal and once for each
judgement.

## Two prompts

The proposer is asked for possible next steps from one state. The judge is asked about one state
at a time. This is an evaluation prompt the course wrote as an example; it was not run, since the
workbench has no model:

```
Numbers left: 4 13 19
Goal: make 24 using each number exactly once, with + - * /.
Try a few combinations, then give your verdict on the last line:
sure (you found a way), likely (it looks reachable), or impossible (every attempt is far off).
```

And the course's illustration of a reply:

```localised
19 - 13 = 6, and 4 * 6 = 24.
Verdict: sure
```

Here the judge happened to find a solution, so `sure` is easy. Most states are harder: the judge
tries a few combinations, finds nothing that obviously works, and has to guess between `likely` and
`impossible`. **That guess is where the search can go wrong**, which is why the previous section's
breadth matters with a model and not with `tot`. Implementations often ask the judge several times
per state and combine the verdicts, which is lesson 27's vote applied to one step.

## How many calls one answer takes

Count them on the capture from the previous section. Suppose a model had judged every different state
`tot` proposed: 36 at level 1, 47 at level 2 and 7 at level 3. **That is 90 calls to judge, plus the
calls that proposed the steps, for one answer to one puzzle.** A chain of thought
would have been one call. Each of those calls is short, and many can run in parallel, but the bill
counts every one of them.

That makes tree of thoughts the most expensive technique in this part of the course by a wide
margin, and the cost is the first thing to weigh.

## When it is worth it

The method pays on problems with two properties together.

**Intermediate states can be judged.** After one step of the Game of 24 you can ask a meaningful
question: can 24 still be reached from these three numbers? A crossword half filled in, a plan with
three of six steps chosen, a proof with two lemmas done: each partial state can be checked against
the constraints. Where a partial answer cannot be judged, as with the first paragraph of a
customer reply, the tree has nothing to prune by and becomes self-consistency with extra steps.

**There are dead ends, and an early step can lead into one.** In the capture, 29 of the 36 first
steps could never reach 24. A single chain that picked one of those would have spent all its later
steps for nothing. Problems whose every path leads somewhere sensible, such as summarising, or
answering a question from one handbook page, gain nothing from exploring alternatives.

## The three side by side

| | chain of thought (lesson 26) | self-consistency (lesson 27) | tree of thoughts |
|---|---|---|---|
| paths | one | several, independent | several, branching from shared steps |
| when paths are compared | never | at the end, by final answer | at every step, by a judgement |
| a dead end | is followed to the end | is outvoted, if it is rare | is dropped when it is judged |
| calls per answer | one | one per sample | one per proposal and per judgement |

**Use the cheapest technique that works on your problem.** A chain of thought is the default for
anything with intermediate steps. A vote over several chains is for answers that can be compared,
where a wrong one is costly. A tree is only for a problem that is a search, with states you can
judge and dead ends you need to leave early. Lesson 29 adds the remaining piece, a model that
calls tools between its steps.
