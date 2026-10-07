---
title: Five shapes for one transcript
version: 2
---

The same audio can come back in five shapes, and choosing the right one saves writing a converter.

**`text`**: just the words. Here, the Portuguese voicemail, with the language left to the model:

```
ana@lab:~/mm$ python transcribe.py media/voicemail-pt.wav text
Oi, aqui é o Rafael Piente da Maginalia, sou ligando sobre o pedido em 2002-1987, um exemplar de memórias postmas de brassculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.
```

**`verbose_json`**: the words, the detected language, the length, and the **segments**, each with a start and an end in seconds:

```python
"""verbose_json: the text, the language, the length, and every segment with its times."""
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(model="whisper-base", file=audio,
                                                response_format="verbose_json")
print(f"language {result.language}, {result.duration} s, {len(result.segments)} segments")
for s in result.segments[:4]:
    print(f"  {s.start:6.2f} {s.end:6.2f}  {s.text}")
```

```
ana@lab:~/mm$ python verbose.py
language english, 55.38 s, 11 segments
    0.26   4.36  Good morning, you're through to Marginalia Support. My name is Kyo.
    4.58   5.32  How can it help
    6.05  14.31  Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro by Machado Desiss and it arrived on 24 September.
   15.01  16.39  Let me pull that up.
```

**`srt`** and **`vtt`**: the same segments as caption files, ready to load beside a video:

```
ana@lab:~/mm$ python transcribe.py media/call-1042.wav srt | head -8
1
00:00:00,260 --> 00:00:04,360
Good morning, you're through to Marginalia Support. My name is Kyo.

2
00:00:04,580 --> 00:00:05,320
How can it help
```

```
ana@lab:~/mm$ python transcribe.py media/call-1042.wav vtt | head -8
WEBVTT

00:00:00.260 --> 00:00:04.360
Good morning, you're through to Marginalia Support. My name is Kyo.

00:00:04.580 --> 00:00:05.320
How can it help
```

The two caption formats carry the same information and differ in punctuation that matters to the software reading them. **SRT** numbers each cue and writes milliseconds after a comma (`00:00:04,360`). **WebVTT** starts with the line `WEBVTT`, writes milliseconds after a full stop (`00:00:04.360`), needs no numbers, and is the format web browsers read in a `<track>` element. Lesson 14 builds captions from these, and finds the problems they still have: a segment of eight seconds is too long to read as one caption, and a cue of three words (*How can it help*) cut off from its sentence is hard to follow.

| shape | use it for |
|---|---|
| `json` (the default) | the text, in a program |
| `text` | the text, in a shell script or a file |
| `verbose_json` | anything that needs times or the detected language |
| `srt`, `vtt` | captions; `vtt` for the web |

OpenAI's documentation does not list `srt`, `vtt` or `verbose_json` for the newer `gpt-4o-transcribe` models, which is worth checking before switching a captioning pipeline to them.
