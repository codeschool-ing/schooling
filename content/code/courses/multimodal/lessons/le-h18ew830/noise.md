---
title: Measuring noise
version: 1
---

**Noise is everything in the recording that is not the signal you want.** Before removing it, measure it: how loud it is against the speech, and where in the spectrum it sits. Both decide what will work.

The lab can measure exactly, because it has the clean call and the noisy one, and the noise is simply the difference between them:

```python
"""How loud the noise is against the voices, and where in the spectrum it sits."""
import numpy as np

import mmlab

clean = mmlab.read_audio("media/call-1042.wav")
noise = mmlab.read_audio("media/call-1042-noisy.wav") - clean
db = lambda x: 10 * np.log10((x ** 2).mean())
print(f"signal-to-noise ratio: {db(clean) - db(noise):.1f} dB")

freqs = np.fft.rfftfreq(len(clean), 1 / mmlab.RATE)
for name, x in (("voices", clean), ("noise", noise)):
    power = np.abs(np.fft.rfft(x)) ** 2
    bands = [(0, 100), (100, 300), (300, 1000), (1000, 3400), (3400, 8000)]
    share = [power[(freqs >= a) & (freqs < b)].sum() / power.sum() for a, b in bands]
    print(f"{name:7}", "  ".join(f"{a}-{b} Hz {s:5.1%}" for (a, b), s in zip(bands, share)))
print(f"loudest single frequency in the noise: {freqs[np.argmax(np.abs(np.fft.rfft(noise)))]:.0f} Hz")
```

```
ana@lab:~/mm$ python noise.py
signal-to-noise ratio: 4.9 dB
voices  0-100 Hz 11.0%  100-300 Hz 51.7%  300-1000 Hz 25.2%  1000-3400 Hz  9.0%  3400-8000 Hz  3.1%
noise   0-100 Hz 54.2%  100-300 Hz 11.5%  300-1000 Hz 12.6%  1000-3400 Hz 12.7%  3400-8000 Hz  8.9%
loudest single frequency in the noise: 60 Hz
```

**The signal-to-noise ratio (SNR) is 4.9 dB**: the voices carry about three times the power of the noise (10^0.49 ≈ 3.1). For comparison, a quiet office recording is typically above 30 dB, and a call from a car or a street can fall to 10 dB or below. 4.9 dB is a bad line, and it was built to be one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Paired bars for five frequency bands, showing what share of its energy each of the two sounds has in the band. Below 100 Hz: voices 11.0%, noise 54.2%. 100 to 300 Hz: voices 51.7%, noise 11.5%. 300 to 1000 Hz: voices 25.2%, noise 12.6%. 1000 to 3400 Hz: voices 9.0%, noise 12.7%. 3400 to 8000 Hz: voices 3.1%, noise 8.9%. Half the noise is below 100 Hz, where the voices have little.\"><line x1=\"60\" y1=\"190\" x2=\"700\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"90\" y=\"162.5\" width=\"30\" height=\"27.5\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"105\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">11.0%</text><rect x=\"124\" y=\"54.5\" width=\"30\" height=\"135.5\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"139\" y=\"45.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">54.2%</text><text x=\"122\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0-100</text><rect x=\"215\" y=\"60.75\" width=\"30\" height=\"129.25\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"230\" y=\"51.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">51.7%</text><rect x=\"249\" y=\"161.25\" width=\"30\" height=\"28.75\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"264\" y=\"152.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">11.5%</text><text x=\"247\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">100-300</text><rect x=\"340\" y=\"127.0\" width=\"30\" height=\"63.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"355\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">25.2%</text><rect x=\"374\" y=\"158.5\" width=\"30\" height=\"31.5\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"389\" y=\"149.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">12.6%</text><text x=\"372\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">300-1000</text><rect x=\"465\" y=\"167.5\" width=\"30\" height=\"22.5\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">9.0%</text><rect x=\"499\" y=\"158.25\" width=\"30\" height=\"31.75\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"149.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">12.7%</text><text x=\"497\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1000-3400</text><rect x=\"590\" y=\"182.25\" width=\"30\" height=\"7.75\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"605\" y=\"173.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">3.1%</text><rect x=\"624\" y=\"167.75\" width=\"30\" height=\"22.25\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"639\" y=\"158.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">8.9%</text><text x=\"622\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3400-8000</text><text x=\"380\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Hz</text><rect x=\"470\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"488\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">voices</text><rect x=\"570\" y=\"12\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"588\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">noise</text></svg>", "caption": "Where the noise lives decides how it can be removed: a hum below 100 Hz can be cut away, a hiss in the voices' own band cannot."}
```

**Where the noise lives is the more useful number.** More than half of it, 54.2%, is below 100 Hz, and the single loudest frequency is exactly 60 Hz: that is the hum, the kind mains electricity leaves on a cheap microphone in a country whose grid runs at 60 Hz, as Brazil's does. The voices have 11.0% of their energy down there. The rest of the noise is a hiss spread across every band, including 100 to 3,400 Hz, where the voices carry 85.9% of theirs.

That split is the whole strategy of the next section in one sentence. **A noise outside the speech band can be cut away with a filter; a noise inside it cannot**, because any filter that removes it removes the voices with it. That second kind needs something that knows what speech sounds like.

In a real product the clean recording does not exist, so the noise is measured in the gaps: a stretch the speech detector says is silence holds only noise, and its level and spectrum stand for the noise under the words. ffmpeg's `astats` and `silencedetect` filters do it without writing any code.
