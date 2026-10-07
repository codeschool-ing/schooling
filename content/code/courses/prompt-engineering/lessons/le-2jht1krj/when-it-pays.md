---
title: The model as proposer and judge, and when it pays
version: 2
---

`tot` does its proposing and judging with exact arithmetic. In the method as published, and in the
paper that introduced it with this same puzzle, **a language model does both jobs, and an ordinary
program around it does the searching**: it keeps the list of states, decides which to expand,
counts levels and stops. The model is called many times, once for each proposal and once for each
judgement.

## Two prompts

The proposer is asked for possible next steps from one state. The judge is asked about one state
at a time. Here is an evaluation prompt for the state `tot` kept at level 1 with `4 13 19` left,
saved as `~/pe/prompts/judge.txt`, sent to the local model:

```
ana@lab:~/pe$ cat prompts/judge.txt
Numbers left: 4 13 19
Goal: make 24 using each number exactly once, with + - * /.
Try a few combinations, then give your verdict on the last line:
sure (you found a way), likely (it looks reachable), or impossible (every attempt is far off).
ana@lab:~/pe$ ask - --temperature 0 < prompts/judge.txt
Let's try a few combinations:

1. (13 + 4) * 19 = 217 (not 24)
2. (19 - 4) * 13 = 221 (not 24)
3. (19 + 4) * 13 = 247 (not 24)
4. (19 + 13) * 4 = 208 (not 24)
5. (19 - 13) * 4 = 6 (not 24)
6. (19 + 13) / 4 = 8 (not 24)
7. (19 - 4) / 13 = 1.38 (not 24)
8. (13 + 4) / 19 = 0.74 (not 24)
9. (19 + 4) / 13 = 2.46 (not 24)
10. (19 - 4) / 13 = 1.38 (not 24)
11. (13 + 4) * 19 / 13 = 24 (yes!)

Verdict: sure (I found a way)
-- llama3.2:3b, finish: stop, prompt 88 tokens, output 236 tokens
```

`4 13 19` can make 24: `tot` found it at level 2, `19 - 13 = 6`, then `4 * 6`. The model tried
that very combination on line 5 and wrote `(19 - 13) * 4 = 6`. Then on line 11 it wrote
`(13 + 4) * 19 / 13 = 24`, which uses 13 twice and comes to 24.85, and on the strength of it said
**sure**. The verdict is right, and the reason for it is false. A judgement reached that way could as easily have said impossible, and pruned the branch that solves the puzzle. **That is where the search
goes wrong with a model in it**: not in the search, which is plain bookkeeping, but in a judgement
nobody checks.

A state with no way to 24, `1 1 2`, shows the other risk. The same prompt, with a limit of 150
tokens:

```
ana@lab:~/pe$ sed "s/4 13 19/1 1 2/" prompts/judge.txt > prompts/judge-dead.txt
ana@lab:~/pe$ ask - --temperature 0 --max-tokens 150 < prompts/judge-dead.txt
Let's try a few combinations:

1. (1 + 2) * 1 = 3 (not enough)
2. (1 + 1) * 2 = 4 (not enough)
3. (1 + 2) - 1 = 2 (not enough)
4. (1 + 1) - 2 = 0 (not enough)
5. (1 + 2) / 1 = 3 (not enough)
6. (1 + 1) / 2 = 1.5 (not enough)
7. (1 + 2) * (1 + 1) = 6 (not enough)
8. (1 + 2) * (1
-- llama3.2:3b, finish: length, prompt 88 tokens, output 150 tokens
```

It was cut off mid-list, at 150 tokens, and still had not reached a verdict. A judge that goes through combinations one by one can cost many times what a judgement should, which is what lesson 15's limit is for.

This is why the previous section's breadth matters with a model and not with `tot`, and why
implementations often ask the judge several times per state and combine the verdicts: lesson 27's
vote, applied to one step, with lesson 27's limits.

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
