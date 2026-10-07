---
title: The silence before the first word
version: 1
---

On a phone line, a reply that takes two seconds to start sounds like a dropped call. **Latency in speech is the time to the first sound**, not the time to make all of it, and the two are very different numbers:

```python
"""How long a caller waits before the first word: the whole reply at once, or sentence by sentence."""
import re
import time

import mmlab

REPLY = ("Your order M, one zero four two, was delivered on the twenty-fourth of September. "
         "It can be returned until the twenty-fourth of October, free of charge. "
         "We will e-mail you a prepaid label in the next few minutes. "
         "Print it, tape it over the old address, and drop the parcel at any post office. "
         "Your refund of 34 reais and 80 centavos will reach your card once the parcel arrives.")
tts = mmlab.piper("en_US-lessac-medium")
tts.generate("Warm up.", sid=0, speed=1.0)            # the first call pays for loading; leave it out

started = time.time()
whole = tts.generate(REPLY, sid=0, speed=1.0)
wait = time.time() - started
audio = len(whole.samples) / whole.sample_rate
print(f"all at once:     first sound after {wait:.2f} s, {audio:.1f} s of speech, real-time factor {wait / audio:.3f}")

sentences = re.split(r"(?<=\.) ", REPLY)
started = time.time()
first = tts.generate(sentences[0], sid=0, speed=1.0)
print(f"one sentence:    first sound after {time.time() - started:.2f} s, "
      f"{len(first.samples) / first.sample_rate:.1f} s of speech to play while the next {len(sentences) - 1} are made")
```

```
ana@lab:~/mm$ python latency.py
all at once:     first sound after 0.99 s, 18.4 s of speech, real-time factor 0.054
one sentence:    first sound after 0.20 s, 4.0 s of speech to play while the next 4 are made
```

Made all at once, the five-sentence reply takes **0.99 seconds** before anything can be played, for 18.4 seconds of speech. The **real-time factor** is 0.054: Piper makes speech eighteen times faster than it plays, which is plenty. And still the caller waits a second in silence.

Made one sentence at a time, the first sentence is ready in **0.20 seconds** and plays for 4.0 seconds, and the next four are made while it plays. As long as each sentence is made faster than the one before it plays, which a real-time factor of 0.054 guarantees with room to spare, the caller never hears a gap again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two timelines starting when the reply is ready. All at once: the caller hears nothing for 0.99 seconds while the whole 18.4-second reply is synthesised, then hears it. Sentence by sentence: the first sentence is ready after 0.20 seconds and plays for 4.0 seconds, and the remaining four sentences are made while it plays.\"><text x=\"20\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">all at once</text><rect x=\"180\" y=\"32\" width=\"23.76\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"209.76\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">silence: 0.99 s</text><rect x=\"203.76\" y=\"32\" width=\"441.6000000000001\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"324\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">speech</text><text x=\"20\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sentence by sentence</text><rect x=\"180\" y=\"92\" width=\"4.8\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"184.8\" y=\"92\" width=\"96.0\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"232.8\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sentence 1</text><rect x=\"280.8\" y=\"92\" width=\"419.2\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"290.8\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sentences 2 to 5, made while 1 plays</text><text x=\"180\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5 s</text><text x=\"420\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 s</text><text x=\"540\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15 s</text><text x=\"660\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 s</text><text x=\"20\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">The total work is the same. What the caller notices is the first gap.</text></svg>", "caption": "Streaming does not make synthesis faster; it moves the wait to where nobody hears it."}
```

## Where the rest of the wait comes from

The voice is usually the smallest part of a spoken reply's latency. In a cascade (lesson 1) the caller waits for the transcriber to decide the caller has finished speaking, then for the language model to write the reply, then for the voice. Each stage can stream to the next:

- the language model's reply arrives **token by token**, so the first sentence can go to the voice as soon as its full stop arrives;
- the voice can start on that sentence while the model writes the second;
- hosted TTS APIs return audio **as a stream** of chunks, so playing can start before the file is complete.

The rule that ties them together is the one in `latency.py`: **cut at sentence boundaries and hand each piece on as soon as it exists**. Cutting finer than a sentence breaks intonation, since the voice needs to see the full stop to know the sentence is ending (section 05).

Lesson 13 adds the network to this account. A hosted voice is faster per sentence than a laptop and adds a round trip per request; a local voice like Piper adds no network and needs a machine to run on. Both are honest choices, and the measurement above is how to make it.
