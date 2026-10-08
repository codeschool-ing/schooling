---
title: The translations endpoint
version: 2
---

Whisper was trained to transcribe speech in many languages and to **translate it into English**, and the API exposes the second job as its own endpoint: `audio.translations`. It takes a recording in any language Whisper knows and returns English text, in one step.

```python
"""The Portuguese voicemail, transcribed as it was said and translated into English."""
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8700/v1")   # audio_server.py, on this machine
with open("media/voicemail-pt.wav", "rb") as audio:
    said = client.audio.transcriptions.create(model="whisper-base", file=audio)
with open("media/voicemail-pt.wav", "rb") as audio:
    english = client.audio.translations.create(model="whisper-base", file=audio)
print("transcribed:", said.text)
print("translated: ", english.text)
```

```
ana@lab:~/mm$ python translate.py
transcribed: Oi, aqui é o Rafael Piente da Maginalia, sou ligando sobre o pedido em 2002-1987, um exemplar de memórias postmas de brassculpas que chegou com a capa amassada. Vocês podem me ligar de volta no fim da tarde? Obrigado.
translated:  Hi, here is Rafael Pienta from Marginalia, I'm calling on the request in my 2017 an exemplary memory of brass cubes that arrived with the mass cover. You can come back in the end of the afternoon, thank you.
```

Both lines are Whisper base's, run by the course's server. The translation carries the transcription's errors into English and adds its own: *pedido M-2087* became *the request in my 2017*, and *Memórias Póstumas de Brás Cubas* became *an exemplary memory of brass cubes*. The meaning of the message (a customer, a damaged cover, please call back in the afternoon) survives; the order number and the title, which are what the shop needs, do not.

Three things to know about it:

- **It only translates into English.** For any other target, transcribe in the original language and translate the text with a language model, which also lets you check the transcript first.
- **It is the same behaviour lesson 7 met by accident**, when Whisper was told a Portuguese recording was English and translated it without saying so. Here it is asked for; there it was a mistake.
- **Translate the text, not the audio, when names and numbers matter.** A two-step pipeline (transcribe in Portuguese, correct names with the shop's lexicon as in lesson 7, then translate) keeps *Brás Cubas* a name. The one-step endpoint gives a model that misheard a name no chance to be corrected before it is translated into something else.
