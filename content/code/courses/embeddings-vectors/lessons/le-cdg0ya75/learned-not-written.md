---
title: Learned, not written
version: 1
---

Nobody wrote down that *money back* goes near *refund*. The model learned it, from examples, and
how it learned decides what it can and cannot do.

## Trained on pairs

A sentence embedding model is trained on **pairs of texts that belong together**: a question and
its accepted answer, a title and its article, two captions of the same photograph, a sentence and
its paraphrase. Training pulls the vectors of each pair together and pushes them away from the
vectors of the other texts in the same batch. This is called **contrastive** training, because
every step contrasts a right partner with many wrong ones.

After enough pairs, the model has to place *money back* near *refund*, because in its training data
the two kept turning up on both sides of matching pairs. It never saw a definition of either. It
saw which texts people put together.

Two consequences follow, and the rest of the course keeps meeting them.

- **The model knows what its training data knew.** all-MiniLM-L6-v2 was trained on English. The
  next section shows what it does with Portuguese.
- **Close means *close in the way the training pairs were close*.** If the pairs were questions and
  answers, a question lands near its answer. If they were paraphrases, a text lands near its
  restatement. Lesson 8 shows providers asking you which of those you are doing, for exactly this
  reason.

## Two ways to build the vector

All-MiniLM-L6-v2 is a **transformer**: it splits the text into pieces, gives each piece a starting
vector, and then runs six layers in which every piece looks at every other piece and adjusts its
own vector accordingly. Only after that are the pieces averaged into one vector. Each piece's final
vector depends on its neighbours, which is why this kind of model is called **contextual**.

The other model the course runs, **WordLlama**, skips the layers. Every token has one fixed vector,
learned in training, and the vector of a text is the average of its tokens' vectors. This kind is
called **static**. It is much smaller and much faster, and lesson 10 measures how much faster.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two pipelines side by side. Static, as in WordLlama: the five tokens of the dog bit the man are each looked up in a table of fixed vectors, and the five vectors are averaged into one vector of 256 numbers; order is lost. Contextual, as in all-MiniLM-L6-v2: the pieces get starting vectors, pass through six layers in which every piece attends to every other, and only then are averaged and normalised into one vector of 384 numbers.\"><defs><marker id=\"twoen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">static (WordLlama)</text><rect x=\"20\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"47\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M47 76 L47 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"82\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"109\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dog</text><path d=\"M109 76 L109 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"144\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bit</text><path d=\"M171 76 L171 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"206\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"233\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M233 76 L233 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"268\" y=\"50\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">man</text><path d=\"M295 76 L295 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"20\" y=\"102\" width=\"302\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">look up a fixed vector</text><path d=\"M322 117 L380 117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"382\" y=\"102\" width=\"110\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">average</text><path d=\"M492 117 L540 117\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"542\" y=\"102\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">256 numbers</text><text x=\"437\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">order is lost here</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">contextual (all-MiniLM-L6-v2)</text><rect x=\"20\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"47\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M47 236 L47 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"82\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"109\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dog</text><path d=\"M109 236 L109 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"144\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bit</text><path d=\"M171 236 L171 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"206\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"233\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the</text><path d=\"M233 236 L233 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"268\" y=\"210\" width=\"54\" height=\"26\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">man</text><path d=\"M295 236 L295 260\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"20\" y=\"262\" width=\"302\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"171\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">6 layers: every piece looks at the others</text><path d=\"M322 277 L380 277\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"382\" y=\"262\" width=\"110\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">average</text><path d=\"M492 277 L540 277\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#twoen-ah0)\"></path><rect x=\"542\" y=\"262\" width=\"130\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"607\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">384 numbers</text><text x=\"171\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">order shapes each vector here</text></svg>", "caption": "A static model averages fixed vectors, so the same words in any order give the same vector. A contextual model lets the pieces see each other before the average, which is how order gets in."}
```

The difference shows the moment word order matters:

```schooling-example
{
  "language": "python",
  "file": "order.py",
  "parts": [
    {
      "code": "from minilm import embed\nfrom wordllama import WordLlama\n\na, b = \"the dog bit the man\", \"the man bit the dog\"\nwl = WordLlama.load()",
      "note": "Two sentences with the same five words in a different order, and the static model loaded alongside the contextual one."
    },
    {
      "code": "m = embed([a, b])\nprint(\"minilm    \", round(float(m[0] @ m[1]), 4))",
      "note": "The contextual model's score for the pair."
    },
    {
      "code": "w = wl.embed([a, b], norm=True)\nprint(\"wordllama \", round(float(w[0] @ w[1]), 4))",
      "note": "The static model's score. `norm=True` asks WordLlama for unit-length vectors, so the dot product is comparable with the line above."
    },
    {
      "code": "print(wl.tokenizer.encode(a, add_special_tokens=False).tokens)",
      "note": "The tokens WordLlama averaged, without the marker it adds at the start."
    }
  ]
}
```

```
ana@lab:~/emb$ python order.py
minilm     0.9795
wordllama  1.0
['▁the', '▁dog', '▁bit', '▁the', '▁man']
```

**WordLlama scores the two sentences as identical, 1.0**, and by its own design it is right to.
The two sentences contain exactly the same five tokens, which the last line shows, and an average
does not care about order. All-MiniLM-L6-v2 sees a difference, 0.9795, because its layers let *dog* and
*man* know which side of *bit* they are on.

Notice how small that difference is. Even the contextual model scores *the dog bit the man* and
*the man bit the dog* as almost the same text, because they share all their words and their topic.
An embedding measures **what a text is about** far better than **what it asserts**, and that is the
subject of the next section.
