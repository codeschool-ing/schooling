---
title: What a version is
version: 2
---

The natural answer is that a version of a prompt is its text, and a commit of the file is a new
version. **That is most of it, and the part it misses is the part that breaks.**

## The id is the file

Every `pl run` prints a prompt id, and the id is not a counter. It is the first eight characters of
a SHA-256 hash of the file's bytes, so the same bytes always give the same id, wherever they came
from:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --out runs/now.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/now.jsonl
ana@lab:~/triage$ git show c8f1927:prompts/triage.txt > runs/triage-c8f1927.txt
ana@lab:~/triage$ pl run runs/triage-c8f1927.txt cases/dev.jsonl --out runs/c8f1927.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/c8f1927.jsonl
ana@lab:~/triage$ git diff c8f1927 85dfa4e -- prompts/triage.txt | wc -l
0
```

`git show c8f1927:prompts/triage.txt` prints the file as it was at that commit, and the run of that
old copy has the id of today's file, `c1916fcd`. The diff between the two commits has no lines at
all: the newest commit put the file back to exactly what it was on 11 August, so the two are one
version under two commit hashes. **An id computed from the content cannot be fooled by a rename,
a copy or a revert**, which is what you want from the thing a result is filed under.

## The same id, a different prompt

Now run the same file with one parameter changed on the command line:

```
ana@lab:~/triage$ pl run prompts/triage.txt cases/dev.jsonl --set temperature=0.8 --out runs/hot.jsonl
40 calls, prompt c1916fcd, llama3.2:3b, written to runs/hot.jsonl
ana@lab:~/triage$ pl check runs/hot.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     36     4
urgency      24    16
all          24    16
```

The id is still `c1916fcd`, and 24 of 40 pass, which is also what the default run passes; the last
section of this lesson compares the two. The file did not change, so its hash did not either: what
changed was a setting the hash never saw. The same total says nothing about whether the same
messages passed, and they did not. **Two runs filed under one id, made with different settings, and
anybody reading the results later has no way to tell them apart.** Lesson 8 is where temperature
itself is measured; here it is only the easiest setting to change by accident.

That is the reason the harness reads parameters from the top of the prompt file, as lesson 4's
`v6-header.txt` and lesson 8's `reply-varied.txt` do: a file may start with `name: value` lines and
a line `---`, and everything above the `---` is a setting. **A parameter written there is part of
the bytes, so changing it changes the id. A parameter passed on the command line belongs to the
run, and nothing records it.**

## Four things make a version

- **The text**, which git already tracks.
- **The parameters**, in the file where the hash can see them.
- **The model.** A different model given the same text is a different prompt in every way that
  matters, because the text is only half of what produces the answer. `pl` sends `llama3.2:3b`, a
  name and a tag; Ollama's `ollama list` shows the id behind the tag, `a80c4f17acd5`, and a tag can
  be pulled again and point at different weights. Hosted providers publish model names with a date
  in them alongside shorter aliases that move to a newer model when one is released; Anthropic's and
  OpenAI's model documentation both describe the difference. Name the exact one in the header and a
  move becomes a commit somebody can see.
- **The test set**, because a score belongs to a pair. A count out of forty means something only
  beside the forty, and `cases/dev.jsonl` belongs in git too, so its version is a commit like the
  prompt's.

And lesson 8 adds a fifth that no file can hold: **the machine**. The same prompt, model, settings
and test set printed 22 on one machine and 21 on another. A result written down without all of
these is a result about something you can no longer rebuild exactly; the most you can do is write
down what it ran on.
