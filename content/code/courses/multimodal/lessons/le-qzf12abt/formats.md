---
title: The format the audio travels in
version: 1
---

A voice produces numbers; what reaches the listener is a file or a stream in some format, and the format decides its size and where it can play. OpenAI's speech endpoint offers five, named by its `response_format` field, and other providers offer much the same list. ffmpeg can make every one of them from the same Piper voice, at the bit rates a speech service uses:

`formats.py`:

```python
"""One sentence from a Piper voice, in the five formats speech APIs offer, and what each one weighs."""
import subprocess

import numpy as np

import mmlab

FORMATS = {"wav": ("wav", ["-c:a", "pcm_s16le"]),
           "flac": ("flac", ["-c:a", "flac"]),
           "mp3": ("mp3", ["-c:a", "libmp3lame", "-b:a", "64k"]),
           "aac": ("adts", ["-c:a", "aac", "-b:a", "64k"]),
           "opus": ("ogg", ["-c:a", "libopus", "-b:a", "32k"])}

audio = mmlab.piper("en_US-lessac-medium").generate("Your order has shipped. It should arrive on Thursday.", sid=0, speed=1.0)
pcm = (np.clip(np.asarray(audio.samples), -1, 1) * 32767).astype("<i2").tobytes()   # 16-bit samples, as a file holds them
for name, (container, codec) in FORMATS.items():
    out = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-f", "s16le", "-ar", str(audio.sample_rate),
                          "-ac", "1", "-i", "-", *codec, "-map_metadata", "-1", "-fflags", "+bitexact",
                          "-f", container, "-"], input=pcm, capture_output=True, check=True).stdout
    print(f"{name:5} {len(out):7,} bytes")
```

```
ana@lab:~/mm$ python formats.py
wav   121,900 bytes
flac   66,655 bytes
mp3    22,589 bytes
aac    23,368 bytes
opus   10,974 bytes
```

| format | what it is | size here | use it for |
|---|---|---|---|
| WAV | the raw samples, uncompressed | 121,900 bytes | further processing; never for delivery |
| FLAC | the same samples, compressed without loss | 66,655 bytes | keeping a master copy |
| MP3 | lossy, at 64 kbit/s here | 22,589 bytes | anything that must play everywhere |
| AAC | lossy, at 64 kbit/s here | 23,368 bytes | Apple devices, video files |
| Opus | lossy, built for speech, at 32 kbit/s here | 10,974 bytes | the web, phone systems, voice chat |

**Opus is a tenth the size of WAV** and is the format designed for speech over networks: every current browser plays it, and it was made to work at the low bit rates calls use. For a phone line the audio is converted once more at the telephone network's edge, to 8,000 samples a second, which is what lesson 5's phone recording sounded like.

The sizes matter twice: once for every reply sent to a caller, and once in the bill, since some providers charge for synthesised speech per character of input and others per second of audio produced. Lesson 13 does that arithmetic with real prices.
