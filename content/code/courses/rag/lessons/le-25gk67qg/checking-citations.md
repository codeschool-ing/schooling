---
title: Checking citations
version: 2
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
      "code": "import re\n\nfrom vectors import embed\n\nCLOSE = 0.75\nnorm = lambda t: \" \".join(t.split())",
      "note": "`CLOSE` is the similarity above which a sentence counts as a fair rendering of a source sentence. It is a judgement, and 0.75 is this course's."
    },
    {
      "code": "def claims(reply):\n    \"\"\"(sentence, source number or None) for every sentence of a reply. A model told to cite like\n    [1] may put the number anywhere: \"... [1]\", \"According to [1], ...\", \"[2] states that ...\".\"\"\"\n    out = []\n    for sentence in re.split(r\"(?<=[.!?\\]])\\s+(?=[A-Z])\", reply.strip()):\n        numbers = re.findall(r\"\\[(\\d+)\\]\", sentence)\n        if not numbers:\n            out.append((sentence, None))\n            continue\n        text = re.sub(r\"^According to (source )?\\[\\d+\\],?\\s*\", \"\", sentence)\n        text = norm(re.sub(r\"\\s*\\[\\d+\\]\", \"\", text))\n        out.append((text[:1].upper() + text[1:], int(numbers[0])))\n    return out",
      "note": "A reply split into sentences, each with the number of the source it cites, or `None` when it cites none. The instruction shows the number at the end, *like [1]*, and llama3.2:3b puts it wherever it likes: first, *According to [1], ...*, or in the middle, *[2] states that ...*. So the number is looked for anywhere in the sentence, the first one wins, and the numbers and the *According to* are taken out, with a capital put back, so that what is left can be looked for in the source."
    },
    {
      "code": "def check(reply, sources):\n    \"\"\"A verdict for every sentence: quoted, close, unsupported, uncited, no such source, or quoted\n    in another source than the one cited.\"\"\"\n    verdicts = []\n    for sentence, n in claims(reply):\n        if n is None:\n            verdicts.append((sentence, n, \"uncited\"))\n            continue\n        if not 0 < n <= len(sources):\n            verdicts.append((sentence, n, \"no such source\"))\n            continue\n        text = norm(sources[n - 1][\"text\"])\n        if norm(sentence) in text:\n            verdicts.append((sentence, n, \"quoted\"))\n            continue\n        elsewhere = [m for m, other in enumerate(sources, 1) if norm(sentence) in norm(other[\"text\"])]\n        if elsewhere:\n            verdicts.append((sentence, n, f\"in [{elsewhere[0]}], not [{n}]\"))\n            continue\n        parts = [p for p in re.split(r\"(?<=[.!?])\\s+\", text) if p]\n        best = float((embed(parts) @ embed(sentence)[0]).max())\n        verdicts.append((sentence, n, f\"close ({best:.2f})\" if best >= CLOSE else f\"unsupported ({best:.2f})\"))\n    return verdicts",
      "note": "For each sentence, in order of how cheap the test is: is it cited at all; does the source exist; is it quoted word for word; is it quoted word for word in a different source; and, last, is any sentence of the source close in meaning."
    }
  ]
}
```

## A reply with two mistakes in it

A checker has to be seen giving each of its verdicts before it is trusted with a model's reply. So
the reply below **was written by the course, not by any model**, to make two mistakes models make in
one place. It is checked against the real sources the search returned for the refund question:

```schooling-example
{
  "language": "python",
  "file": "made_up.py",
  "parts": [
    {
      "code": "from answer import sources_for\nfrom verify import check\n\n# A reply WRITTEN BY THE COURSE, not by any model, imitating two mistakes real\n# models make: a true sentence cited to the wrong source, and a sentence no\n# source says.\nreply = (\"We refund within three working days of the return reaching our warehouse. [2] \"\n         \"Your bank may take another five to ten days to show it. [1] \"\n         \"Refunds are always paid as store credit. [1]\")",
      "note": "The reply is written out by hand, so that every verdict the checker can give appears in one run."
    },
    {
      "code": "sources = sources_for(\"How long after my return arrives will I get the refund?\")\nfor n, s in enumerate(sources, 1):\n    print(f\"[{n}] {s['path']}\")\nfor sentence, n, verdict in check(reply, sources):\n    print(f\"{verdict:20} [{n}] {sentence}\")",
      "note": "The real sources the search returns for the refund question, and the checker's verdict on each sentence."
    }
  ]
}
```

```
ana@vm:~/rag$ python made_up.py
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

```schooling-example
{
  "language": "python",
  "file": "check_reply.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import answer\nfrom verify import check\n\nreply, sources = answer(sys.argv[1])\nprint(reply)\nfor sentence, n, verdict in check(reply, sources):\n    print(f\"  {verdict:18} [{n}] {sentence[:60]}\")",
      "note": "The model's own reply for a question, and the verdict on each of its sentences."
    }
  ]
}
```

```
ana@vm:~/rag$ python check_reply.py "How long after my return arrives will I get the refund?"
According to [1], the money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. This means that the refund processing time is at least 5-10 days after the return reaches the warehouse.

However, [2] states that the return window starts on the day the carrier records the parcel as delivered, not on the day you placed the order. This implies that the refund processing time may be shorter than 5-10 days, as it depends on when the carrier records the parcel as delivered.

To clarify, I would recommend checking the seller's policy, as mentioned in [3], as they may have a different return window and refund processing time.
  quoted             [1] The money goes back to the card or account you paid with, an
  uncited            [None] This means that the refund processing time is at least 5-10 
  unsupported (0.70) [2] However, states that the return window starts on the day the
  uncited            [None] This implies that the refund processing time may be shorter 
  unsupported (0.73) [3] To clarify, I would recommend checking the seller's policy, 
```

**One sentence is quoted and the other four fail**, which is the reply the last section read by eye,
now read by a program. The quote is the bank's five to ten days. The two conclusions the model drew,
*at least 5-10 days* and *may be shorter*, cite nothing. The return window, cited to `[2]` in the
middle of its sentence, scores 0.70 against the sentences of `[2]`, close to the line and under it.
It is a fair account of the source with the model's *However, states that* in front, and the checker
cannot see past the words. The advice to check the seller's policy scores 0.73 against `[3]`, which
says nothing of the kind.

Run over many replies, the same program gives a rate worth measuring. Lesson 8 calls that rate
**faithfulness** and measures it over the test set.

## What to do with a failed check

Three responses, from cheapest to most careful: **drop the sentence** that failed and show the rest;
**show the reply with a warning** on the sentence; or **regenerate**, asking the model again with the
failure pointed out. Which one depends on the use, and lesson 2's table applies: a legal assistant
should never show an unsupported sentence, a help centre can show a paraphrase marked *close*.
