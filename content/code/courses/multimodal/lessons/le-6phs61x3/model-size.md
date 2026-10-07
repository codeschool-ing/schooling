---
title: A bigger model, and what it buys
version: 1
---

Whisper comes in sizes, from *tiny* (39 million parameters) through *base*, *small*, *medium* and *large*, and the lab has the two smallest. Both, on the three recordings of the call from lesson 5:

```python
"""Whisper tiny and base on three versions of the call: errors by kind, and the time each took."""
import time

import jiwer

import mmlab
from measure import transcript, words

TRUTH = words(open("media/truth/call-1042.txt").read())
for size in ("tiny", "base"):
    whisper = mmlab.whisper(size, language="en")
    for name in ("call-1042", "call-1042-phone", "call-1042-noisy"):
        started = time.time()
        text, _ = transcript(mmlab.read_audio(f"media/{name}.wav"), whisper)
        took = time.time() - started
        o = jiwer.process_words(TRUTH, words(text))
        print(f"{size:4} {name:16} WER {o.wer:6.1%}  substituted {o.substitutions:2}  deleted {o.deletions:2}  "
              f"inserted {o.insertions:2}  {took:4.1f} s")
```

```
ana@lab:~/mm$ python score.py
tiny call-1042        WER  16.6%  substituted 15  deleted  7  inserted  3   5.1 s
tiny call-1042-phone  WER  13.2%  substituted 16  deleted  2  inserted  2   4.4 s
tiny call-1042-noisy  WER  20.5%  substituted 21  deleted  4  inserted  6   4.6 s
base call-1042        WER  12.6%  substituted 12  deleted  6  inserted  1   7.2 s
base call-1042-phone  WER  11.9%  substituted 14  deleted  3  inserted  1   8.0 s
base call-1042-noisy  WER  20.5%  substituted 14  deleted 17  inserted  0   8.4 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Paired bars of word error rate for Whisper tiny and Whisper base on three recordings of the same call. Clean: tiny 16.6%, base 12.6%. Phone line: tiny 13.2%, base 11.9%. Noisy: tiny 20.5%, base 20.5%. Base is better on the clean and phone recordings and no better on the noisy one.\"><line x1=\"60\" y1=\"190\" x2=\"640\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"110\" y=\"90.4\" width=\"44\" height=\"99.6\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"132\" y=\"81.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">16.6%</text><rect x=\"160\" y=\"114.4\" width=\"44\" height=\"75.6\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"182\" y=\"105.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12.6%</text><text x=\"157\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">clean</text><rect x=\"290\" y=\"110.8\" width=\"44\" height=\"79.2\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"312\" y=\"101.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">13.2%</text><rect x=\"340\" y=\"118.6\" width=\"44\" height=\"71.4\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"362\" y=\"109.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">11.9%</text><text x=\"337\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">phone line</text><rect x=\"470\" y=\"67.0\" width=\"44\" height=\"123.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"492\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20.5%</text><rect x=\"520\" y=\"67.0\" width=\"44\" height=\"123.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"542\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20.5%</text><text x=\"517\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">noisy</text><rect x=\"480\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"498\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tiny</text><rect x=\"560\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"578\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">base</text><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Word error rate against the script; lower is better.</text></svg>", "caption": "The larger model helps where the audio is good and stops helping where the audio is the problem."}
```

Four findings, and the last is the one that matters.

**Base is better where the audio is good**: 12.6% against 16.6% on the clean call. It made fewer substitutions (12 against 15) and fewer deletions.

**The phone line cost almost nothing.** Base scored 11.9% on the telephone version, slightly better than on the clean one. That is within the noise of a single 151-word call, and it confirms lesson 5: speech survives the telephone band.

**Base is slower**: about 8 seconds for the call against about 5 for tiny, on four processor cores. Both are faster than real time (the call is 55 seconds), and both times include the speech detector.

**On the noisy call, both scored 20.5%.** The larger model bought nothing, and the way base failed is telling: 17 deletions and no insertions, where tiny made 4 deletions and 6 insertions. Base, faced with noise, said less; tiny guessed more. The same score hides two different behaviours, and which one you prefer depends on whether a missing word or an invented one does more harm downstream.

**A bigger model is not the first fix for bad audio.** Lesson 5's filter brought the noisy call from 20.5% to 13.2% with the same base model. The order of attack is: the recording first, the cleaning second, the model third.

## Choosing a size

| if | then |
|---|---|
| the transcript feeds a search index or a summary | the smallest model whose WER is acceptable on your audio; the downstream step forgives small errors |
| it is shown to people as captions | the largest model you can afford, because every error is on screen (lesson 14) |
| it must run on the device or in real time | tiny or base, measured on that device |
| it goes through a hosted API | the provider's model; lesson 10 sends the same call to labmm's Whisper and to OpenAI's API shape |
