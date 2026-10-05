---
title: Inside the model, step by step
version: 1
---

`model.encode` looks like one operation, and it is four: **cut the text into pieces, run the
transformer, average the pieces, scale the average to length 1.** sentence-transformers runs them as
a short list of modules, a transformer with its tokenizer, a pooling module and a normalising one;
`minilm.py` does the same with onnxruntime.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"The four steps inside all-MiniLM-L6-v2 for the title When your refund arrives, in a batch with a longer title. The text is cut into ten word pieces: [CLS], when, your, ref, ##und, arrives, [SEP] and three [PAD]. Six transformer layers turn each position into a vector of 384 numbers. The attention mask is 1 for the seven real pieces and 0 for the three padding positions. The seven real vectors are averaged, the average is divided by its length, and the result is one vector of 384 numbers with length 1.\"><defs><marker id=\"pipeen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"pipeen-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"150\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">text</text><rect x=\"168\" y=\"10\" width=\"545\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440.5\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">When your refund arrives</text><text x=\"150\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">word pieces</text><rect x=\"168\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"193\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[CLS]</text><rect x=\"223\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"248\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">when</text><rect x=\"278\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"303\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">your</text><rect x=\"333\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ref</text><rect x=\"388\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"413\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">##und</text><rect x=\"443\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"468\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">arrives</text><rect x=\"498\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"523\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[SEP]</text><rect x=\"553\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"578\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">[PAD]</text><rect x=\"608\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"633\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">[PAD]</text><rect x=\"663\" y=\"62\" width=\"50\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"688\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">[PAD]</text><text x=\"150\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">6 transformer layers</text><rect x=\"168\" y=\"106\" width=\"545\" height=\"36\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"440.5\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every piece adjusts to the real pieces</text><text x=\"150\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one vector per piece</text><path d=\"M193 142 L193 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"185\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M248 142 L248 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"240\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M303 142 L303 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"295\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M358 142 L358 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"350\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M413 142 L413 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"405\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M468 142 L468 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"460\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M523 142 L523 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"515\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M578 142 L578 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"570\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M633 142 L633 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"625\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><path d=\"M688 142 L688 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"680\" y=\"162\" width=\"16\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"150\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">attention mask</text><text x=\"193\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"248\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"303\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"358\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"413\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"468\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"523\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"578\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"633\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"688\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><path d=\"M181.0 246 L181.0 254 L535.0 254 L535.0 246\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M358 254 L358 280\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah1)\"></path><rect x=\"208\" y=\"282\" width=\"190\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"303\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mean of the 7 real vectors</text><path d=\"M398 298 L430 298\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"432\" y=\"282\" width=\"150\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">divide by the length</text><path d=\"M582 298 L608 298\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"610\" y=\"282\" width=\"108\" height=\"32\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"664\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">384 numbers</text><text x=\"664\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">length 1</text></svg>", "caption": "What encode does to one title in a batch of two. The padding gets vectors like any other position, and the mask is what keeps them out of the average."}
```

The program below does all four by hand on two titles of different lengths, so that the batch
needs padding, and then checks its answer against `minilm.py` and against Chroma's own
implementation of the same model.

```schooling-example
{
  "language": "python",
  "file": "inside.py",
  "parts": [
    {
      "code": "import os\nimport numpy as np\nimport onnxruntime\nfrom tokenizers import Tokenizer\nfrom chromadb.utils.embedding_functions import DefaultEmbeddingFunction\nimport minilm\n\nDIR = os.environ[\"MINILM_DIR\"]\ntexts = [\"When your refund arrives\", \"A parcel marked as delivered that never arrived\"]",
      "note": "The model's files are in `MINILM_DIR`. Two titles of different lengths, so that one has to be padded."
    },
    {
      "code": "tok = Tokenizer.from_file(os.path.join(DIR, \"tokenizer.json\"))\ntok.enable_truncation(256)\ntok.enable_padding(pad_id=0, pad_token=\"[PAD]\")\nenc = tok.encode_batch(texts)\nprint(enc[0].tokens)\nprint(enc[0].attention_mask)\nids = np.array([e.ids for e in enc], dtype=np.int64)\nmask = np.array([e.attention_mask for e in enc], dtype=np.int64)",
      "note": "Step 1. Load the tokenizer, cut at 256 pieces and pad to the longest text in the batch. Print the first title's pieces and its attention mask."
    },
    {
      "code": "model = onnxruntime.InferenceSession(os.path.join(DIR, \"model.onnx\"))\nhidden = model.run(None, {\"input_ids\": ids, \"attention_mask\": mask,\n                          \"token_type_ids\": np.zeros_like(ids)})[0]\nprint(\"one vector per piece:\", hidden.shape)",
      "note": "Step 2. Run the transformer. It returns one vector of 384 numbers for every position of every text."
    },
    {
      "code": "m = mask[:, :, None].astype(np.float32)\npooled = (hidden * m).sum(axis=1) / m.sum(axis=1)\nnaive = hidden.mean(axis=1)\nprint(\"pooled:\", pooled.shape)",
      "note": "Step 3. Mean pooling: zero the padding rows with the mask and divide by the number of real pieces. `naive` averages every row, padding included, for comparison."
    },
    {
      "code": "v = pooled / np.linalg.norm(pooled, axis=1, keepdims=True)\nn = naive / np.linalg.norm(naive, axis=1, keepdims=True)\nprint(\"padding averaged in, first text:\", round(float(v[0] @ n[0]), 4))",
      "note": "Step 4. Divide each vector by its length. Then compare the masked result with the naive one for the first, padded title."
    },
    {
      "code": "chroma = np.array(DefaultEmbeddingFunction()(texts))\nprint(\"largest difference from minilm.py:\", np.abs(v - minilm.embed(texts)).max())\nprint(\"largest difference from Chroma:   \", np.abs(v - chroma).max())",
      "note": "The result against `minilm.py` and against Chroma's own implementation of the same model."
    }
  ],
  "output": "ana@lab:~/emb$ python inside.py\n['[CLS]', 'when', 'your', 'ref', '##und', 'arrives', '[SEP]', '[PAD]', '[PAD]', '[PAD]']\n[1, 1, 1, 1, 1, 1, 1, 0, 0, 0]\none vector per piece: (2, 10, 384)\npooled: (2, 384)\npadding averaged in, first text: 0.9189\nlargest difference from minilm.py: 0.0\nlargest difference from Chroma:    1.4901161e-08"
}
```

## Pieces, and the mask that marks the padding

The tokenizer split *When your refund arrives* into **word pieces**: lower-cased, with *refund* cut
into `ref` and `##und` because the vocabulary of 30,522 pieces has no single entry for it. The
`##` says the piece continues a word. `[CLS]` and `[SEP]` mark the start and the end of every text.

A batch is one rectangular array, so the shorter title was filled out with `[PAD]` to the length of
the longer one: ten positions, of which three are padding. The **attention mask** under the pieces
is 1 for a real piece and 0 for padding. The transformer reads it so that no piece attends to the
padding, and the next step reads it again.

## One vector per piece, then one per text

The transformer returned an array of shape `(2, 10, 384)`: for each of the two texts, a vector of
384 numbers for each of the ten positions, padding included. Each has been through six layers in
which every piece adjusts to the others, which is what lesson 1 called contextual.

**Mean pooling** turns ten vectors into one by averaging them, and the mask decides which of the ten
count. Multiplying by the mask zeroes the padding rows, and dividing by the mask's sum divides by
the number of real pieces, seven here, rather than by ten. The line that skips the mask and averages
all ten gives a vector whose dot product with the right one is 0.9189 after normalising. That is
close, and it is wrong by a different amount for every text, depending on how much padding its batch
happened to give it. The bug changes a search result only when a short text shares a batch with a
long one.

**Normalising** divides each pooled vector by its length. The model card's own example does it, and
it is what lets every comparison in this course be a dot product.

## The same answer three ways

The vectors made by hand are identical to `minilm.py`'s, a largest difference of `0.0`, because
they are the same arithmetic. Against Chroma's `DefaultEmbeddingFunction` the largest difference is
`1.4901161e-08`, a difference in the last digits a float32 holds. Chroma pads every text to 256
positions rather than to the longest in the batch, and arithmetic done in a different order rounds
differently in the last place; the mask keeps the padding itself out of the result.

That last check is the habit worth keeping. **When you run a model outside the library it was
published with, compare a few vectors with a reference implementation** before trusting the rest.
A pooling step left out, or a missing normalisation, produces vectors that look perfectly
reasonable and rank slightly wrong.
