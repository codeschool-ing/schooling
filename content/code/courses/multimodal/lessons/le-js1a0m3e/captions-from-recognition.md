---
title: Captions from recognition, held to three rules
version: 1
---

Lesson 4's returns video has a narration, and lesson 10 showed Whisper returning `vtt` directly. A caption file is more than a transcript with times, though: a viewer has to read each cue before it goes. Subtitle style guides agree on the shape of the rules, and these numbers are the ones Netflix's English guide uses for adult programmes: at most **42 characters per line**, at most **2 lines** per cue, and at most **20 characters per second** of reading.

```python
"""The three rules every caption cue is held to, and the two helpers both caption programs share."""
LINE, LINES, CPS = 42, 2, 20       # characters per line, lines per cue, characters per second


def stamp(t):
    return "%02d:%02d:%06.3f" % (t // 3600, t % 3600 // 60, t % 60)


def wrap(text):
    """Greedy wrap at LINE characters."""
    lines, cur = [], ""
    for word in text.split():
        if cur and len(cur) + 1 + len(word) > LINE:
            lines.append(cur)
            cur = word
        else:
            cur = (cur + " " + word).strip()
    return lines + [cur]
```

```python
"""Captions for the returns video, straight from recognition, then checked against the cue rules."""
import json

from cues import CPS, LINES, stamp, wrap
from openai import OpenAI

with open("media/returns.mp4", "rb") as f:
    r = OpenAI().audio.transcriptions.create(model="lab-whisper-base", file=f, response_format="verbose_json")
cues = [(s.start, s.end, s.text.strip()) for s in r.segments]
json.dump(cues, open("recognised.json", "w"))

with open("returns.vtt", "w") as out:
    out.write("WEBVTT\n")
    for start, end, text in cues:
        out.write(f"\n{stamp(start)} --> {stamp(end)}\n" + "\n".join(wrap(text)) + "\n")

for start, end, text in cues:
    lines, cps = wrap(text), len(text) / (end - start)
    faults = [f"{len(lines)} lines"] * (len(lines) > LINES) + [f"{cps:.1f} chars/s"] * (cps > CPS)
    print("%5.2f %5.2f  %-28s %s" % (start, end, ", ".join(faults) or "ok", text[:34]))
```

```
ana@lab:~/mm$ python captions.py
 0.42  5.19  3 lines, 20.8 chars/s        Here is how to return a book you b
 6.34 10.89  3 lines, 21.1 chars/s        First, sign and end open the order
12.04 14.98  22.1 chars/s                 Second, press return this item and
16.10 20.01  3 lines, 22.0 chars/s        Third, print the prepared label we
21.83 25.70  3 lines, 21.2 chars/s        Drop the parcel at any post office
26.89 31.91  3 lines                      Refunds go back to the card you pa
ana@lab:~/mm$ head -n 8 returns.vtt
WEBVTT

00:00:00.420 --> 00:00:05.190
Here is how to return a book you bought
from Marginelia. It takes four steps and
the label is free.

00:00:06.340 --> 00:00:10.890
```

**Every cue broke a rule.** Whisper's segments follow the speaker's sentences, so most of them wrap to three lines, and the narration runs at 20 to 22 characters a second, faster than the reading rate. The words have lesson 7's kind of error, too: "sign and end" for "sign in", "Marginelia", "a damage to book as refunded and full".

The lines are the easy half. This program cuts each segment into cues of two lines at most and shares the segment's time out by characters:

```python
"""Cut each recognised segment into cues that obey the rules, sharing its time out by characters."""
import json

from cues import CPS, LINE, LINES, stamp, wrap

cues = []
for start, end, text in json.load(open("recognised.json")):
    lines = wrap(text)
    groups = [lines[i:i + LINES] for i in range(0, len(lines), LINES)]
    if len(groups) > 1 and len(groups[-1]) == 1:          # never leave one short line alone at the end
        words = text.split()
        half = len(words) // 2
        groups = [wrap(" ".join(words[:half])), wrap(" ".join(words[half:]))]
    total, t = sum(len(" ".join(g)) for g in groups), start
    for g in groups:
        span = (end - start) * len(" ".join(g)) / total
        cues.append((t, t + span, g))
        t += span

for a, b, g in cues:
    cps = len(" ".join(g)) / (b - a)
    print("%s --> %s  %4.1f/s  %s" % (stamp(a)[3:], stamp(b)[3:], cps, " / ".join(g)))
print(len(cues), "cues,", sum(len(" ".join(g)) / (b - a) > CPS for a, b, g in cues), "over", CPS, "chars/s,",
      sum(any(len(x) > LINE for x in g) for a, b, g in cues), "lines over", LINE)
```

```
ana@lab:~/mm$ python recut.py
00:00.420 --> 00:02.562  20.5/s  Here is how to return a book you bought / from
00:02.562 --> 00:05.190  20.5/s  Marginelia. It takes four steps and the / label is free.
00:06.340 --> 00:08.399  20.9/s  First, sign and end open the order the / book
00:08.399 --> 00:10.890  20.9/s  came in. You will find it under account / then orders.
00:12.040 --> 00:14.980  22.1/s  Second, press return this item and choose / a reason from the list.
00:16.100 --> 00:18.078  21.7/s  Third, print the prepared label we send / you
00:18.078 --> 00:20.010  21.7/s  by email and tape it over the old address.
00:21.830 --> 00:23.454  20.9/s  Drop the parcel at any post office
00:23.454 --> 00:25.700  20.9/s  and keep the receipt until your refund / arrives.
00:26.890 --> 00:29.020  19.7/s  Refunds go back to the card you paid with,
00:29.020 --> 00:31.910  19.7/s  a damage to book as refunded and full, / shipping included.
11 cues, 9 over 20 chars/s, 0 lines over 42
```

**No line is over 42 now, and 9 of the 11 cues are still over 20 characters a second.** Cutting a cue in two halves its text and its time together, so the rate does not move. Only two things move it: fewer words, which is what an **edited** caption does against a **verbatim** one, or more time, by letting a cue stay on screen into the pause after it. Both are decisions about the text, and both are the captioner's. The breaks are not a person's either: "the / book" leaves one word alone on a line, which a reader stumbles on.
