---
title: Sampling and voting
version: 2
---

The other way to get several voters is to ask one prompt several times at a temperature above 0, so
that each answer is a fresh sample. It is the form self-consistency takes. Here is `v6-escaped`,
five samples per message at 0.8, voted:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl
350 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/s5.jsonl
ana@lab:~/triage$ python3 vote.py runs/s5.jsonl
sample 0                  46/70 right
sample 1                  47/70 right
sample 2                  45/70 right
sample 3                  43/70 right
sample 4                  46/70 right
majority of 5             46/70 right
unanimous on 61 cases, a tie on 0
```

Five samples of each of seventy messages, 350 calls. Each sample on its own was right between 43
and 47 times, and the vote of five was right 46 times. The same prompt at temperature 0, in the last
section's run, was right 45 times. **One more right answer, for five times the calls.** All five
samples agreed on 61 of the seventy messages, so on most messages sampling changed nothing at all.

## Where the samples disagreed

The first `awk` keeps the first three characters of each failure, the case without its sample
number. `uniq -c` counts how many samples of each case failed, and the last `awk` keeps the cases
that failed in some samples and not all five:

```
ana@lab:~/triage$ pl check runs/s5.jsonl --failures | awk '$2 == "json" || $2 == "category" {print substr($1, 1, 3)}' | sort | uniq -c | awk '$1 < 5'
      3 h17
      2 h19
      1 h26
      1 t12
      1 t16
```

Five messages split. On `h17`, three samples of five were wrong, and so was the vote, and so was
temperature 0. On the other four the majority was right, and temperature 0 had been right as well.
These are the close calls lesson 8 found, and voting gave each one the answer temperature 0 already
gave.

The one message that moved is not a close call about a label. It is `t38`:

```
ana@lab:~/triage$ pl show runs/v6.jsonl t38
│ {"category": "returns", "urgency": "high", "summary": "Ebook won"}}
stop: stop, tokens in 145, out 22, 2.6 s
ana@lab:~/triage$ pl check runs/s5.jsonl --failures | grep '^t38'
t38    urgency   high, expected normal
t38#1  urgency   high, expected normal
t38#2  urgency   high, expected normal
t38#3  urgency   high, expected normal
t38#4  urgency   high, expected normal
```

At temperature 0, `v6-escaped` cuts `t38`'s summary at the apostrophe of *won't* and adds a second
closing brace, the failure lesson 15 logged as F-0001. At 0.8 the five samples wrote the summary
differently, all five parsed, and all five had the right category; the urgency is wrong in all of
them, which the vote does not count. **Sampling did not find a better label here. It stepped around
a formatting bug**, which a fixed prompt would step around for one call instead of five.

## Compare with the best single call

There is a trap in how this gets reported. Compared with a single sample at 0.8, between 43 and 47,
the vote looks like a small win. Compared with the answer you get by not sampling at all, it is one
message better. Compared with the best single prompt you have, `v3-examples` at 54, it is eight
worse. **Always compare an ensemble with the best single call**, not with one of its own members.

## Where self-consistency comes from

The gains that made the technique known were real, and they came from a different kind of task.
*Self-Consistency Improves Chain of Thought Reasoning in Language Models* (Wang and others, 2022)
sampled several chains of reasoning for the same problem, arithmetic and commonsense questions among
them, and took a majority over their final answers. Its argument was that a problem has many ways of
reasoning to the right answer, and that wrong chains tend to scatter across different wrong
answers, so the right one collects the most votes.

A one-word classification has no chain. The sample is the answer, there is one way to reach it, and
the samples share every reason the prompt gives the model to lean one way: here they agreed on 61
messages of seventy. Before you pay for a vote of samples, ask whether your task has **many
different paths to one answer**. If it does not, measure it against temperature 0 first, as above.
