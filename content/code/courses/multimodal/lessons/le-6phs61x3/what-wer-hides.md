---
title: What the word error rate does not say
version: 1
---

A WER treats every word alike. *The* and *Casmurro* count the same, and so do a dropped *a* and a wrong digit in an order number. For a shop, the words that matter are a small set, and their accuracy deserves a number of its own:

```python
"""How many of the shop's own words came out exactly right, which a word error rate does not say."""
import mmlab
from lexicon import correct
from measure import transcript, words

TERMS = ["Marginalia", "Caio", "M-1042", "Dom Casmurro", "Machado de Assis"]
truth = words(open("media/truth/call-1042.txt").read())
samples = mmlab.read_audio("media/call-1042.wav")
for size in ("tiny", "base"):
    heard, _ = transcript(samples, mmlab.whisper(size, language="en"))
    for label, text in (("as heard", heard), ("corrected", correct(heard)[0])):
        got = sum(min(words(text).count(words(t)), truth.count(words(t))) for t in TERMS)
        want = sum(truth.count(words(t)) for t in TERMS)
        print(f"{size:4} {label:9} {got} of {want} mentions of the shop's terms right")
```

```
ana@lab:~/mm$ python names.py
tiny as heard  1 of 8 mentions of the shop's terms right
tiny corrected 4 of 8 mentions of the shop's terms right
base as heard  3 of 8 mentions of the shop's terms right
base corrected 6 of 8 mentions of the shop's terms right
```

The call mentions the shop's terms eight times: Marginalia twice, Caio twice, M-1042 once, Dom Casmurro twice and Machado de Assis once. **Tiny got 1 of the 8 right**, and base 3. After the lexicon, tiny got 4 and base 6. That is a much bigger change than the WER's move from 12.6% to 9.9%, and it is the change the shop cares about: a transcript that says Dom Casmurro can be found by searching for Dom Casmurro.

So measure both: the **WER** for the transcript as a whole, and the **term accuracy** for the words the business runs on. A model that improves the first and worsens the second is worse for you, and only the second number would say so.

## Building a test set worth trusting

Every number in this lesson came from one call, 151 words long, with the truth known because the lab made it. A real decision needs more, and building it is unglamorous work:

1. **Sample real recordings**, across the conditions you will meet: phone and app, quiet and noisy, each accent your customers have, each language.
2. **Have a person transcribe them**, with written rules for numbers, names and punctuation, so two transcribers agree with each other. The rules are the normalisation of section 02.
3. **Mark the terms that matter** in each truth, so term accuracy can be counted.
4. **Keep the set fixed**, and run every candidate model and every change (a filter, a lexicon, a prompt) against the whole of it.

A few dozen recordings is enough to tell tiny from base, and not enough to tell two good hosted models apart; a difference of a point or two of WER needs hours of audio to be real. The test set is the asset that outlives every model you test on it.
