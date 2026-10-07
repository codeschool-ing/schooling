---
title: Cleaning a recording, and measuring whether it helped
version: 1
---

Three ways to clean the noisy call, from the bluntest to the cleverest, each one handed to Whisper and scored against the script with the word error rate (WER) from `measure.py`:

```python
"""Two measurements the audio lessons share: words wrong, and speech found."""
import jiwer

import mmlab


def words(text):
    """Lower case, no punctuation, one space: what a word error rate should compare."""
    return " ".join(jiwer.RemovePunctuation()(text.lower()).split())


def transcript(samples, whisper):
    """Cut at silences, transcribe each piece, join them: the pipeline of lesson 4."""
    pieces = mmlab.speech_segments(samples)
    text = " ".join(mmlab.transcribe(whisper, samples[int(s * mmlab.RATE):int(e * mmlab.RATE)])[0] for s, e in pieces)
    return text, pieces


def wer(truth, heard):
    return jiwer.wer(words(truth), words(heard))
```

```python
"""The noisy call cleaned three ways, each one transcribed and scored against the script."""
import subprocess
import time

import numpy as np
import soundfile as sf

import mmlab
from measure import transcript, wer

TRUTH = open("media/truth/call-1042.txt").read()
noisy = mmlab.read_audio("media/call-1042-noisy.wav")


def ffmpeg(audio_filter, out):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", "media/call-1042-noisy.wav",
                    "-af", audio_filter, out], check=True)
    return mmlab.read_audio(out)


started = time.time()
denoised = np.asarray(mmlab.denoiser()(noisy, mmlab.RATE).samples, dtype=np.float32)
print(f"GTCRN took {time.time() - started:.1f} s for {len(noisy) / mmlab.RATE:.1f} s of audio")
sf.write("call-gtcrn.wav", denoised, mmlab.RATE)

versions = {
    "clean (the truth)": mmlab.read_audio("media/call-1042.wav"),
    "noisy, as recorded": noisy,
    "high-pass at 120 Hz": ffmpeg("highpass=f=120", "/tmp/hp.wav"),
    "high-pass + afftdn": ffmpeg("highpass=f=120,afftdn=nf=-25", "/tmp/fftdn.wav"),
    "GTCRN": denoised,
}
whisper = mmlab.whisper("base", language="en")
for name, samples in versions.items():
    text, pieces = transcript(samples, whisper)
    print(f"{name:20} WER {wer(TRUTH, text):6.1%}   {len(pieces):2} stretches of speech found")
```

```
ana@lab:~/mm$ python clean.py
GTCRN took 3.2 s for 55.4 s of audio
clean (the truth)    WER  12.6%   11 stretches of speech found
noisy, as recorded   WER  20.5%    5 stretches of speech found
high-pass at 120 Hz  WER  14.6%    4 stretches of speech found
high-pass + afftdn   WER  13.2%    3 stretches of speech found
GTCRN                WER  17.9%   13 stretches of speech found
```

- A **high-pass filter at 120 Hz** removes everything below 120 Hz. That takes the hum, and the WER falls from 20.5% to 14.6%.
- **afftdn** is ffmpeg's spectral denoiser: it estimates the noise's spectrum and subtracts it, frame by frame. Added to the high-pass, it reaches 13.2%, close to the 12.6% Whisper scores on the clean call itself.
- **GTCRN** is a small neural network trained to separate speech from noise. It took 3.2 seconds for 55 seconds of audio, and Whisper scored 17.9% on its output: better than doing nothing and worse than either filter.

So the cleverest tool lost, on this measure. **It is not that GTCRN is bad**: to a listener its output is the cleanest of the four, with the hiss gone rather than reduced. But a denoiser trained to make speech pleasant for people also changes the speech in small ways, and Whisper was trained on huge amounts of noisy audio and copes with a hiss better than with a voice that has been subtly altered. **What sounds cleaner to you is not what transcribes better for a model.** The only way to know which one your pipeline needs is the measurement in this section, on your own recordings.

The last column tells a different story, and it is why GTCRN stays in the lab. **The noisy call let the speech detector find only 5 stretches of speech, where the clean call has 11.** With the noise floor that high, the silences between turns no longer look like silence. Both filters left it worse still, at 4 and 3. GTCRN brought it back to 13. Section 05 shows what those long stretches do to the job of telling the speakers apart.

## The order matters

Clean first, then resample, then cut, then transcribe. A filter on 8 kHz audio cannot restore what the phone line removed; a denoiser run on each small piece after cutting sees too little noise to learn its shape. And keep the original: a cleaned file is a derivative, and lesson 14's captions are timed against the original.
