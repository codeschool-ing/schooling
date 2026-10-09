---
title: Audio is billed by the second and limited by the byte
version: 2
---

A transcription is billed by its seconds, so the encoding cannot change the price. It can change two other things: whether the file fits under the upload limit, and what the model hears. This program encodes the call four ways, sends each to Whisper base through lesson 10's `audio_server.py` (start it first, in a second terminal), and scores what came back against the call's script:

```python
"""One call in four encodings: the bytes, how many minutes fit under 25 MB, and what Whisper heard."""
import os
import subprocess

import jiwer
from openai import OpenAI

LIMIT = 25 * 1024 * 1024
truth = open("media/truth/call-1042.txt").read()
norm = jiwer.Compose([jiwer.ToLowerCase(), jiwer.RemovePunctuation(), jiwer.RemoveMultipleSpaces(),
                      jiwer.Strip(), jiwer.ReduceToListOfListOfWords()])
seconds = 55.38

print("%-24s %9s %10s %6s" % ("encoding", "bytes", "min/25MB", "WER"))
for name, args, ext in (("wav 16 kHz 16-bit", ["-ar", "16000", "-ac", "1"], "wav"),
                        ("mp3 64 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "64k"], "mp3"),
                        ("mp3 32 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "32k"], "mp3"),
                        ("opus 16 kbit/s", ["-ar", "16000", "-ac", "1", "-b:a", "16k"], "ogg")):
    out = f"call.{name.split()[0]}{name.split()[1]}.{ext}"
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", "media/call-1042.wav", *args, out], check=True)
    size = os.path.getsize(out)
    with open(out, "rb") as f:
        heard = OpenAI(base_url="http://localhost:8700/v1").audio.transcriptions.create(
            model="whisper-base", file=f, response_format="text")
    wer = jiwer.wer(truth, heard, reference_transform=norm, hypothesis_transform=norm)
    print("%-24s %9d %10.0f %5.1f%%" % (name, size, LIMIT / size * seconds / 60, 100 * wer))
```

```
ana@lab:~/mm$ python audio_sizes.py
encoding                     bytes   min/25MB    WER
wav 16 kHz 16-bit          1772350         14  12.6%
mp3 64 kbit/s               444141         54  14.6%
mp3 32 kbit/s               222129        109  13.9%
opus 16 kbit/s              120226        201  14.6%
```

The bytes fall nearly fifteenfold from the WAV to the Opus file, and so the **minutes that fit under OpenAI's 25 MB** rise from 14 to 201. The WAV is the format lesson 10 hit the limit with; a 32 kbit/s MP3 holds an hour and three-quarters in one request, which covers most calls without cutting them into pieces at all.

The error rate moved from 12.6% to between 13.9% and 14.6%. On one call of 151 words, that is three or four words, the same size of difference lesson 11 declined to call a finding. What it does say is that **compression did not break the transcript**, and a shop that wants to know whether 16 kbit/s costs it accuracy runs the comparison on lesson 7's test set, not on one call.

Video is the same story told in frames. Lesson 4 sent a few frames rather than the file, and the cost was the frames' tokens; how many frames per second a provider samples, and at what size, is its rule and changes the bill in the same way the tile rule does.
