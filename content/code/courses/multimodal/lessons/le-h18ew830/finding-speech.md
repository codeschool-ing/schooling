---
title: Finding where people are speaking
version: 1
---

**Voice activity detection (VAD)** answers the simplest question about a recording: speech or not speech, moment by moment. Every other step in this course leans on it. It decides where to cut audio before transcribing (lesson 4), where a caption starts and ends (lesson 14), and how much of a long recording you pay to transcribe (lesson 13). Silero VAD is a model of 632 kilobytes that reads the audio in windows of 32 milliseconds and says, for each one, how likely it is to be speech.

Against the script's truth, on the clean call:

```python
"""Where Silero hears speech, against where the script says somebody was speaking."""
import json
import sys

import mmlab

path, silence = sys.argv[1], float(sys.argv[2])
turns = json.load(open("media/truth/call-1042.json"))["turns"]
found = mmlab.speech_segments(mmlab.read_audio(path), min_silence=silence)
print(f"{path}, silences under {silence} s ignored: {len(found)} stretches for {len(turns)} turns")
for start, end in found:
    inside = [t["who"] for t in turns if t["start"] < end and t["end"] > start]
    print(f"  {start:6.2f} {end:6.2f}  {'+'.join(inside)}")
```

```
ana@lab:~/mm$ python vad.py media/call-1042.wav 0.25
media/call-1042.wav, silences under 0.25 s ignored: 11 stretches for 9 turns
    0.26   4.36  caio
    4.58   5.32  caio
    6.05  14.31  bia
   15.01  16.39  caio
   16.61  23.88  caio
   25.00  29.16  bia
   29.99  38.21  caio
   39.69  41.32  bia
   41.89  49.57  caio
   50.34  51.46  bia
   52.17  55.36  caio
ana@lab:~/mm$ python vad.py media/call-1042.wav 1.0 | head -4
media/call-1042.wav, silences under 1.0 s ignored: 4 stretches for 9 turns
    0.26  20.48  caio+bia+caio
   20.58  23.90  caio
   25.00  47.26  bia+caio+bia+caio
ana@lab:~/mm$ python vad.py media/call-1042-noisy.wav 0.25
media/call-1042-noisy.wav, silences under 0.25 s ignored: 5 stretches for 9 turns
    0.33  14.63  caio+bia
   15.01  35.90  caio+bia+caio
   36.20  38.89  caio
   39.17  50.09  bia+caio
   50.37  55.36  bia+caio
ana@lab:~/mm$ python vad.py call-gtcrn.wav 0.25 | head -1
call-gtcrn.wav, silences under 0.25 s ignored: 13 stretches for 9 turns
```

On the clean call Silero found **11 stretches for 9 turns**, and every boundary sits within about a quarter of a second of the truth. Two of Caio's turns came out as two stretches each: he pauses mid-sentence (*Good morning, you're through to Marginalia support. My name is Caio.*), and the pause was longer than the 0.25 seconds `mmlab.speech_segments` ignores by default.

**The one setting that matters most is how long a silence has to be to count.** At 1.0 second, the second command merges whole exchanges: the first stretch runs from 0.26 to 20.48 seconds and holds three turns, Caio, Bia and Caio again, because none of the gaps between them reached a second. Short silences give pieces that follow sentences; long ones give pieces that follow topics. Which you want depends on what comes next: captions want short pieces, a summariser is happy with long ones.

**Noise breaks it in the other direction.** On the noisy call the detector found 5 stretches, each running across two or three turns: the gaps of half a second between speakers were filled with hiss, and the hiss looked enough like speech. After GTCRN it found 13. That is the strongest argument for a denoiser in this lesson, and it is not about the words at all.
