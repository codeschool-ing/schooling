---
title: One change at a time
version: 2
---

The obvious way to compare two ways of writing a prompt is to run both and keep the one that
scores higher. **That works only when the wording is the one thing that differs between the two
runs.** An experiment changes one thing, on the same test set, with the same parameters, or the
number it produces cannot say which change did it.

Here is what happens when that rule slips. `prompts/v6-escaped.txt`, from lesson 4, lists its
fields as bullets, and `prompts/v7-prose.txt`, the next section's prompt, says the same things in a
paragraph. Somebody runs the prose version to see whether it reads better to the model, and happens
to leave a sampling temperature of 0.8 in the command from an earlier experiment:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6.jsonl
ana@lab:~/triage$ pl run prompts/v7-prose.txt cases/all.jsonl --set temperature=0.8 --out runs/v7-warm.jsonl
70 calls, prompt 7864b0b5, llama3.2:3b, written to runs/v7-warm.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/v7-warm.jsonl
runs/v6.jsonl            passes 26/70
runs/v7-warm.jsonl       passes 24/70
fixed 5, broken 7
broken: t04 t11 t12 t17 h13 h15 h19
sign test on the 12 that changed: p = 0.774
```

Seven messages broke and five were fixed, and the sign test says p = 0.774: nothing a coin would not
do. So the prose prompt did no harm? **The comparison cannot say**, in either direction. Two things
changed, and a small total difference can hide two effects pulling against each other as easily as
it can mean neither did anything. Temperature is lesson 8's subject; for now it is enough that it
makes the model draw its answer by chance, and that this run is two changes wearing the name of
one.

The trap is easy to fall into because the run file does not record it:

```
ana@lab:~/triage$ head -n 1 runs/v7-warm.jsonl
{"case": "t01", "sample": 0, "cases": "cases/all.jsonl", "prompt": "7864b0b5", "text": "{\"category\": \"billing\", \"urgency\": \"high\", \"summary\": \"Refund the second payment for order 4471\"}", "stop": "stop", "tokens_in": 153, "tokens_out": 29, "seconds": 4.45}
```

Each line of a run keeps the case's id, the prompt's id, the test set, the reply, the stop reason,
the tokens and the time. **It does not keep the parameters you passed with `--set`.** The id
`7864b0b5` is a hash of the prompt file, so it is identical for the prose prompt at temperature 0
and at 0.8. Lesson 4 said the same about a setting typed on the command line; lesson 14 versions
prompts properly. Until then, write the command down with the run.

## What stays fixed

- The test set. Both runs read `cases/all.jsonl`, all seventy messages. Two runs on different
  messages compare the messages as much as the prompts.
- The parameters. Temperature, the output cap and everything else you can `--set`.
- Everything in the prompt except the change. The same labels, in the same order, with the
  same examples or none.
- The comparison is message by message. `pl compare` lines up each message's two results,
  because two totals that differ by two can hide a dozen messages moving in opposite directions.

The next section runs the experiment again, with the temperature where it belongs.
