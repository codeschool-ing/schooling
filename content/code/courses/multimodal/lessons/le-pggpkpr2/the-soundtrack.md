---
title: Listening to the soundtrack
version: 1
---

The second stream is the narration, and it carries what the slides do not say: the reasons behind each step, and the details the narrator adds in passing. `mmlab.read_audio` asks ffmpeg for the audio stream of any file, so the same function that reads a WAV reads the soundtrack of an MP4, resampled to the 16,000 samples a second that Whisper expects.

```python
"""The video's soundtrack, cut at its silences and transcribed piece by piece."""
import json
import sys

import mmlab

samples = mmlab.read_audio(sys.argv[1])
whisper = mmlab.whisper("base", language="en")
said = []
for start, end in mmlab.speech_segments(samples):
    text, _ = mmlab.transcribe(whisper, samples[int(start * mmlab.RATE):int(end * mmlab.RATE)])
    said.append({"start": round(start, 2), "end": round(end, 2), "text": text})
    print(f"{start:6.2f} {end:6.2f}  {text}")
json.dump(said, open("said.json", "w"), indent=1)
```

```
ana@lab:~/mm$ python soundtrack.py media/returns.mp4
  0.42   5.19  Here is how to return a book you bought from Marginelia. It takes four steps and the label is free.
  6.34  10.89  First, sign and end open the order the book came in. You will find it under account then orders.
 12.04  14.98  Second, press return this item and choose a reason from the list.
 16.10  20.01  Third, print the prepared label we send you by email and tape it over the old address.
 21.83  25.70  Drop the parcel at any post office and keep the receipt until your refund arrives.
 26.89  31.91  Refunds go back to the card you paid with, a damage to book as refunded and full, shipping included.
```

Two models ran here. **Silero VAD** (voice activity detection) found six stretches of speech and the silences between them; lesson 5 looks at it closely. **Whisper base** then transcribed each stretch on its own, which gives every piece of text a start and an end on the video's clock.

Read the transcript against the script the narrator spoke (it is in `media/truth/returns.json`) and the errors are of three kinds:

- **Words heard as other words.** *Marginelia* for Marginalia, *sign and end* for *sign in*, *prepared label* for *prepaid label*, *a damage to book as refunded and full* for *a damaged book is refunded in full*. Each is a plausible English phrase, and the last one changes the meaning.
- **A word lost at the edge.** The fourth step starts with *Fourth,* and the transcript does not: the speech detector judged the stretch to begin at 21.83 seconds, a moment after the word did. A word clipped at the boundary of a segment is a characteristic error of cutting audio before transcribing it.
- **Nothing for what was not said.** From 20.72 to 21.12 there is no speech at all, so the transcript has nothing for the card. That is not an error of Whisper's. It is the reason a video cannot be understood from its soundtrack alone.

Lesson 7 measures Whisper's errors properly, with a word error rate, and lesson 14 turns transcripts like this one into captions, where every one of these errors would be on screen.
