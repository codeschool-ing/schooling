---
title: A smaller copy of the same model
version: 1
---

**Quantisation** stores a model's weights with fewer bits. A full-precision model keeps each weight as a 32-bit floating-point number (**fp32**); an **int8** copy keeps most of them as 8-bit integers plus a scale, roughly a quarter of the space for the quantised parts. The question is always the same: what does the smaller copy cost in accuracy?

The lab has both copies of each Whisper, side by side:

```
ana@lab:~/mm$ cd /opt/multimodal/share && ls -l sherpa-onnx-whisper-base/*.onnx | awk "{print \$5, \$9}"
130672026 sherpa-onnx-whisper-base/base-decoder.int8.onnx
196548998 sherpa-onnx-whisper-base/base-decoder.onnx
29120534 sherpa-onnx-whisper-base/base-encoder.int8.onnx
95087154 sherpa-onnx-whisper-base/base-encoder.onnx
```

So the question can be measured instead of argued, with lesson 5's `measure.py` for the word error rate:

```python
"""The same Whisper at full precision and at int8: size on disk, time to load, time to transcribe, words wrong."""
import os
import time

import mmlab
from measure import transcript, wer

TRUTH = open("media/truth/call-1042.txt").read()
samples = mmlab.read_audio("media/call-1042.wav")
for size in ("tiny", "base"):
    for int8 in (False, True):
        q = ".int8" if int8 else ""
        d = os.path.join(mmlab.SHARE, f"sherpa-onnx-whisper-{size}")
        mb = sum(os.path.getsize(f"{d}/{size}-{part}{q}.onnx") for part in ("encoder", "decoder")) / 1e6
        started = time.time()
        model = mmlab.whisper(size, language="en", int8=int8)
        loaded = time.time() - started
        started = time.time()
        text, _ = transcript(samples, model)
        ran = time.time() - started
        print(f"{size:4} {'int8' if int8 else 'fp32':4}  {mb:6.1f} MB  load {loaded:4.1f} s  "
              f"transcribe {ran:5.1f} s  WER {wer(TRUTH, text):6.1%}")
```

```
ana@lab:~/mm$ python precision.py
tiny fp32   152.2 MB  load  1.2 s  transcribe   4.9 s  WER  17.2%
tiny int8   102.8 MB  load  0.4 s  transcribe   4.1 s  WER  16.6%
base fp32   291.6 MB  load  2.4 s  transcribe   8.5 s  WER  11.9%
base int8   159.8 MB  load  0.8 s  transcribe   6.8 s  WER  12.6%
```

**On this call, int8 cost nothing measurable.** Tiny int8 scored 16.6% against 17.2% for fp32, and base int8 12.6% against 11.9%. One went up and one went down, by less than one word in a hundred, on 151 words of speech: that is the noise of a single recording, not a difference between the copies. What int8 bought is plain: **base at 160 MB instead of 292**, loaded in 0.8 seconds instead of 2.4, and transcribing in 6.8 seconds instead of 8.5.

The sizes did not quite fall to a quarter, because not every part of a model is quantised. The encoders shrank about three times; the decoders much less, since a large share of a Whisper decoder is its vocabulary table, which this export keeps at higher precision.

Two cautions keep this from becoming a rule:

- **One call is not a test set.** Lesson 7's advice applies: run both copies on the recordings you care about before choosing. Quantisation errors tend to show on the hard cases, such as accents, noise and names, and a 151-word call has few of them.
- **Not every model quantises this well.** Small models and image generators can lose visibly at int8; some formats go further (4-bit) and lose more. The measurement above is the method; the result is this model's.

For a lab, a laptop or a phone, the int8 copy is the default worth starting from, and this lab uses it everywhere through `mmlab.whisper`.
