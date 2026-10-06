---
title: Intonation, pace and saying it the same way twice
version: 1
---

**Intonation is how pitch moves through a sentence**, and in English it carries meaning: a statement falls at the end, a question rises. Piper takes its cue from punctuation, which espeak-ng passes on as a mark of what kind of clause it is. The same four words with a full stop and with a question mark:

```
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped." /tmp/a.wav 1.0
/tmp/a.wav: 1.14 s of audio at 22050 Hz, made in 0.11 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped?" /tmp/b.wav 1.0
/tmp/b.wav: 1.15 s of audio at 22050 Hz, made in 0.11 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped!" /tmp/c.wav 1.0
/tmp/c.wav: 1.14 s of audio at 22050 Hz, made in 0.11 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped." /tmp/d.wav 0.8
/tmp/d.wav: 1.31 s of audio at 22050 Hz, made in 0.11 s
ana@lab:~/mm$ python say.py en_US-lessac-medium "Your order has shipped." /tmp/e.wav 1.25
/tmp/e.wav: 1.00 s of audio at 22050 Hz, made in 0.11 s
```

The lengths barely move, 1.14 against 1.15 seconds. The pitch does, measured by a small program that estimates the voice's fundamental frequency every 30 milliseconds:

```python
"""The voice's pitch over the first half of a sentence and over its last word."""
import sys

import numpy as np
import soundfile as sf


def pitch(frame, rate):
    """One frame's fundamental frequency, by autocorrelation, or None when it is not voiced."""
    frame = frame - frame.mean()
    ac = np.correlate(frame, frame, "full")[len(frame) - 1:]
    lo, hi = rate // 400, rate // 70                     # look for a pitch between 70 and 400 Hz
    lag = lo + int(np.argmax(ac[lo:hi]))
    return rate / lag if ac[lag] > 0.3 * ac[0] else None


for path in sys.argv[1:]:
    x, rate = sf.read(path)
    step = int(0.03 * rate)
    f0 = [(i / rate, pitch(x[i:i + step], rate)) for i in range(0, len(x) - step, step)]
    voiced = [(t, f) for t, f in f0 if f]
    end = voiced[-1][0]
    early = np.median([f for t, f in voiced if t < end / 2])
    late = np.median([f for t, f in voiced if t > end - 0.35])
    print(f"{path}: {early:5.0f} Hz in the first half, {late:5.0f} Hz over the last word")
```

```
ana@lab:~/mm$ python pitch.py /tmp/a.wav /tmp/b.wav
/tmp/a.wav:   184 Hz in the first half,   125 Hz over the last word
/tmp/b.wav:   204 Hz in the first half,   174 Hz over the last word
```

The statement starts around 184 Hz and falls to 125 Hz over its last word. The question starts higher and stays up, 174 Hz over the last word. That is the difference a listener hears between *Your order has shipped.* and *Your order has shipped?*, and it came from one character. **Punctuation is the cheapest control you have over a voice**: a comma for a pause, a full stop for an ending, a question mark for a question, and a dash where you want a longer pause than a comma gives.

**Pace** is a setting. Piper's `speed` scales the length of every sound: at 0.8 the sentence took 1.31 seconds, at 1.25 it took 1.00. Phone menus are usually slowed slightly, because a listener cannot scroll back and a number heard too fast has to be asked for again.

## What commercial voices add

Most hosted TTS services accept **SSML** (Speech Synthesis Markup Language), an XML dialect for exactly these controls: `<break time="500ms"/>` for a pause, `<prosody rate="slow">` for pace, `<say-as interpret-as="characters">` for reading a code letter by letter, `<phoneme>` for a pronunciation. Google Cloud, Amazon Polly and Azure all support it, each with its own subset. OpenAI's speech models do not take SSML; its newer one takes a plain-language `instructions` field instead ("speak slowly and warmly"). Piper takes neither, which is why this lesson does the same work in the text.

## The same sentence, twice

Piper's VITS models add a little randomness when they speak, the way a person never says a sentence the same way twice. That is usually good for a long passage and bad for a test:

```python
"""The same sentence spoken twice, with Piper's own noise and without it."""
import hashlib

import numpy as np

import mmlab

TEXT = "Your order has shipped."
for noise in (True, False):
    tts = mmlab.piper("en_US-lessac-medium", noise=noise)
    takes = [tts.generate(TEXT, sid=0, speed=1.0) for _ in range(2)]
    sums = [hashlib.sha256(np.asarray(t.samples).tobytes()).hexdigest()[:12] for t in takes]
    lengths = [f"{len(t.samples) / t.sample_rate:.2f} s" for t in takes]
    print(f"noise {'on ' if noise else 'off'}  {sums[0]} {lengths[0]}   {sums[1]} {lengths[1]}   "
          f"{'the same' if sums[0] == sums[1] else 'different'}")
```

```
ana@lab:~/mm$ python twice.py
noise on   daed63679ee3 1.13 s   47d643b490a6 1.25 s   different
noise off  8ca881e0ebb4 1.14 s   8ca881e0ebb4 1.14 s   the same
```

With the voice's own noise (`noise_scale` 0.667 in lessac's configuration), the same sentence came out as two different files of 1.20 and 1.13 seconds. With noise switched off, the two takes are identical to the last sample. **This lab switches it off everywhere**, which is the one setting `mmlab.piper` makes: a recording that changes every time the lab is rebuilt could not be quoted by any lesson. A product might choose the other way, for a voice that sounds less mechanical over a long call.
