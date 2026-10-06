---
title: The format the audio travels in
version: 1
---

A voice produces numbers; what reaches the listener is a file or a stream in some format, and the format decides its size and where it can play. labmm's speech route, which runs the same Piper voice behind OpenAI's API shape, offers the formats OpenAI's does. The same sentence in each:

```python
"""One sentence from labmm's speech route in every format it offers, and what each one weighs."""
from openai import OpenAI

client = OpenAI()
TEXT = "Your order has shipped. It should arrive on Thursday."
for fmt in ("wav", "flac", "mp3", "aac", "opus"):
    audio = client.audio.speech.create(model="lab-tts-1", voice="lessac", input=TEXT, response_format=fmt)
    print(f"{fmt:5} {len(audio.content):7,} bytes")
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
