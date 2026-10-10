---
title: Byte-pair encoding, by hand
version: 1
---

**Byte-pair encoding starts from single characters and glues together the pair that occurs most
often, again and again.** Each glued pair becomes a new entry in the vocabulary, and the list of
merges, in the order they were made, is the whole tokenizer. It was a compression trick from 1994
before it was a tokenizer, and nearly every language model today uses it or a close relative.

Five words, each with how often it was seen, are enough to watch it work. Save this as
`~/dl/bpe.py`:

```schooling-example
{
  "language": "python",
  "file": "bpe.py",
  "parts": [
    {
      "code": "\"\"\"bpe: byte-pair encoding by hand, on five words and how often each was seen.\"\"\"\nfrom collections import Counter\n\ncounts = {\"bake\": 5, \"baker\": 6, \"bakers\": 2, \"make\": 4, \"maker\": 3}\nwords = {w: list(w) for w in counts}",
      "note": "Five words and how often each was seen. Every word starts as a list of its letters, and those letters are the whole vocabulary BPE begins with."
    },
    {
      "code": "def pairs():\n    seen = Counter()\n    for w, pieces in words.items():\n        for a, b in zip(pieces, pieces[1:]):\n            seen[a, b] += counts[w]\n    return seen",
      "note": "Every pair of neighbouring pieces, counted. A pair inside a word seen six times counts six."
    },
    {
      "code": "def merge(pieces, a, b):\n    out, i = [], 0\n    while i < len(pieces):\n        if i + 1 < len(pieces) and pieces[i] == a and pieces[i + 1] == b:\n            out.append(a + b)\n            i += 2\n        else:\n            out.append(pieces[i])\n            i += 1\n    return out",
      "note": "Replace each occurrence of the pair `a`, `b` by the single piece `a + b`, reading left to right."
    },
    {
      "code": "merges = []\nfor step in range(1, 7):\n    (a, b), n = pairs().most_common(1)[0]\n    merges.append((a, b))\n    for w in words:\n        words[w] = merge(words[w], a, b)\n    print(f\"merge {step}: {a!r} + {b!r} seen {n:2d} times ->\", \" \".join(\"|\".join(p) for p in words.values()))",
      "note": "Six rounds of one rule: take the commonest pair, make it a piece, write it down. The list `merges`, in its order, is the tokenizer. A tie goes to the pair counted first."
    },
    {
      "code": "def encode(word):\n    pieces = list(word)\n    for a, b in merges:\n        pieces = merge(pieces, a, b)\n    return pieces",
      "note": "A new word starts as letters and goes through the merges in the order they were learnt."
    },
    {
      "code": "for new in [\"makers\", \"baked\", \"taker\"]:\n    print(f\"{new!r} was never seen ->\", encode(new))",
      "note": "Three words the five did not contain."
    }
  ]
}
```

```
PENDING bpe
```

## Reading the merges

**The first merge is `a` + `k`, seen 20 times**: it occurs once in each of the five words, and the
five words were seen 5 + 6 + 2 + 4 + 3 = 20 times. `k` + `e` was also seen 20 times, and the tie went
to the pair counted first. The second merge glues `ak` to `e`, and from then on the rule keeps
building on its own output: `bake` at merge 3, `baker` at merge 4, then `make` and `maker`.

Watch the counts fall: 20, 20, 13, 8, 7, 3. The early merges are pieces shared by many words, and
the late ones are whole words that are merely frequent. A real tokenizer runs the same loop tens of
thousands of times over gigabytes of text, and its late merges are rare words, names and pieces of
code.

## Words it never saw

**Encoding a new word replays the merges, in the order they were learnt.** `makers` was not among
the five, and it comes out as `maker` and `s`, two pieces the vocabulary has, which is exactly the
relationship a word vocabulary could not see. `baked` becomes `bake` and `d`.

`taker` shows the other side. No merge ever produced `ta`, so `t` stays alone, then `ake` and `r`
follow from merges 2 and 1. The word is still represented, with no `<unk>`, only in more pieces. That
is the general behaviour: **a word like the training text costs few tokens, and a word unlike it
costs many**, down to one per character. The bill for that arrives in the last section of this
lesson.

Nothing here knows what a baker is. The merges are frequencies, and `bake` became a piece because it
was common, not because it is a verb. Meaning comes later, from the model that reads the ids.
