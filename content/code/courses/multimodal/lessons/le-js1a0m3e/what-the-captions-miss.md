---
title: What perfect captions still miss
version: 1
---

Captions carry what is **said**. A viewer who cannot see the screen gets the narration and nothing else, so the next question is what the screen shows that the narration never says. Lesson 4 read the slides with Tesseract; this program does it for a frame in the middle of each slide and keeps every line of which half or more of the words are never spoken:

```python
"""What the video SHOWS that its narration never SAYS: OCR a frame from the middle of each slide."""
import json
import re
import subprocess

slides = json.load(open("media/truth/returns.json"))["slides"]
spoken = set(re.findall(r"[a-z0-9]+", " ".join(s["said"] for s in slides).lower()))

for s in slides:
    mid = (s["start"] + s["end"]) / 2
    png = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-ss", f"{mid:.2f}", "-i", "media/returns.mp4",
                          "-frames:v", "1", "-f", "image2pipe", "-vcodec", "png", "-"], capture_output=True).stdout
    text = subprocess.run(["tesseract", "-", "-"], input=png, capture_output=True).stdout.decode()
    for line in filter(None, (l.strip() for l in text.splitlines())):
        words = re.findall(r"[a-z0-9]+", line.lower())
        unsaid = [w for w in words if w not in spoken]
        if len(unsaid) * 2 >= len(words):              # half or more of the line is never said
            print("%5.2f-%5.2f  %-38s never said: %s" % (s["start"], s["end"], line, " ".join(unsaid)))
```

```
ana@lab:~/mm$ python missing.py
 5.92-11.64  Account > Orders > M-1042              never said: m 1042
11.64-15.68  () Wrong book sent                     never said: wrong sent
11.64-15.68  () Changed my mind                     never said: changed my mind
20.72-21.12  Code: RETURN3O                         never said: code return3o
20.72-21.12  Quote it if you call us                never said: quote if call us
21.12-26.44  4. Drop it off                         never said: 4 off
26.44-32.60  Within 30 days of delivery             never said: within 30 days of delivery
26.44-32.60  The label is valid for 7 days          never said: valid for 7 days
```

The video was made with these gaps on purpose, and the program found them, with two lines more that matter less. **Three matter to someone returning a book.** The reasons on slide 3, which the narration calls "a reason from the list" without reading the list. The 0.4-second card between slides 4 and 5, `Code: RETURN30` and "Quote it if you call us", which nobody says at all (Tesseract reads the code as `RETURN3O`, as in lesson 4). And on the last slide, **the label is valid for 7 days**, a deadline a listener would only learn by missing it.

The rest are noise to a describer: the order number on slide 2 is an example, and "4. Drop it off" says what "Fourth, drop the parcel" already said. That judgement, which shown text matters, is the part of audio description that is about meaning, and the program cannot make it. It can make the list short enough for a person to decide in a minute.
