---
title: Where the time goes
version: 2
---

The intuitive picture is that a longer prompt is a slower prompt: more to send, more to read, a
longer wait. **For the wait a person feels, the length of the answer matters far more than the
length of the prompt**, and three prompts from earlier lessons show it on your own machine.

## Why output is the slow part

A model reads its whole input in one pass that can work on every token at once. Then it writes its
answer one token at a time, each token waiting for the one before it, which is how the decoder in
*Attention Is All You Need* (Vaswani and others, 2017) generates text. Reading a hundred tokens is
one step of work spread wide; writing a hundred is a hundred steps in a row. OpenAI's published
guide to latency optimisation makes the practical point: it lists generating fewer tokens among its
first principles, and says that cutting input tokens usually helps far less.

## Three prompts, timed

`stats.py`, from lesson 2, already reports what a run cost in tokens and in seconds. Here are three
prompts over the same forty messages, on the machine these lessons were captured on, four processor
cores and no graphics card:

```
ana@lab:~/triage$ pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl
40 calls, prompt 9c365e2d, llama3.2:3b, written to runs/v2.jsonl
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl
40 calls, prompt 1d9c6ec4, llama3.2:3b, written to runs/v3.jsonl
ana@lab:~/triage$ pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl
40 calls, prompt a4ffc4b1, llama3.2:3b, written to runs/v1.jsonl
ana@lab:~/triage$ python3 stats.py runs/v2.jsonl runs/v3.jsonl runs/v1.jsonl
runs/v2.jsonl, 40 calls
  tokens in    mean  106.2   total   4246
  tokens out   mean   30.8   total   1230   max 41
  seconds      p50   4.0   p95   5.5   total  171.3
runs/v3.jsonl, 40 calls
  tokens in    mean  248.2   total   9926
  tokens out   mean   30.6   total   1226   max 38
  seconds      p50   4.1   p95   5.0   total  168.2
runs/v1.jsonl, 40 calls
  tokens in    mean   61.1   total   2446
  tokens out   mean  106.2   total   4246   max 183
  seconds      p50  12.4   p95  15.6   total  485.8
```

`p50` is the median: half the calls were faster. `p95` is the time that 95 in a hundred calls beat,
which on forty calls means only two were slower. These are seconds on a wall clock, so your machine
will print its own; what should hold is the comparison between the three.

`v3-examples` sends more than twice the input of `v2-json`, 248.2 tokens a call against 106.2, and
writes the same amount, 30.6 against 30.8. Its median is 4.1 seconds against 4.0: **142 more tokens
of prompt cost a tenth of a second**. `v1-bare` sends the least of the three, 61.1 tokens, and writes
three and a half times as much, 106.2 tokens of chatty answer. Its median is 12.4 seconds, three
times the others, and its p95 is 15.6.

**If you want an answer sooner, look at what the model writes before you look at what you send.**
That is what lesson 3 found when JSON took the bare prompt's replies from 107.5 tokens to 30.6 and
the median call from 12.7 seconds to 3.7, and it is the same arithmetic here. Lesson 17 opens the
time of one call into its two halves, reading and writing, and shows why the long prompt here was
so cheap to read.
