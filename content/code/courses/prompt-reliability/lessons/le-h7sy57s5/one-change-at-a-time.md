---
title: One change at a time
version: 1
---

The obvious way to compare two ways of writing a prompt is to run both and keep the one that
scores higher. **That works only when the wording is the one thing that differs between the two
runs.** An experiment changes one thing, on the same test set, with the same parameters, or the
number it produces cannot say which change did it.

Here is what happens when that rule slips. `prompts/v6-escaped.txt` lists its fields as bullets,
and `prompts/v7-prose.txt` says the same things in a paragraph. Somebody runs the prose version to
see whether it reads better to the model, and happens to leave a sampling temperature of 0.8 in
the command from an earlier experiment:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, written to runs/v6.jsonl
ana@lab:~/triage$ pl run prompts/v7-prose.txt cases/all.jsonl --set temperature=0.8 --out runs/v7-warm.jsonl
70 calls, prompt 7864b0b5, written to runs/v7-warm.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/v7-warm.jsonl
runs/v6.jsonl            passes 46/70
runs/v7-warm.jsonl       passes 33/70
fixed 1, broken 14, still passing 32, still failing 23
broken: t06 t08 t10 t13 t18 t20 t21 t22 t25 t29 t37 h05 h07 h12
sign test on the 15 that changed: p = 0.001
```

Fourteen messages broke and one was fixed, and the sign test says p = 0.001. As evidence that
something changed, that is strong. As evidence that **prose is worse than bullets, it is worth
nothing**, because two things changed and the comparison cannot pull them apart. Temperature is
lesson 8's subject; for now it is enough that it makes the stand-in pick its label by chance, and
that this run is two changes wearing the name of one.

The trap is easy to fall into because the run file does not record it:

```
ana@lab:~/triage$ head -n 1 runs/v7-warm.jsonl
{"case": "t01", "sample": 0, "prompt": "7864b0b5", "cases": "cases/all.jsonl", "text": "{\n  \"category\": \"billing\",\n  \"urgency\": \"high\",\n  \"summary\": \"They were charged twice for order 4471.\"\n}", "stop": "end", "usage": {"input": 121, "cache_read": 0, "cache_write": 0, "output": 32}, "latency_ms": 1127}
```

Each line of a run keeps the message, the prompt's id, the test set, the reply, the stop reason,
the tokens and the time. **It does not keep the parameters you passed with `--set`.** The id
`7864b0b5` is a hash of the prompt file, so it is identical for the prose prompt at temperature 0
and at 0.8. Lesson 14 versions prompts properly; until then, write the command down with the run.

## What stays fixed

- **The test set.** Both runs read `cases/all.jsonl`, all seventy messages. Two runs on different
  messages compare the messages as much as the prompts.
- **The parameters.** Temperature, the output cap and everything else you can `--set`.
- **Everything in the prompt except the change.** The same labels, in the same order, with the
  same examples or none.
- **The comparison is message by message.** `pl compare` lines up each message's two results,
  because two totals that differ by two can hide fourteen messages moving in opposite directions.

The next section runs the experiment again, with the temperature where it belongs.
