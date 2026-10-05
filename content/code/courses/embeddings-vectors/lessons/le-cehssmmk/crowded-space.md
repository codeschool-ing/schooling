---
title: A crowded space
version: 1
---

A cosine runs from −1 to 1, so it is natural to read 0 as *unrelated*, 1 as *the same* and 0.4 as
*not very similar*. Measured on real texts, none of those readings holds. `crowded.py` scores every
pair of the 150 customer tickets in `data/tickets.jsonl`, with both of the course's models, and
puts a third set beside them: 150 random arrows in 384 dimensions.

```schooling-example
{
  "language": "python",
  "file": "crowded.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\ntickets = [json.loads(line) for line in open(\"data/tickets.jsonl\")]\ntexts = [t[\"text\"] for t in tickets]\nlabels = np.array([t[\"label\"] for t in tickets])\nupper = np.triu_indices(len(texts), 1)\nsame = (labels[:, None] == labels[None, :])[upper]",
      "note": "The 150 tickets and their labels. `triu_indices` picks each pair once, leaving out a ticket against itself, and `same` says which pairs share a label."
    },
    {
      "code": "rng = np.random.default_rng(0)\nnoise = rng.standard_normal((len(texts), 384))\nnoise /= np.linalg.norm(noise, axis=1, keepdims=True)\nmodels = {\"minilm\": embed(texts),\n          \"wordllama\": WordLlama.load().embed(texts, norm=True),\n          \"random\": noise}",
      "note": "Three sets of 150 unit vectors: MiniLM's, WordLlama's normalised, and random arrows in 384 dimensions with a fixed seed."
    },
    {
      "code": "print(f\"{len(same)} pairs, {same.sum()} of them with the same label\")\nprint(\"            5%  median    95%    max  same label  different  above 0.4\")\nfor name, V in models.items():\n    s = (V @ V.T)[upper]\n    p5, p50, p95 = np.percentile(s, [5, 50, 95])\n    print(f\"{name:9} {p5:6.3f} {p50:6.3f} {p95:6.3f} {s.max():6.3f}\"\n          f\"  {s[same].mean():10.3f} {s[~same].mean():10.3f} {(s > 0.4).mean():10.1%}\")",
      "note": "For each set, the 5th percentile, median, 95th percentile and maximum of all pair scores, the mean for pairs with the same label and with different labels, and the share above 0.4."
    },
    {
      "code": "bins = np.arange(-0.25, 1.0001, 0.05)\nfor name in (\"minilm\", \"wordllama\"):\n    V = models[name]\n    print(name, \" \".join(map(str, np.histogram((V @ V.T)[upper], bins)[0])))",
      "note": "The counts for the figure: how many pairs fall in each band of 0.05, from −0.25 to 1."
    }
  ]
}
```

```
ana@lab:~/emb$ python crowded.py
11175 pairs, 2175 of them with the same label
            5%  median    95%    max  same label  different  above 0.4
minilm    -0.004  0.158  0.415  0.934       0.277      0.151       6.0%
wordllama -0.061  0.076  0.305  0.893       0.173      0.073       1.8%
random    -0.083  0.000  0.085  0.216      -0.001      0.001       0.0%
minilm 0 0 7 122 494 1080 1640 1923 1793 1371 975 653 444 294 160 124 44 25 9 6 7 2 1 1 0
wordllama 3 24 144 560 1385 2216 2302 1787 1108 682 385 236 145 95 45 25 17 6 5 4 0 0 1 0 0
```

## A narrow band, and not around zero

**All 11,175 pairs of tickets crowd into a narrow band.** With all-MiniLM-L6-v2, the middle 90%
runs from −0.004 to 0.415 and the median is 0.158. Almost no pair is negative, and the highest of
11,175 is 0.934. With WordLlama the band is lower and just as narrow: −0.061 to 0.305, median
0.076.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A histogram of the cosine similarity of all 11,175 pairs among the 150 tickets, in bins of 0.05 from -0.25 to 1. The tallest MiniLM bar is the bin from 0.10 to 0.15; the tallest WordLlama bar is the bin from 0.05 to 0.10. Few pairs of either model score below 0, and very few above 0.5. A bracket near zero shows where 90% of the pairs of random 384-dimension vectors fall, between -0.083 and 0.085. A dashed line marks 0.4.\"><path d=\"M152.8 38 L236.2 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M152.8 33 L152.8 43\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M236.2 33 L236.2 43\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"194.5\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">90% of random pairs</text><path d=\"M70 191.7 L690 191.7\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"62\" y=\"191.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><path d=\"M70 83.3 L690 83.3\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"62\" y=\"83.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><text x=\"62\" y=\"300\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"62\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pairs</text><path d=\"M70 300 L690 300\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M94.8 300 L94.8 305\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"94.8\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-0.2</text><path d=\"M194 300 L194 305\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"194\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M293.2 300 L293.2 305\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"293.2\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M392.4 300 L392.4 305\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"392.4\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M491.6 300 L491.6 305\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"491.6\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M590.8 300 L590.8 305\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"590.8\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M690 300 L690 305\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"690\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><text x=\"380\" y=\"340\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">cosine similarity between two tickets</text><rect x=\"82.9\" y=\"299.7\" width=\"10.9\" height=\"0.3\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"107.7\" y=\"297.4\" width=\"10.9\" height=\"2.6\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"120.6\" y=\"299.2\" width=\"10.9\" height=\"0.8\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"132.5\" y=\"284.4\" width=\"10.9\" height=\"15.6\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"145.4\" y=\"286.8\" width=\"10.9\" height=\"13.2\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"157.3\" y=\"239.3\" width=\"10.9\" height=\"60.7\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"170.2\" y=\"246.5\" width=\"10.9\" height=\"53.5\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"182.1\" y=\"150\" width=\"10.9\" height=\"150\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"195\" y=\"183\" width=\"10.9\" height=\"117\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"206.9\" y=\"59.9\" width=\"10.9\" height=\"240.1\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"219.8\" y=\"122.3\" width=\"10.9\" height=\"177.7\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"231.7\" y=\"50.6\" width=\"10.9\" height=\"249.4\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"244.6\" y=\"91.7\" width=\"10.9\" height=\"208.3\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"256.5\" y=\"106.4\" width=\"10.9\" height=\"193.6\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"269.4\" y=\"105.8\" width=\"10.9\" height=\"194.2\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"281.3\" y=\"180\" width=\"10.9\" height=\"120\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"294.2\" y=\"151.5\" width=\"10.9\" height=\"148.5\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"306.1\" y=\"226.1\" width=\"10.9\" height=\"73.9\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"319\" y=\"194.4\" width=\"10.9\" height=\"105.6\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"330.9\" y=\"258.3\" width=\"10.9\" height=\"41.7\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"343.8\" y=\"229.3\" width=\"10.9\" height=\"70.7\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"355.7\" y=\"274.4\" width=\"10.9\" height=\"25.6\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"368.6\" y=\"251.9\" width=\"10.9\" height=\"48.1\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"380.5\" y=\"284.3\" width=\"10.9\" height=\"15.7\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"393.4\" y=\"268.1\" width=\"10.9\" height=\"31.9\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"405.3\" y=\"289.7\" width=\"10.9\" height=\"10.3\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"418.2\" y=\"282.7\" width=\"10.9\" height=\"17.3\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"430.1\" y=\"295.1\" width=\"10.9\" height=\"4.9\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"443\" y=\"286.6\" width=\"10.9\" height=\"13.4\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"454.9\" y=\"297.3\" width=\"10.9\" height=\"2.7\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"467.8\" y=\"295.2\" width=\"10.9\" height=\"4.8\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"479.7\" y=\"298.2\" width=\"10.9\" height=\"1.8\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"492.6\" y=\"297.3\" width=\"10.9\" height=\"2.7\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"504.5\" y=\"299.4\" width=\"10.9\" height=\"0.6\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"517.4\" y=\"299\" width=\"10.9\" height=\"1\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"529.3\" y=\"299.5\" width=\"10.9\" height=\"0.5\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"542.2\" y=\"299.4\" width=\"10.9\" height=\"0.6\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"554.1\" y=\"299.6\" width=\"10.9\" height=\"0.4\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"567\" y=\"299.2\" width=\"10.9\" height=\"0.8\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"591.8\" y=\"299.8\" width=\"10.9\" height=\"0.2\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"616.6\" y=\"299.9\" width=\"10.9\" height=\"0.1\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"628.5\" y=\"299.9\" width=\"10.9\" height=\"0.1\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"641.4\" y=\"299.9\" width=\"10.9\" height=\"0.1\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M392.4 36 L392.4 300\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"398.4\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">0.4</text><rect x=\"500\" y=\"66\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"518\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><rect x=\"500\" y=\"90\" width=\"12\" height=\"12\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"518\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">WordLlama</text></svg>", "caption": "Every pair of the 150 tickets, scored by each model. Neither uses the range from -1 to 1: the scores crowd into a band just above zero, and each model's band sits in a different place."}
```

The random arrows show what *unrelated* looks like in this space. In 384 dimensions, two arrows
pointing anywhere at all are almost perpendicular: 90% of the random pairs fall between −0.083 and
0.085, around a median of 0.000. The tickets do not spread out like that. Every one of them is
customer English about a bookshop, so all their arrows lean into the same region, and even two
tickets with different labels score 0.151 on average with MiniLM. The difference between related
and unrelated is a difference **inside the band**: 0.277 on average for two tickets with the same
label against 0.151 for two with different ones.

## What a score of 0.4 means

**For all-MiniLM-L6-v2, 0.4 is high**: only 6.0% of the pairs score above it. For WordLlama the
same 0.4 is rarer still, 1.8% of the pairs. The number is the same and the meaning is not, so three
things follow.

- **A score is not a probability.** 0.4 does not mean a 40% chance that two texts are related. It
  is a position in a band whose width and place belong to one model.
- **A threshold does not travel.** A cut-off chosen for one model is wrong for another, and wrong
  again for the same model on a different kind of text, where the band moves. Lesson 16 chooses
  one from your own data.
- **Scores are not comparable across models.** 0.30 from WordLlama is a stronger match than 0.30
  from MiniLM.

What does hold within one model and one collection is the **order**: the article with the higher
score is the closer one. Lesson 3 builds the search on that, and judges it by where the right
answer lands in the ranking, never by the size of its score.
