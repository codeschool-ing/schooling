---
title: One template, every case
version: 1
---

A test set is possible because of templates. **Forty runs of one template, with only the message
changing, means any difference between two runs is the template's doing**, and that is the
condition every comparison in this course rests on. The same file renders every case the same way:

```
ana@lab:~/triage$ pl render prompts/v6-escaped.txt --cases cases/dev.jsonl --case t02 | tail -n 3
<message>
My parcel was meant to arrive on Monday and the tracking hasn't moved since Friday.
</message>
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/dev.jsonl --out runs/v6.jsonl
40 calls, prompt fbc4c9b1, written to runs/v6.jsonl
```

If the instructions were pasted into forty files, or edited by hand for an awkward message, the run
would be measuring forty prompts at once, and a change to one of them would show up as noise in
the count.

## The settings belong with the template

The message is not the only thing that changes what the model does. The temperature, the output
limit, the model and the cache are settings too, and a prompt file in this lab can carry them in a
header, one `name: value` per line, above a line of three dashes:

```
ana@lab:~/triage$ head -n 3 prompts/v17-static-first.txt
cache: on
---
You sort customer messages for Folio, an online bookshop, so that the right
```

`cache: on` is lesson 17's subject. What matters here is where it is written: in the same file as
the instructions, so a person reading the prompt sees every value it runs with.

## What the prompt id covers

`pl run` prints an id for the prompt it ran, and records it on every line of the run. It is the
first eight characters of the SHA-256 of the file:

```
ana@lab:~/triage$ pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/v17.jsonl
40 calls, prompt b04095b1, written to runs/v17.jsonl
ana@lab:~/triage$ sha256sum prompts/v17-static-first.txt | cut -c1-8
b04095b1
ana@lab:~/triage$ pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/v17-hot.jsonl --set temperature=0.8
40 calls, prompt b04095b1, written to runs/v17-hot.jsonl
```

Change a word, a blank line or a setting in the header and the id changes. **Set the temperature on
the command line instead, and the id stays the same**: the two runs above both say `b04095b1`,
and one of them sampled at 0.8. Anybody comparing the two later, from the run files alone, would
believe they ran the same prompt. That is the practical argument for the header. A setting written
in the file is covered by the id, and a setting typed on a command line is covered by nothing
unless somebody writes it down. Lesson 14 builds on that id to track what each change did.
