---
title: Finding them before the model does
version: 2
---

You found the contradiction in `v2-long.txt` by reading, because the prompt is short and the two
lines use obvious words. A prompt of sixty lines, edited by four people over a year, is read by
nobody end to end. **A linter reads every line every time**, and it is cheap enough to run before
each change. This one is a few lists of words and patterns. Save it as `lint.py`:

```python
"""lint: lines of a prompt worth a second look. It reads words, not meaning."""
import re
import sys

# Pairs of patterns that pull one decision in opposite directions.
OPPOSITES = [
    (r"\b(brief|concise|short|one sentence)\b", r"\b(in (full )?detail|thorough|everything)\b", "length"),
    (r"\bformal\b", r"\b(casual|friendly|chatty)\b", "tone"),
]
SHOUT = r"\b(IMPORTANT|MUST|NEVER|ALWAYS|CRITICAL)\b"
NEGATIVE = r"^\s*[-*]?\s*(do not|don't|never|avoid)\b"


def lint(path):
    lines = open(path, encoding="utf-8").read().splitlines()
    found = []

    def where(pattern):
        return [n for n, line in enumerate(lines, 1) if re.search(pattern, line, re.I)]

    for one, other, what in OPPOSITES:
        x, y = where(one), where(other)
        if x and y:
            found.append((min(x + y), "contradiction (%s): lines %s against lines %s"
                          % (what, ",".join(map(str, x)), ",".join(map(str, y)))))
    seen = {}
    for n, line in enumerate(lines, 1):
        words = re.sub(r"\W+", " ", line.lower()).strip()
        if len(words.split()) >= 4:
            if words in seen:
                found.append((n, "repeats line %d" % seen[words]))
            seen.setdefault(words, n)
    negative = where(NEGATIVE)
    if len(negative) >= 3:
        found.append((negative[0], "%d rules say only what not to do: lines %s"
                      % (len(negative), ",".join(map(str, negative)))))
    rules = [n for n in where(r"^\s*([-*]|\d+\.)\s") if not re.search(r'^\s*-\s*"\w+":', lines[n - 1])]
    if len(rules) > 8:
        found.append((rules[0], "%d separate rules; a reader keeps fewer" % len(rules)))
    shouting = where(SHOUT)
    if len(shouting) >= 2:
        found.append((shouting[0], "%d lines shout: %s" % (len(shouting), ",".join(map(str, shouting)))))
    for n, text in sorted(found):
        print("%s:%d: %s" % (path, n, text))
    if not found:
        print("%s: nothing found" % path)


for path in sys.argv[1:]:
    lint(path)
```

```
ana@lab:~/triage$ python3 lint.py prompts/v2-long.txt prompts/v2-json.txt
prompts/v2-long.txt:4: contradiction (length): lines 4 against lines 16
prompts/v2-long.txt:11: 3 lines shout: 11,13,14
prompts/v2-long.txt:14: repeats line 11
prompts/v2-json.txt: nothing found
```

Three findings for the long prompt and none for the short one. Each finding names a line, so it
can be fixed where it is:

| finding | what it means |
|---|---|
| `contradiction (length)` | a line asking for brevity and a line asking for detail, in one prompt |
| `3 lines shout` | lines with words like IMPORTANT or NEVER, which raise some rules above the rest |
| `repeats line 11` | the same instruction twice, word for word |

## What the linter is reading

`lint.py` knows that *brief*, *concise*, *short* and *one sentence* pull one way and *in detail*,
*thorough* and *everything* pull the other, and it reports a prompt that contains both. **It does
not understand either instruction.** Two consequences follow, and both show up here.

It misses a contradiction written in other words:

```
ana@lab:~/triage$ printf 'Keep the summary to one line.\nLeave nothing out of the summary.\n' > /tmp/two-lines.txt
ana@lab:~/triage$ python3 lint.py /tmp/two-lines.txt
/tmp/two-lines.txt: nothing found
```

Those two lines disagree exactly as lines 4 and 16 do, and the linter finds nothing, because *one
line* and *leave nothing out* are on none of its lists.

And some of what it reports is not what the finding's name says. Lines 11 and 14 open with
`IMPORTANT:`, and line 13 opens with *Never*, an ordinary capitalised word at the start of a
sentence. `where()` searches with `re.I`, which ignores case, so it counted line 13 as shouting.
**A finding is a line to look at, not a verdict on it.**

So `nothing found` means that no pattern matched, which is weaker than saying the prompt is clear.
The linter is worth running because the mistakes it does catch are the ones that creep in
unnoticed: a rule pasted a second time, a capitalised word added in a hurry, a new line that
quietly reverses an old one. Lesson 5 runs it over a prompt with thirteen rules.
