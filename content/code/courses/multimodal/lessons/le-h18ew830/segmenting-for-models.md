---
title: Cutting long audio for a model
version: 1
---

Every speech model has a longest piece it will take at once. Whisper's is **30 seconds**: the model was trained on 30-second windows, and anything longer has to be cut into pieces and the pieces transcribed in turn. Hosted APIs add their own limits on top, by file size rather than length (lesson 10 meets the 25 MB one).

**Where you cut decides what goes wrong.** Cut at a fixed 30 seconds and the cut lands in the middle of a word about as often as not; the word is split between two pieces, transcribed badly in both or lost entirely. Lesson 4 already saw the gentler version of this, where a segment that began a moment late dropped the word *Fourth*. The rule is to **cut only in silence**, and the speech detector says where the silences are:

```python
"""Cut a recording into pieces of at most 30 seconds, and only at a silence."""
import sys

import mmlab

LIMIT = 30.0
samples = mmlab.read_audio(sys.argv[1])
chunks, start, last_end = [], 0.0, 0.0
for s, e in mmlab.speech_segments(samples):
    if e - start > LIMIT and last_end > start:
        cut = (last_end + s) / 2          # the middle of the silence before this stretch
        chunks.append((start, cut))
        start = cut
    last_end = e
chunks.append((start, len(samples) / mmlab.RATE))
for a, b in chunks:
    print(f"{a:6.2f} -> {b:6.2f}  ({b - a:4.1f} s)")
```

```
ana@lab:~/mm$ python chunks.py media/call-1042.wav
  0.00 ->  29.57  (29.6 s)
 29.57 ->  55.38  (25.8 s)
```

Two pieces: 29.6 seconds and 25.8 seconds, cut in the middle of the gap before the stretch that would have pushed the first piece past 30 seconds. Nobody was speaking at 29.57; the truth file has Bia's turn ending at 29.375 and Caio's next one starting at 29.975.

Three refinements matter for long recordings, and each one trades something.

**Overlap.** Some pipelines give each piece a second or two of the previous one, so that a word near the cut is heard whole in at least one piece, and then remove the duplicated words when joining. It costs a little extra transcription and some care at the join.

**Context across pieces.** Whisper can be given the text of the previous piece as a *prompt*, which helps it keep names and spelling consistent across cuts. The ONNX export this lab runs has no way to take one, so it is not demonstrated here; lesson 10 shows where the API takes it.

**Pieces shorter than the limit.** Silero's own stretches, a sentence or two each, are already well under 30 seconds, and transcribing each one alone is what lesson 4 did. Smaller pieces give finer timestamps and lose context; the 30-second pieces here keep more context and give coarser times. Captions want the first; a summary wants the second.

The three models of this lesson (find speech, separate speakers, cut into pieces) are usually run in that order, and then the transcriber of lessons 7 and 10 takes over.
