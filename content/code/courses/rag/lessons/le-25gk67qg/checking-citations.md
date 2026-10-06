---
title: Checking citations
version: 1
---

A citation is a claim: *this sentence comes from that source.* Like any claim a model makes, it can
be wrong, and unlike most, it can be checked mechanically, because both halves are text the program
has. `verify.py` checks every sentence of a reply against the source it cites:

```schooling-example
{
  "language": "python",
  "file": "verify.py",
  "parts": [
    {
      "code": "import re\n\nfrom minilm import embed\n\nCLOSE = 0.75\nnorm = lambda t: \" \".join(t.split())",
      "note": "`CLOSE` is the similarity above which a sentence counts as a fair rendering of a source sentence. It is a judgement, and 0.75 is this lab's."
    },
    {
      "code": "def claims(reply):\n    \"\"\"(sentence, source number or None) for every sentence of a reply.\"\"\"\n    out = []\n    for sentence in re.split(r\"(?<=[.!?\\]])\\s+(?=[A-Z])\", reply.strip()):\n        m = re.match(r\"(.*?)\\s*\\[(\\d+)\\]$\", sentence)\n        out.append((m.group(1), int(m.group(2))) if m else (sentence, None))\n    return out",
      "note": "A reply split into sentences, each with the number at its end, or `None` when it has none."
    },
    {
      "code": "def check(reply, sources):\n    \"\"\"A verdict for every sentence: quoted, close, unsupported, uncited, no such source, or quoted\n    in another source than the one cited.\"\"\"\n    verdicts = []\n    for sentence, n in claims(reply):\n        if n is None:\n            verdicts.append((sentence, n, \"uncited\"))\n            continue\n        if not 0 < n <= len(sources):\n            verdicts.append((sentence, n, \"no such source\"))\n            continue\n        text = norm(sources[n - 1][\"text\"])\n        if norm(sentence) in text:\n            verdicts.append((sentence, n, \"quoted\"))\n            continue\n        elsewhere = [m for m, other in enumerate(sources, 1) if norm(sentence) in norm(other[\"text\"])]\n        if elsewhere:\n            verdicts.append((sentence, n, f\"in [{elsewhere[0]}], not [{n}]\"))\n            continue\n        parts = [p for p in re.split(r\"(?<=[.!?])\\s+\", text) if p]\n        best = float((embed(parts) @ embed(sentence)[0]).max())\n        verdicts.append((sentence, n, f\"close ({best:.2f})\" if best >= CLOSE else f\"unsupported ({best:.2f})\"))\n    return verdicts",
      "note": "For each sentence, in order of how cheap the test is: is it cited at all; does the source exist; is it quoted word for word; is it quoted word for word in a different source; and, last, is any sentence of the source close in meaning."
    }
  ]
}
```

## A reply with two mistakes in it

extract-1 cannot make a citation mistake: it copies a sentence and appends the number of the source
it copied it from. So to see the checker catch something, the reply below **was written by the
course, not by any model**, to imitate two mistakes real models make. It is checked against the real
sources the search returned for the refund question:

```
ana@lab:~/rag$ python made_up.py
[1] Returns and refunds policy > Refunds
[2] Returns and refunds policy > The return window
[3] Returns and refunds policy > Items sold by marketplace sellers
in [1], not [2]      [2] We refund within three working days of the return reaching our warehouse.
close (0.79)         [1] Your bank may take another five to ten days to show it.
unsupported (0.50)   [1] Refunds are always paid as store credit.
```

**The first sentence is true and cited to the wrong source.** It is quoted word for word, but from
`[1]`, not `[2]`. This is the most convincing kind of error, because the sentence is right and a reader
who checks the claim, not the pointer, will be satisfied. The checker finds it because it looks for
the sentence in every source, not only in the cited one.

**The second is a fair paraphrase.** *Your bank may take another five to ten days to show it* is part
of a longer sentence in `[1]`, and its similarity to that sentence is 0.79, above the 0.75 the checker
treats as close. A model that paraphrases instead of quoting produces sentences like this all the
time, and a check that only accepted exact quotes would flag every one.

**The third is not in any source.** *Refunds are always paid as store credit* is a plausible sentence,
close to the gift card rule, and false for every order paid by card. Its best similarity to the cited
source is 0.50, and the checker marks it unsupported.

## The same check on a real reply

```
ana@lab:~/rag$ python check_reply.py "How long after my return arrives will I get the refund?"
We refund within three working days of the return reaching our warehouse. [1] Every seller must accept returns for at least 14 days from delivery, and many accept them for longer. [3] If a seller does not answer a return request within two working days, open a claim from the order and we decide it. [3]
  quoted             [1] We refund within three working days of the return reaching o
  quoted             [3] Every seller must accept returns for at least 14 days from d
  quoted             [3] If a seller does not answer a return request within two work
```

All three of extract-1's sentences are quoted, which is what copying sentences guarantees. Run on a
real model's replies, the same program finds the cases above at a rate worth measuring; lesson 8 calls
that rate **faithfulness** and measures it over the test set.

## What to do with a failed check

Three responses, from cheapest to most careful: **drop the sentence** that failed and show the rest;
**show the reply with a warning** on the sentence; or **regenerate**, asking the model again with the
failure pointed out. Which one depends on the use, and lesson 2's table applies: a legal assistant
should never show an unsupported sentence, a help centre can show a paraphrase marked *close*.
