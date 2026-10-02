---
title: What a version is
version: 1
---

The natural answer is that a version of a prompt is its text, and a commit of the file is a new
version. **That is most of it, and the part it misses is the part that breaks.**

## The id is the file

Every `pl run` prints a prompt id, and the id is not a counter. It is the first eight characters of
a SHA-256 hash of the file's bytes, so the same bytes always give the same id, wherever they came
from:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/now.jsonl
40 calls, prompt c1916fcd, written to runs/now.jsonl
ana@lab:~/triage$ git show c8470c9:prompts/triage.txt > runs/triage-c8470c9.txt
ana@lab:~/triage$ pl run runs/triage-c8470c9.txt cases/dev.jsonl --out runs/c8470c9.jsonl
40 calls, prompt c1916fcd, written to runs/c8470c9.jsonl
ana@lab:~/triage$ git diff c8470c9 03e1151 -- prompts/triage.txt | wc -l
0
```

`git show c8470c9:prompts/triage.txt` prints the file as it was at that commit, and the run of that
old copy has the id of today's file, `c1916fcd`. The diff between the two commits has no lines at
all: the newest commit put the file back to exactly what it was on 11 August, so the two are one
version under two commit hashes. **An id computed from the content cannot be fooled by a rename,
a copy or a revert**, which is what you want from the thing a result is filed under.

## The same id, a different prompt

Now run the same file with one parameter changed on the command line:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --set temperature=0.8 --out runs/hot.jsonl
40 calls, prompt c1916fcd, written to runs/hot.jsonl
ana@lab:~/triage$ pl check runs/hot.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     31     9
urgency      28    12
all          28    12
```

The id is still `c1916fcd`, and the score went from 36 of 40 to 28. The file did not change, so its
hash did not either; what changed was a setting the hash never saw. Two runs filed under one id
now disagree by eight messages, and **anybody reading the results later has no way to tell them
apart**. Lesson 8 is where temperature itself is measured; here it is only the easiest setting to
change by accident.

That is the reason the harness reads parameters from the top of the prompt file. A file may start
with `name: value` lines and a line `---`, and everything above the `---` is a setting:

```
ana@lab:~/triage$ head -n 2 prompts/v17-static-first.txt
cache: on
---
```

`cache` is the one lesson 17 uses; `model`, `temperature`, `top_k`, `top_p` and `max_tokens` are
the others. A parameter written there is part of the bytes, so changing it changes the id. **A
parameter passed on the command line belongs to the run, and nothing records it.**

## Four things make a version

- **The text**, which git already tracks.
- **The parameters**, in the file where the hash can see them.
- **The model.** A different model given the same text is a different prompt in every way that
  matters, because the text is only half of what produces the answer. Several providers publish
  model names with a date in them alongside shorter aliases that move to a newer model when one is
  released; Anthropic's and OpenAI's model documentation both describe the difference. Name the
  dated one in the header and the move becomes a commit somebody can see. The stand-in has one
  model, so the lab cannot show this one changing.
- **The test set**, because a score belongs to a pair. Thirty-six of forty means something only
  beside the forty, and `cases/dev.jsonl` is in git too, so its version is a commit like the
  prompt's.

A result written down without all four is a result about something you can no longer rebuild.
