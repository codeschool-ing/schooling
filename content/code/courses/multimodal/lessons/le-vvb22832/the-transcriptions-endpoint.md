---
title: The transcriptions endpoint
version: 1
---

OpenAI's speech-to-text API is one call: **upload a file, name a model, get text back**. The file goes as a multipart form upload, not as JSON, and the SDK hides that:

```python
"""Send a recording to the transcriptions endpoint and print what comes back."""
import sys

from openai import OpenAI

path = sys.argv[1]
fmt = sys.argv[2] if len(sys.argv) > 2 else "json"
client = OpenAI()
with open(path, "rb") as audio:
    result = client.audio.transcriptions.create(model="lab-whisper-base", file=audio, response_format=fmt)
print(result.text if fmt == "json" else result)
```

```
ana@lab:~/mm$ python transcribe.py media/call-1042.wav | cut -c1-160
Good morning, you're through to Marginalia Support. My name is Kyo. How can it help Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro by Machado
ana@lab:~/mm$ tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print({k: r[k] for k in (\"model\", \"file\", \"bytes\", \"duration\", \"segments\", \"seconds\")})"
{'model': 'lab-whisper-base', 'file': 'call-1042.wav', 'bytes': 1772316, 'duration': 55.38, 'segments': 11, 'seconds': 12.96}
```

**This transcript is real, and it is not OpenAI's.** labmm answers the route with `lab-whisper-base`, which is Whisper base running on the lab's machine, after cutting the recording at its silences: the same model and the same errors as lesson 7 (*Kyo*, *Kau*, *M1042*, *Dom Kazmuro*). OpenAI's `whisper-1` is a larger Whisper and would make fewer and different mistakes. What is the same is the call: the SDK, the upload and the fields.

labmm's log says what it received: the file name, **1,772,316 bytes**, 55.38 seconds of audio, cut into 11 segments, and how long the whole thing took on this machine. A hosted API reports less, and a production program should log the same things itself: file, size, duration and model are what explain a bill and a slow request a month later.

The fields worth setting:

| field | what it does |
|---|---|
| `model` | `whisper-1`, `gpt-4o-transcribe`, `gpt-4o-mini-transcribe` at OpenAI; `lab-whisper-base` or `lab-whisper-tiny` here |
| `file` | the recording, in one of the accepted formats (section 06) |
| `language` | an ISO 639-1 code such as `en` or `pt`; lesson 7 showed why to set it when you know it |
| `response_format` | the shape of the answer (section 03) |
| `prompt` | text the model treats as what came before the audio (section 05) |
| `temperature` | 0 for the most likely words; higher values let the decoder take less likely ones |
