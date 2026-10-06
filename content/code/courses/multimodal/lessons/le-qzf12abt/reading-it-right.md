---
title: Making it read numbers, dates and names right
version: 1
---

**The cheapest test of a voice is to let a transcriber listen to it.** Speak a sentence with Piper, transcribe the audio with Whisper, and compare. Whatever comes back different is a place where a listener might hear something else too:

```python
"""Say each sentence with a Piper voice, then let Whisper write down what it heard in that voice's language."""
import sys

import soundfile as sf

import mmlab

voice = sys.argv[2] if len(sys.argv) > 2 else "en_US-lessac-medium"
tts = mmlab.piper(voice)
whisper = mmlab.whisper("base", language=voice[:2])
for line in open(sys.argv[1]):
    text = line.strip()
    audio = tts.generate(text, sid=0, speed=1.0)
    sf.write("/tmp/roundtrip.wav", audio.samples, audio.sample_rate)
    heard, _ = mmlab.transcribe(whisper, mmlab.read_audio("/tmp/roundtrip.wav"))
    print(f"said:  {text}\nheard: {heard}")
```

```
ana@lab:~/mm$ python roundtrip.py said.txt
said:  Your order M-1042 arrived on 24/09/2026.
heard: Your Order M 1042 arrived on 24/09/2021/26.
said:  Your refund of R$ 34,80 is on its way.
heard: Your refund of our $1.3480 is on its way.
said:  Dom Casmurro, by Machado de Assis.
heard: Dom Kismuro by Machado Desiss
```

Each of the three came back wrong, and each wrong in the way the phonemes in section 02 predicted. *24/09/2026* came back as *24/09/2021/26*: Whisper heard "twenty twenty-one, twenty-six" in "two thousand twenty six". *R$ 34,80* came back as *our $1.3480*: the voice said "R dollar thirty four eighty", and Whisper wrote down a dollar amount that does not exist. And *Dom Casmurro, by Machado de Assis* came back as *Dom Kismuro by Machado Desiss*.

**A round trip has two models in it, so a difference is a suspicion, not a verdict.** Whisper makes mistakes of its own (lessons 4 and 7 are full of them). A line that comes back different is one to listen to; a line that comes back the same is evidence, not proof, that a person will hear it right. The phonemes from espeak-ng are the direct evidence: they say exactly what the voice was told to say.

## The fix is to write what should be said

```schooling-example
{
  "language": "python",
  "file": "spoken.py",
  "parts": [
    {
      "code": "\"\"\"Rewrite the things a voice reads badly into the words a person would say.\"\"\"\nimport re\nimport sys\n\n"
    },
    {
      "code": "DIGITS = \"zero one two three four five six seven eight nine\".split()\nMONTHS = (\"January February March April May June July August September October November \"\n          \"December\").split()\nORDINAL = {1: \"first\", 2: \"second\", 3: \"third\", 21: \"twenty-first\", 22: \"twenty-second\",\n           23: \"twenty-third\", 24: \"twenty-fourth\", 30: \"thirtieth\", 31: \"thirty-first\"}\n\n\n",
      "note": "**The words the rewrites need**: digits, months and the few ordinals Marginalia's dates use. A real system takes a library for this; the point here is to see the rules."
    },
    {
      "code": "def order_id(m):                        # M-1042 -> \"M, one zero four two\"\n    return m[1] + \", \" + \" \".join(DIGITS[int(d)] for d in m[2])\n\n\n",
      "note": "**An order number is read digit by digit**, with a comma after the letter so the voice pauses. *One thousand forty-two* is a quantity; an order number is a code."
    },
    {
      "code": "def date(m):                            # 24/09/2026 -> \"the twenty-fourth of September\"\n    day, month = int(m[1]), int(m[2])\n    return f\"the {ORDINAL.get(day, str(day) + 'th')} of {MONTHS[month - 1]}\"\n\n\n",
      "note": "**A date becomes the words a person says**: the day as an ordinal and the month by name. The year is dropped, as people do when it is this year."
    },
    {
      "code": "def reais(m):                           # R$ 34,80 -> \"34 reais and 80 centavos\"\n    return f\"{int(m[1])} reais\" + (f\" and {int(m[2])} centavos\" if int(m[2]) else \"\")\n\n\n",
      "note": "**Money in reais** gets its currency spoken, which `R$` never is: espeak-ng read it as *R dollar*."
    },
    {
      "code": "RULES = [(r\"\\b([A-Z])-(\\d{4})\\b\", order_id),\n         (r\"\\b(\\d{1,2})/(\\d{1,2})/\\d{4}\\b\", date),\n         (r\"R\\$ ?(\\d+),(\\d\\d)\\b\", reais)]\n\n\n",
      "note": "**The rules, in the order they run.** An order number is matched before anything else could take its digits."
    },
    {
      "code": "def spoken(text):\n    for pattern, rewrite in RULES:\n        text = re.sub(pattern, rewrite, text)\n    return text\n\n\n",
      "note": "**One function a pipeline calls** on every text before the voice sees it."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for line in open(sys.argv[1]):\n        print(spoken(line.strip()))",
      "note": "**Run as a program**, it rewrites a file line by line, which is how the round trip below uses it."
    }
  ]
}
```

```
ana@lab:~/mm$ python spoken.py said.txt | tee said-spoken.txt
Your order M, one zero four two arrived on the twenty-fourth of September.
Your refund of 34 reais and 80 centavos is on its way.
Dom Casmurro, by Machado de Assis.
ana@lab:~/mm$ python roundtrip.py said-spoken.txt
said:  Your order M, one zero four two arrived on the twenty-fourth of September.
heard: Your Order M-1042 arrived on the 24th of September.
said:  Your refund of 34 reais and 80 centavos is on its way.
heard: Your refund of 34 Rs and 80 centavos is on its way.
said:  Dom Casmurro, by Machado de Assis.
heard: Dom Kismuro by Machado Desiss
```

Now the order number comes back as *M-1042*, the date as *the 24th of September*, and only *reais* is misheard as *Rs*, an English transcriber's guess at a Portuguese word in an English sentence. The rewrites are rules a person can read and test, which is the point: a voice reads whatever it is given, so **what it is given is where the quality is decided**.

Real systems use a library of such rules per language rather than three regular expressions, and most commercial voices normalise common cases themselves. Shop-specific things are never in anybody's library: order numbers, product codes, the shop's own name. Those are always yours to write.

## Names in another language

The title came back as *Dom Kismuro* through the English voice, and spelling tricks will not make an English voice say Portuguese. Two honest options remain. **Use the voice of the name's language for the name**, which is what a bilingual person does. The Portuguese voice says the title like this, transcribed by Whisper in Portuguese:

```
ana@lab:~/mm$ python roundtrip.py titulo.txt pt_BR-faber-medium
said:  Dom Casmurro, de Machado de Assis.
heard: Tom Casmogo de Machado de Assis.
```

It is not perfect either: *Tom Casmogo de Machado de Assis*, with the author now right and the novel's name still not. **Or give the voice the phonemes directly**, which many commercial TTS services allow through SSML's `<phoneme>` element, and which the next section returns to. For a shop that says the same twenty titles every day, a short pronunciation list checked once by a person is cheaper than either.
