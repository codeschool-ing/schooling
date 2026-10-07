---
title: The shop's own words
version: 1
---

A speech model is trained on general speech, and every business has words that general speech does not: product names, people's names, codes, jargon. They are also the words that matter most in its transcripts. In the call, the words Whisper got wrong are almost all of that kind: *Kau* and *Kyo* for Caio, *Dom Kazmuro* and *Dom Casmorrow* for Dom Casmurro, *Machado Desiss* for Machado de Assis, *M1042* for M-1042.

There are three places to fix them, and only the last one runs in this lab.

**Before decoding, by biasing the model.** Some hosted APIs take a list of words to favour. OpenAI's transcription endpoint takes a `prompt`: text that Whisper treats as what came before the audio, so the spellings in it become more likely. Google's and Amazon's services take phrase lists. Lesson 10 shows where the prompt goes, and why labmm accepts it and cannot use it: the ONNX export this lab runs has no way to take one.

**By training**, on recordings of your own speakers saying your own words. That is the strongest fix and the most expensive, and it is out of this course's reach.

**After decoding, by correcting the text against what the shop knows.** The shop has a catalogue, so it knows how every title and author is spelt. A program can look for runs of words that are spelt almost like one of them, and replace them.

The catalogue first. A real shop's has thousands of lines; this one has twelve, enough for the call. Save it as `data/books.jsonl` in `~/mm`, one book per line:

```json
{"title": "Dom Casmurro", "author": "Machado de Assis"}
{"title": "The Posthumous Memoirs of Brás Cubas", "author": "Machado de Assis"}
{"title": "Bleak House", "author": "Charles Dickens"}
{"title": "Great Expectations", "author": "Charles Dickens"}
{"title": "The Secret Garden", "author": "Frances Hodgson Burnett"}
{"title": "Pride and Prejudice", "author": "Jane Austen"}
{"title": "Emma", "author": "Jane Austen"}
{"title": "Jane Eyre", "author": "Charlotte Brontë"}
{"title": "Middlemarch", "author": "George Eliot"}
{"title": "Madame Bovary", "author": "Gustave Flaubert"}
{"title": "Anna Karenina", "author": "Leo Tolstoy"}
{"title": "Crime and Punishment", "author": "Fyodor Dostoevsky"}
```

Then the program that uses it:

```schooling-example
{
  "language": "python",
  "file": "lexicon.py",
  "parts": [
    {
      "code": "\"\"\"Correct a transcript against the words this shop knows: its name, its staff, its books and their authors.\"\"\"\nimport difflib\nimport json\nimport re\n\n"
    },
    {
      "code": "books = [json.loads(line) for line in open(\"data/books.jsonl\")]\nKNOWN = sorted({\"Marginalia\", \"Caio\"} | {b[\"title\"] for b in books} | {b[\"author\"] for b in books}, key=len, reverse=True)\n\n\n",
      "note": "**The words this shop knows**: its name, the name of the person who answers, and every title and author in the catalogue. Longest first, so *Machado de Assis* is tried before any one-word name inside it."
    },
    {
      "code": "def correct(text, cutoff=0.75):\n    \"\"\"Replace any run of words that is spelt like a known name, but is not it, with the name.\"\"\"\n    fixes = []\n    tokens = text.split()\n    for name in KNOWN:\n        n, i = len(name.split()), 0\n        while i < len(tokens):\n            best = None\n            for size in {max(1, n - 1), n, n + 1}:\n                window = \" \".join(tokens[i:i + size])\n                bare = re.sub(r\"[^\\w ]\", \"\", window).lower()\n",
      "note": "**For every known name, every window of words about its length.** A window one word shorter or longer is tried too, because Whisper splits and joins words: *Desiss* is one word where the name has two."
    },
    {
      "code": "                if name.lower() in bare:                 # the name is already there, spelt right\n                    best = None\n                    break\n                first = bare.split()[0] if bare else \"\"\n                if difflib.SequenceMatcher(None, first, name.lower().split()[0]).ratio() < 0.5:\n                    continue                             # a window must start where the name starts\n",
      "note": "**Two refusals before any scoring.** A window that already contains the name is left alone, and a window must start with something like the name's first word, so *by Machado Desiss* is never taken for the name and the *by* lost."
    },
    {
      "code": "                score = difflib.SequenceMatcher(None, bare, name.lower()).ratio()\n                if score >= cutoff and (best is None or score > best[0]):\n                    best = (score, size, window)\n",
      "note": "**Spelling similarity**, from 0 to 1, and the best window above 0.75 wins. This compares letters, not sounds, which is exactly why it will miss some errors (section 05)."
    },
    {
      "code": "            if best:\n                score, size, window = best\n                tail = window[len(window.rstrip(\",.?!\")):]\n                tokens[i:i + size] = (name + tail).split()\n                fixes.append(f\"{window!r} -> {name!r} ({score:.2f})\")\n                i += n                                   # carry on after the name just written\n            else:\n                i += 1\n",
      "note": "**Replace, record what was done, and move past the name just written.** Every change is listed, so a person can see what the program decided and disagree with it."
    },
    {
      "code": "    text = \" \".join(tokens)\n    text, n = re.subn(r\"\\bM ?(\\d{4})\\b\", r\"M-\\1\", text)             # an order number has a hyphen\n    fixes += [\"M nnnn -> M-nnnn\"] * n\n    return text, fixes",
      "note": "**An order number is a pattern, not a name**, so it gets a rule: a letter and four digits become `M-1042`, with the hyphen the shop writes."
    }
  ]
}
```

```python
"""The base transcript, before and after the shop's lexicon, scored against the script."""
import mmlab
from lexicon import correct
from measure import transcript, wer

truth = open("media/truth/call-1042.txt").read()
heard, _ = transcript(mmlab.read_audio("media/call-1042.wav"), mmlab.whisper("base", language="en"))
fixed, fixes = correct(heard)
for f in fixes:
    print("  ", f)
print(f"WER before {wer(truth, heard):6.1%}   after {wer(truth, fixed):6.1%}")
```

```
ana@lab:~/mm$ python fix.py
   'Machado Desiss' -> 'Machado de Assis' (0.87)
   'Dom Kazmuro' -> 'Dom Casmurro' (0.78)
   'Dom Casmorrow' -> 'Dom Casmurro' (0.88)
   M nnnn -> M-nnnn
WER before  12.6%   after   9.9%
```

Three corrections and an order number reformatted, and the WER fell from **12.6% to 9.9%**. Every correction is printed with its score, which is how you notice when the threshold is too loose: an early version of this program, without the "must start like the name" rule, turned *by Machado Desiss* into *Machado de Assis* and deleted the *by*.

## What it cannot fix

**Caio is still *Kau* and *Kyo*.** Spelling similarity compares letters, and *kau* and *caio* share almost none (0.29). They sound alike and are spelt differently, and a spelling comparison is the wrong tool for a sound-alike. A phonetic comparison (Soundex, Metaphone, or the phonemes lesson 6 printed) would catch some; for the agent's own name, the cheapest fix is that the phone system knows who answered.

**A wrong number is not a misspelt name.** Tiny heard *M-1042* as *M 142*, a digit lost. No list of words recovers a lost digit, and "correcting" it to the nearest valid order number would be inventing data. What the shop can do is check: does order M-142 exist? It does not, so the transcript is flagged for a person, the same move as lesson 2's invoice checking itself.
