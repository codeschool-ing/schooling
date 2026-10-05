---
title: The limit nobody warns you about
version: 1
---

The obvious expectation is that a long text makes a vector of the whole text, perhaps a blurrier
one. **It does not. A transformer reads a fixed number of pieces and drops the rest, without an
error and without a warning.** all-MiniLM-L6-v2 reads 256 pieces, and two of those are `[CLS]` and
`[SEP]`, so 254 pieces of text are all a vector can ever describe.

None of the help centre's articles comes near that: the longest, measured below, is 102 pieces. The
bodies of the eight shipping articles joined into one text do:

```schooling-example
{
  "language": "python",
  "file": "length.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nfrom tokenizers import Tokenizer\nfrom chromadb.utils.embedding_functions import DefaultEmbeddingFunction\nfrom minilm import embed, pieces\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]"
    },
    {
      "code": "def count(h):\n    text = h[\"title\"] + \". \" + h[\"body\"]\n    return len(text.split()), len(pieces(text))\nfor h in sorted(help, key=lambda h: -count(h)[1])[:4]:\n    print(h[\"id\"], h[\"lang\"], \"%d words, %d pieces\" % count(h))\nlong = \" \".join(h[\"body\"] for h in help if h[\"category\"] == \"shipping\")\nprint(\"shipping bodies joined:\", len(pieces(long)), \"pieces\")",
      "note": "Words and pieces for each article, title and body together; print the four with the most pieces. Then join the bodies of the shipping articles into one long text."
    },
    {
      "code": "tok = Tokenizer.from_file(os.path.join(os.environ[\"MINILM_DIR\"], \"tokenizer.json\"))\ntok.no_truncation()\nstart, end = tok.encode(long).offsets[254]\nprint(\"the last piece read:\", repr(long[start:end]), \"in\", repr(long[end - 40:end + 30]))",
      "note": "A tokenizer with no limit, to find where the 254th piece of text falls. Index 0 is `[CLS]`, so index 254 is the last piece the model keeps."
    },
    {
      "code": "a = embed(long)\nb = embed(long + \" Every word after the limit is ignored, however important.\")\nc = embed(\"Refunds go back to the card you paid with. \" + long)\nprint(\"a sentence added at the end:  \", np.abs(a - b).max())\nprint(\"a sentence added at the start:\", np.abs(a - c).max())",
      "note": "The long text, the same text with a sentence after it, and the same text with a sentence before it. Print the largest difference from the original vector."
    },
    {
      "code": "chroma = np.array(DefaultEmbeddingFunction()([long]))\nprint(\"Chroma, same long text:\", chroma.shape, np.abs(chroma - a).max())",
      "note": "Chroma's embedding function, given the same long text."
    }
  ],
  "output": "ana@lab:~/emb$ python length.py\nh38 pt 48 words, 102 pieces\nh39 pt 44 words, 89 pieces\nh40 pt 44 words, 85 pieces\nh03 en 53 words, 65 pieces\nshipping bodies joined: 407 pieces\nthe last piece read: 'bent' in 'f a book arrives with a torn cover, bent corners or water damage, phot'\na sentence added at the end:   0.0\na sentence added at the start: 0.07395266\nChroma, same long text: (1, 384) 1.1920929e-07"
}
```

**The joined text is 407 pieces, and the model stopped reading at `bent`**, in
the middle of the article about damaged books. *corners or water damage, photograph* and everything
after it are not in the vector. A sentence added at the end changed nothing at all, a largest
difference of `0.0` in all 384 numbers. The same sentence added at the start moved the vector,
because its pieces took places inside the 254 and pushed as many pieces of the old text past the
cut.

So a search for *water damage* cannot find this text through its vector, whatever the text says.

**The three longest articles, in the first lines of the output, are the three Portuguese ones**, and
none of them is the longest in words. Article h38 has 48 words and 102 pieces; the longest English
article by pieces, h03, has 53 words and 65. A model with an English vocabulary breaks Portuguese
words into more and smaller pieces, so the same limit holds fewer words of another language.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Bars measured in word pieces. The eight shipping articles joined are 407 pieces; the model reads the first 254 of them, up to the word bent, and drops the other 153. Below, the longest single article, h38, in Portuguese, is 102 pieces for 48 words, and the longest English one, h03, is 65 pieces for 53 words.\"><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">shipping bodies joined</text><rect x=\"40\" y=\"42\" width=\"387\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"427\" y=\"42\" width=\"233.1\" height=\"34\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"233.5\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">read: 254 pieces</text><text x=\"543.6\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dropped: 153 pieces</text><path d=\"M427 30 L427 160\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"433\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the limit</text><text x=\"421\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">bent</text><rect x=\"40\" y=\"116\" width=\"155.4\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"201.4\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">102</text><text x=\"231.4\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h38, Portuguese, 48 words</text><rect x=\"40\" y=\"150\" width=\"99\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">65</text><text x=\"175\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">h03, English, 53 words</text><text x=\"40\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M40 184 L40 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"192.4\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M192.4 184 L192.4 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"344.8\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M344.8 184 L344.8 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"427\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">254</text><path d=\"M427 184 L427 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.1\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">300</text><path d=\"M497.1 184 L497.1 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"649.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">400</text><path d=\"M649.5 184 L649.5 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M40 184 L680 184\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660.2\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">407</text><text x=\"680\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">word pieces</text></svg>", "caption": "The model reads 254 pieces of text and the rest is not in the vector. The same limit holds fewer words of Portuguese, because an English vocabulary cuts Portuguese words into more pieces."}
```

## Who truncates, and who tells you

**`minilm.py` truncates silently**, because it does what sentence-transformers does: the library's
`max_seq_length` is 256 for this model, and its documentation says that longer input is truncated.
That is a reasonable default for a library and a dangerous one for a pipeline, because the place
where it bites is the long documents, and nothing in the output marks them.

**Chroma truncates silently too**, in the version this lab runs. Its embedding function has a check
that raises a `ValueError` for a text over 256 pieces. The last line of `length.py` shows it did not
fire: Chroma's tokenizer is set to cut at 256 before the check counts, so the check counts at most
256 and passes. The vector it returned matches `minilm.py`'s for the same long text to
`1.1920929e-07`, which is to say it is the same truncated vector.

## What to do about it

Count before you embed. `minilm.pieces(text)` gives every piece of a text, before the cut, and every
model's own tokenizer can do the same; a text over the limit is one to cut deliberately rather than
leave to the library. Lesson 3 cut long texts into chunks for search, and `rag` makes chunk size a
design decision. The limit is a property of each model, written on its card, and the next section is
about where to read it. Lesson 8's price sheet showed how far apart the providers' limits are.
