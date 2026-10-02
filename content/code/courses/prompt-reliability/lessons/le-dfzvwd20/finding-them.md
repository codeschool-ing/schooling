---
title: Finding them before the model does
version: 1
---

You found the contradiction in `v2-long.txt` by reading, because the prompt is short and the two
lines use obvious words. A prompt of sixty lines, edited by four people over a year, is read by
nobody end to end. **A linter reads every line every time**, and it is cheap enough to run before
each change:

```
ana@lab:~/triage$ pl lint prompts/v2-long.txt
prompts/v2-long.txt:4: contradiction (length): lines 4 against lines 16
prompts/v2-long.txt:11: 3 lines shout: 11,13,14
prompts/v2-long.txt:14: repeats line 11
167 tokens
ana@lab:~/triage$ pl lint prompts/v2-json.txt
prompts/v2-json.txt: nothing found
69 tokens
```

Three findings for the long prompt and none for the short one. Each finding names a line, so it
can be fixed where it is:

| finding | what it means |
|---|---|
| `contradiction (length)` | a line asking for brevity and a line asking for detail, in one prompt |
| `3 lines shout` | lines with words like IMPORTANT or NEVER, which raise some rules above the rest |
| `repeats line 11` | the same instruction twice, word for word |

## What the linter is reading

`pl lint` is a few lists of words and patterns. It knows that *brief*, *concise*, *short* and *one
sentence* pull one way and *in detail*, *thorough* and *everything* pull the other, and it reports
a prompt that contains both. **It does not understand either instruction.** Two consequences
follow, and both show up in this lab.

It misses a contradiction written in other words:

```
ana@lab:~/triage$ printf 'Keep the summary to one line.\nLeave nothing out of the summary.\n' | pl lint /dev/stdin
/dev/stdin: nothing found
14 tokens
```

Those two lines disagree exactly as lines 4 and 16 do, and the linter finds nothing, because
*one line* and *leave nothing out* are on none of its lists.

And some of what it reports is not what the finding's name says. Look again at the shouting finding: lines 11 and
14 open with `IMPORTANT:`, and line 13 opens with *Never*, an ordinary capitalised word at the
start of a sentence. The pattern ignores case, so it counted line 13 as shouting. **A finding is
a line to look at, not a verdict on it.**

So `nothing found` means that no pattern matched, which is weaker than saying the prompt is
clear. The linter is worth running because the mistakes it does catch are the ones that creep in
unnoticed: a rule pasted a second time, a capitalised word added in a hurry, a new line that
quietly reverses an old one. Lesson 5 runs it over a prompt with thirteen rules and finds four
problems.

::: track ai
You wrote Python in `python`, so read `cmd_lint` in `promptlab/cli.py`. It is about forty lines,
and seeing the word lists is the quickest way to stop trusting `nothing found` more than it
deserves.
:::

::: track *
The linter's patterns are in `promptlab/cli.py`, under `cmd_lint`. You do not need to read them,
but knowing they are word lists is enough to read its output sceptically.
:::
