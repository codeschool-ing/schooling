---
title: Tokens are the bill
version: 1
---

A model is limited and charged by tokens, never by words or characters. **Its context, the text it
can read at once, is a number of tokens; its time per step grows with the number of tokens; and a
provider that sells access to one prices it per token.** So the question that matters about a
tokenizer is how many tokens your text becomes, and the answer depends on what the tokenizer was
trained on.

`tok.json` was trained on forty-five lines of English. Save this as `~/dl/bill.py` to see what it
makes of Portuguese:

```schooling-example
{
  "language": "python",
  "file": "bill.py",
  "parts": [
    {
      "code": "\"\"\"bill: the same sentences in English and in Portuguese, counted in tokens.\"\"\"\nfrom tokenizers import Tokenizer\n\ntok = Tokenizer.from_file(\"tok.json\")\nPAIRS = [\n    (\"On Monday the baker sells bread.\", \"Na segunda-feira o padeiro vende pão.\"),\n    (\"The goat eats apples, and the cow eats hay.\", \"A cabra come maçãs, e a vaca come feno.\"),\n    (\"The weaver mends the blankets before winter.\", \"O tecelão remenda os cobertores antes do inverno.\"),\n]",
      "note": "Three sentences and their Portuguese. The first two use words from the corpus; the third uses words it never contained, in either language."
    },
    {
      "code": "print(f\"{'':4}{'chars':>6}{'bytes':>6}{'tokens':>7}\")\ntotal = {\"en\": 0, \"pt\": 0}\nfor en, pt in PAIRS:\n    for lang, s in ((\"en\", en), (\"pt\", pt)):\n        n = len(tok.encode(s).ids)\n        total[lang] += n\n        print(f\"{lang:4}{len(s):6d}{len(s.encode()):6d}{n:7d}  {s}\")\nprint(\"tokens, en:\", total[\"en\"], \" pt:\", total[\"pt\"], f\" ratio: {total['pt'] / total['en']:.2f}\")\nprint(\"' pão' ->\", [tok.decode([i]) for i in tok.encode(\" pão\").ids])",
      "note": "Each sentence measured three ways: characters, UTF-8 bytes, and tokens of `tok.json`."
    },
    {
      "code": "CONTEXT = 512   # tokens the model reads at once: an illustrative size\nPRICE = 2.00    # money per million tokens: an illustrative price, not anybody's\nfor lang in (\"en\", \"pt\"):\n    per = total[lang] / len(PAIRS)\n    print(f\"{lang}: {per:.1f} tokens a sentence, {int(CONTEXT // per)} sentences fit in {CONTEXT}, \"\n          f\"a million sentences cost {per * PRICE:.2f}\")",
      "note": "The two numbers that turn a token count into consequences. Both are invented for the arithmetic, and the comments say so."
    }
  ]
}
```

```
PENDING bill
```

## The same meaning, twice the tokens

**The Portuguese costs 86 tokens where the English costs 41, a ratio of 2.10**, for sentences that
say the same thing in about the same number of characters. The first pair is the extreme: 7 tokens
in English, because every word of it is a whole entry, and 28 in Portuguese, three tokens for
every four characters. No merge the trainer learnt was about Portuguese, so `padeiro` falls back to small pieces
of English.

Look at the bytes column. `pão` is three characters and four bytes, because UTF-8 spends two bytes on
`ã`, and the byte-level tokenizer gives each of those bytes its own token. In the line that starts
`' pão'`, the two `�` are those halves: each is a byte that is not a character on its own, so it cannot be
printed alone.

The third pair is fairer, since neither sentence was in the corpus: 20 tokens against 30. **English
still wins, with no sentence to have memorised**, because the pieces it breaks into, ` the`, `er`,
` w`, are pieces the trainer saw constantly.

## What the ratio costs

The last two lines turn tokens into consequences with two invented numbers, and the program says
they are invented. With a context of 512 tokens, the model reads 37 of these English sentences at
once, and only 17 of the Portuguese ones. At a price of 2.00 per million tokens, a million English
sentences cost 27.33 and a million Portuguese ones 57.33. The numbers are made up, the ratio is not:
**whatever the price and whatever the context, both scale with the token count**, so a language the
tokenizer handles badly is read in smaller pieces and billed more for the same meaning.

The tokenizers of real language models are trained on far more text and in many languages, so their
gap between English and Portuguese is much smaller than this one. It is rarely zero, and this lesson
did not measure one, because the lab cannot download them. The way to know for your own text is the
one used here: encode a sample and count. Lesson 15's attention compares every token with every
other, so its cost grows with the square of the count, and a text twice as long in tokens is about
four times the work in that part of the model.
