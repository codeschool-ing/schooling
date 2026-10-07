---
title: The prompt field, and why it does nothing here
version: 1
---

Whisper decodes a recording one token at a time, and each token is predicted from the sound **and from the text before it**. The API's `prompt` field lets you supply that earlier text yourself. The model treats it as if it had just been said, so its words and spellings become more likely in what follows.

It is the hosted fix for lesson 7's problem: give the prompt the shop's name, the agent's name, the order number format and the title, and the model is far more likely to write *Marginalia*, *Caio* and *Dom Casmurro*. OpenAI's documentation describes three uses: spelling unusual words, keeping the style of the previous piece of a long recording (its last words, passed on as the next piece's prompt), and setting punctuation and capitalisation by example. For `whisper-1` it says only the final 224 tokens of the prompt are considered.

```python
"""The prompt parameter: text the model is told came before the audio."""
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open("media/call-1042.wav", "rb") as audio:
    result = client.audio.transcriptions.create(
        model="whisper-base", file=audio, language="en",
        prompt="Marginalia support. Caio. Order M-1042: Dom Casmurro, by Machado de Assis.")
print(result.text[:150])
```

```
ana@lab:~/mm$ python hint.py
Good morning, you're through to Marginalia Support. My name is Kyo. How can it help Hi Kau, I'm calling about Order M1042. It's a copy of Dom Kazmuro 
ana@lab:~/mm$ tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print(r[\"prompt\"])"
Marginalia support. Caio. Order M-1042: Dom Casmurro, by Machado de Assis.
```

**The transcript is unchanged**: still *Kyo*, *Kau* and *Dom Kazmuro*, with the right names sitting in the prompt. That is not evidence about the prompt. **The course's server accepts the field, logs it, and does not pass it to the model**, because the ONNX export of Whisper the course runs has no way to take one; the second command shows it arrived. On the real endpoint this is where lesson 7's errors would be attacked first, and lesson 7's lexicon is the fallback that works whether or not a prompt is possible.

Two cautions from the same documentation, worth knowing before relying on it:

- **A prompt is a hint, not a constraint.** The model can still write something else, so the lexicon check after the transcript stays.
- **A prompt can push in the wrong direction.** A prompt in English nudges the model towards English, and a long list of unrelated names can make the model write them where they were not said. Keep it short and true to the recording.
