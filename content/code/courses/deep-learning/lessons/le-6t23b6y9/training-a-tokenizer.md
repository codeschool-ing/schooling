---
title: Training a real tokenizer on the corpus
version: 1
---

**The `tokenizers` library does what `bpe.py` did, in Rust, with the details a real tokenizer
needs.** The main one is that it works on bytes rather than characters, so its starting vocabulary
is the 256 possible byte values and no text, in any language or alphabet, can ever fall outside it.
It trains on your own file, and nothing is downloaded. Save this as
`~/dl/tok.py`:

```schooling-example
{
  "language": "python",
  "file": "tok.py",
  "parts": [
    {
      "code": "\"\"\"tok: a byte-level BPE tokenizer trained on corpus.txt, at several vocabulary sizes.\"\"\"\nfrom tokenizers import Tokenizer, decoders, models, pre_tokenizers, trainers",
      "note": "`tokenizers` is the library lesson 1 installed. Nothing is downloaded here: the tokenizer is trained on your own file."
    },
    {
      "code": "def train(size):\n    tok = Tokenizer(models.BPE())\n    tok.pre_tokenizer = pre_tokenizers.ByteLevel(add_prefix_space=False)\n    tok.decoder = decoders.ByteLevel()\n    trainer = trainers.BpeTrainer(vocab_size=size, show_progress=False,\n                                  initial_alphabet=pre_tokenizers.ByteLevel.alphabet())\n    tok.train([\"corpus.txt\"], trainer)\n    return tok",
      "note": "Byte-level BPE. The pre-tokenizer cuts the text at spaces and punctuation and turns it into bytes, so the vocabulary starts as the 256 byte values and no text is ever unknown. `vocab_size` says when to stop merging."
    },
    {
      "code": "text = open(\"corpus.txt\").read()\nprint(f\"corpus: {len(text)} characters, {len(text.encode())} bytes\")\nfor size in [256, 300, 400, 500, 600, 800, 1000]:\n    tok = train(size)\n    n = len(tok.encode(text).ids)\n    print(f\"asked {size:4d}  learnt {tok.get_vocab_size():4d}  tokens {n:5d}  characters a token {len(text) / n:.2f}\")",
      "note": "The same corpus, trained at seven sizes, and the number of tokens it becomes under each."
    },
    {
      "code": "tok = train(500)\ntok.save(\"tok.json\")\nfor sentence in [\"On Monday the baker sells bread.\", \"On Sunday the weaver sells blankets.\"]:\n    enc = tok.encode(sentence)\n    print(len(enc.ids), \"tokens\", enc.ids)\n    print(\"  \", [tok.decode([i]) for i in enc.ids])",
      "note": "Size 500 is saved as `tok.json` for the rest of the lesson. `decode` of a single id shows the text that token stands for, its leading space included."
    }
  ]
}
```

```
PENDING tok
```

## Vocabulary size against length

At 256, the vocabulary is the bytes alone, and the corpus is 3,261 tokens, one per byte, exactly
the character count `split.py` printed: every character in it is plain ASCII, one byte each. Each
step up shortens the text: 1,886 tokens at 300, 1,002 at 500, 758 at 700.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 320\" role=\"img\" aria-label=\"Tokens the corpus becomes against the size of the vocabulary. From 256 single bytes to 700 tokens the count falls from 3261 to 758, quickly at first and then slowly; past 700 the trainer has nothing left to merge.\"><path d=\"M90 260 L600 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 260 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90.0 260 L90.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M175.0 260 L175.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"175.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">300</text><path d=\"M260.0 260 L260.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"260.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M345.0 260 L345.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"345.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">500</text><path d=\"M430.0 260 L430.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"430.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><path d=\"M515.0 260 L515.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"515.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">700</text><path d=\"M600.0 260 L600.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"600.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">800</text><path d=\"M85 260.0 L90 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M85 197.14285714285714 L90 197.14285714285714\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"197.14285714285714\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1000</text><path d=\"M85 134.28571428571428 L90 134.28571428571428\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"134.28571428571428\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2000</text><path d=\"M85 71.42857142857144 L90 71.42857142857144\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"81\" y=\"71.42857142857144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3000</text><text x=\"345.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">vocabulary size</text><text x=\"90\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tokens in the corpus</text><path d=\"M137.6 55.0 L515.0 212.4\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"137.6\" cy=\"55.022857142857134\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"145.6\" y=\"43.022857142857134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3261</text><circle cx=\"515.0\" cy=\"212.3542857142857\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><text x=\"523.0\" y=\"200.3542857142857\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">758</text><path d=\"M515.0 212.3542857142857 L600.0 212.3542857142857\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"464.0\" y=\"172.3542857142857\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">every word whole: nothing left to merge</text><text x=\"147.6\" y=\"57.022857142857134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">single bytes</text></svg>", "caption": "The more merges the tokenizer learns, the fewer tokens the same text becomes, until there is nothing left to merge."}
```

**The first merges buy the most.** Going from 256 to 300 entries removes 1,375 tokens; going from
600 to 700 removes 100. At 800 and 1,000 the trainer stops at 700 entries. The pre-tokenizer cut
the text at spaces and punctuation before any merging, a merge never crosses that cut, and by 700
every word of the corpus is already a single token. The 758 left are the words and punctuation marks
themselves.

Choosing the size is a trade with three sides. **A larger vocabulary gives shorter sequences**, and
each step of a model costs time per token. **It also gives a larger embedding table**, one row per
entry, which the next section shows is a block of parameters. And each entry is seen less often in
training, so a rare token's row learns from few examples. Language models settle somewhere in the
tens of thousands to a few hundred thousand entries; this lesson settles at 500 because its corpus
is one page.

## What a sentence becomes

The last lines are what the model would receive. `On Monday the baker sells bread.` is 7 tokens,
one per word and one for the full stop, with ids from 13 to 371. **The space belongs to the token
after it**: ` Monday` with its space is one entry, and `Monday` at the start of a line would be a
different one. That is how decoding puts spaces back without guessing.

`On Sunday the weaver sells blankets.` is 15. `Sunday` appears once in the corpus, too rarely to earn
a merge of its own at this size, so it comes out as ` S`, `u` and `nday`. `weaver` and `blankets` were
never in the corpus at all and break into four pieces each. **No `<unk>` anywhere**: the byte
alphabet at the bottom guarantees that, and the cost of a strange word is length, never a hole.

The ids themselves mean nothing. 288 is ` baker` because of the order in which this training run made its merges,
and a tokenizer trained on different text would number it differently. That is why a
model and its tokenizer are always shipped together, and why the next thing to explain is how a
network turns an arbitrary number into something it can compute with.
