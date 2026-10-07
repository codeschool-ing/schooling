---
title: Measuring a transcript: the word error rate
version: 1
---

**The word error rate (WER)** counts the smallest number of single-word edits that turn a transcript into the truth, and divides by the number of words in the truth. Three kinds of edit:

- a **substitution** (S), one word heard as another: *Kau* for *Caio*;
- a **deletion** (D), a word that was said and is missing;
- an **insertion** (I), a word that was not said and appears.

WER = (S + D + I) / N, where N is the number of words actually said. Because insertions are counted, a transcript full of invented words can score above 100%.

`jiwer` computes it and can show the alignment, word by word. The programs in this lesson also import `measure.py`, the module of two functions lesson 5 wrote in `~/mm`: `words()` makes a transcript comparable, and `transcript()` cuts a recording at its silences and transcribes it. Here are two of Bia's and Caio's turns, each cut out of the call by the script's own times and transcribed alone:

```python
"""Each turn of the call cut out by the script's own times and transcribed alone, aligned with what was said."""
import json
import sys

import jiwer

import mmlab
from measure import words

turns = json.load(open("media/truth/call-1042.json"))["turns"]
samples = mmlab.read_audio("media/call-1042.wav")
whisper = mmlab.whisper(sys.argv[1], language="en")
pick = [int(n) for n in sys.argv[2:]]
said, heard = [], []
for i in pick:
    t = turns[i]
    text, _ = mmlab.transcribe(whisper, samples[int(t["start"] * mmlab.RATE):int(t["end"] * mmlab.RATE)])
    said.append(words(t["text"]))
    heard.append(words(text))
print(jiwer.visualize_alignment(jiwer.process_words(said, heard), show_measures=False))
```

```
ana@lab:~/mm$ python turns.py base 1 2
=== SENTENCE 1 ===

REF: hi caio im calling about order m1042 its a copy of dom casmurro by machado     de assis and it arrived on the twentyfourth of september
HYP: hi  kau im calling about order m1042 its a copy of dom  kazmuro by machado desiss ***** and it arrived on  24 ************ ** september
           S                                                       S                 S     D                     S            D  D          

=== SENTENCE 2 ===

REF: let me pull that up yes i can see it here one copy of dom  casmurro delivered on the twentyfourth what seems to be the problem
HYP: let me pull that up yes i can see it here one copy of dom casmorrow delivered on the         24th what seems to be the problem
                                                                       S                             S                             
```

The marks under each line are the alignment's verdict. *kau* for *caio* is an **S**. *machado desiss* for *machado de assis* is two substitutions and a deletion, because the model wrote two words where three were said. And three of the errors on the first line are not errors at all: *24* for *twentyfourth*, and the *the* and *of* that come with it. **The model wrote the date as a number, and the truth spells it out.**

## Score what you mean to score

That last point decides more than any model choice. The same base transcript of the whole call, scored three ways:

```python
"""The same transcript scored three ways: as written, without case and punctuation, and with numbers as words."""
import re
import sys

import jiwer
from num2words import num2words

import mmlab
from measure import transcript, words

truth = open("media/truth/call-1042.txt").read()
heard, _ = transcript(mmlab.read_audio("media/call-1042.wav"), mmlab.whisper(sys.argv[1], language="en"))


def spelled(text):
    """24th -> twenty-fourth, 10 -> ten: numbers written as the words they were spoken as."""
    text = re.sub(r"\b(\d+)(st|nd|rd|th)\b", lambda m: num2words(int(m[1]), to="ordinal"), text)
    return re.sub(r"(?<![\w-])\d+(?![\w-])", lambda m: num2words(int(m[0])), text)


print(f"as written:                  WER {jiwer.wer(truth, heard):6.1%}")
print(f"no case, no punctuation:     WER {jiwer.wer(words(truth), words(heard)):6.1%}")
print(f"and numbers spelled out:     WER {jiwer.wer(words(spelled(truth)), words(spelled(heard))):6.1%}")
```

```
ana@lab:~/mm$ python fairly.py base
as written:                  WER  18.5%
no case, no punctuation:     WER  12.6%
and numbers spelled out:     WER  13.2%
```

Scored **as written**, 18.5%: every capital letter and every comma that differs counts as a wrong word. **Without case and punctuation**, the measure every transcript in this course uses, 12.6%. **With numbers spelled out on both sides**, 13.2%: better for *24th*, worse for *3480*, which `num2words` spells as *three thousand, four hundred and eighty* where Caio said *thirty-four eighty*. Neither way of writing that number is wrong; they are two ways of writing one sound.

So **a WER is only comparable with another WER normalised the same way**. A vendor's figure measured with their normalisation and yours measured with jiwer's defaults are two different numbers with the same name. When you compare models, run both on the same audio, through the same `words()` function, against the same truth, and the comparison means something.
