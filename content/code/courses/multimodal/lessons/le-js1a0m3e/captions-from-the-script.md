---
title: When the script exists, the words come from it
version: 1
---

Recognition is the right tool for a recording nobody wrote down: a call, an interview, a meeting. The returns video is not one. Somebody wrote its narration before a voice spoke it, and `media/truth/returns.json` keeps that script. **When the script exists, the recognised words are a worse copy of it**, and the useful part of recognition is only its timings.

```python
"""Timings from recognition, words from the script: each segment takes the script line it is closest to."""
import json

import jiwer
from cues import stamp

said = [s["said"] for s in json.load(open("media/truth/returns.json"))["slides"] if s["said"]]
heard = json.load(open("recognised.json"))

print("recognised against the script: WER %.1f%%" % (100 * jiwer.wer(" ".join(said).lower(), " ".join(t for _, _, t in heard).lower())))
for start, end, text in heard:
    line = min(said, key=lambda s: jiwer.cer(s.lower(), text.lower()))
    print("%s  cer %4.1f%%  %s" % (stamp(start)[3:], 100 * jiwer.cer(line.lower(), text.lower()), line[:52]))
```

```
ana@lab:~/mm$ python script_captions.py
recognised against the script: WER 13.7%
00:00.420  cer  2.0%  Here is how to return a book you bought from Margina
00:06.340  cer  4.2%  First, sign in and open the order the book came in. 
00:12.040  cer  0.0%  Second, press Return this item and choose a reason f
00:16.100  cer  4.6%  Third, print the prepaid label we send you by e-mail
00:21.830  cer  9.9%  Fourth, drop the parcel at any post office, and keep
00:26.890  cer  7.2%  Refunds go back to the card you paid with. A damaged
```

The recognised text is 13.7% wrong against the script. Matched segment by segment, each one finds its script line at a character error rate of 0% to 9.9%, so the match is unambiguous, and the captions take **the script's words with the recogniser's times**. "Marginalia", "sign in" and "Fourth," come back; the reading rate stays as high, because the words were never the reason for it.

This is how this platform treats its own videos. `docs/VIDEO.md` makes the spoken script authored source, kept in `content/` beside the prose, and the transcript a student reads back **is** that script. In its words, "calling the script a transcript is a claim about the video", and if a rendition drifts from it, the script is what gets corrected. A course written that way has its caption text before its video exists. What it still needs is the timing, which is the half a recogniser does well.
