---
title: Choosing a voice
version: 2
---

The lab has three Piper voices: **lessac**, American English; **alan**, British English; and **faber**, Brazilian Portuguese. The same short message in each:

```python
"""Speak a text with one of the lab's Piper voices and save it as a WAV."""
import sys
import time

import soundfile as sf

import mmlab

voice, text, out = sys.argv[1], sys.argv[2], sys.argv[3]
speed = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
tts = mmlab.piper(voice)
started = time.time()
audio = tts.generate(text, sid=0, speed=speed)
took = time.time() - started
seconds = len(audio.samples) / audio.sample_rate
sf.write(out, audio.samples, audio.sample_rate)
print(f"{out}: {seconds:.2f} s of audio at {audio.sample_rate} Hz, made in {took:.2f} s")
```

```
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped. It should arrive on Thursday." lessac.wav
lessac.wav: 2.76 s of audio at 22050 Hz, made in 0.26 s
ana@lab:~/mm$ python say.py en_GB-alan-medium "Your order has shipped. It should arrive on Thursday." alan.wav
alan.wav: 3.47 s of audio at 22050 Hz, made in 0.21 s
ana@lab:~/mm$ python say.py pt_BR-faber-medium "Seu pedido foi enviado. Deve chegar na quinta-feira." faber.wav
faber.wav: 2.82 s of audio at 22050 Hz, made in 0.32 s
ana@lab:~/mm$ grep -E "Language|Samplerate|URL|License" /opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD
* Language: en_US (English, United States)
* Samplerate: 22,050Hz
* URL: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/
* License: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html
```

All three produce **22,050 samples a second**, which is more than a telephone carries (lesson 5) and less than music is recorded at; it is a common choice for speech. All three made their audio far faster than it plays: lessac made 2.76 seconds of speech in 0.26 seconds, on four ordinary processor cores and no graphics card. The *alan* voice took 3.47 seconds for the same words, a quarter longer: voices differ in pace as people do, and a phone menu built for one will run long with another.

## What to look at when choosing

**The language and the accent of the people listening.** A Brazilian customer hearing *lessac* read Portuguese would hear English rules applied to Portuguese words. A voice is chosen per language, and for a bilingual shop that means two voices and a decision about which one reads a sentence that mixes them (section 04 shows what that costs).

**The licence, which lives in two places.** The voice's own licence covers the model; the **dataset** it was trained on may carry its own terms, and those can be stricter. Every Piper voice ships a model card, and it points to where the data came from, as the last command above shows: `lessac` was trained on a dataset released for the Blizzard Challenge 2013, a research evaluation, and the card links that dataset's licence page. Whether a voice may answer a commercial shop's phone line is a question that page answers, not the voice's file; read it before shipping, as lesson 11 does for every model in the lab.

**Consent, for any voice that sounds like a person.** The voices here were recorded by people who agreed to make a speech dataset. Voice cloning, where a model imitates a specific person from a short recording, makes it possible to put words into somebody's mouth. A shop has no reason to clone anybody's voice without written consent, and most providers' terms forbid it.

**Saying that it is a machine.** A caller should know they are talking to a synthetic voice. One sentence at the start of the call does it, and in several places it is required by law for automated calls. It also sets expectations: people speak more clearly to a machine they know is one.
