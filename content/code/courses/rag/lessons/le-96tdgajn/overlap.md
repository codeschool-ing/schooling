---
title: Overlap
version: 1
---

If the trouble with fixed-size chunks is that a cut lands inside a sentence, one fix is to make sure
no sentence lives only at a cut. **Overlap** starts each chunk some words before the previous one
ended, so that the text around every boundary appears twice, once at the end of one chunk and once at
the start of the next.

```
ana@lab:~/rag$ python boundaries.py 60 15
20 chunks of 60 words, 15 overlapping
chunk 3 starts: has no writing, no broken spine and no missing ...
chunk 3 ends:   ... an email explaining why. The statutory right of withdrawal
chunk 4 starts: to you at our cost with an email explaining ...
chunk 4 ends:   ... choose Return items. 2. Select the books you are
chunk 5 starts: the order in your account and choose Return items. ...
chunk 5 ends:   ... at the post office counter instead. 4. Pack the
```

**Chunk 4 still ends in the middle of *Select the books you are*, and chunk 5 starts fifteen words
before that**, at *the order in your account*, so the whole instruction is inside chunk 5. The cut is
still there. It no longer matters, because there is a second copy of the text around it with no cut
in it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 740 310\" role=\"img\" aria-label=\"Two rows of chunks along words 130 to 340 of the returns policy. Without overlap, chunks of 60 words sit end to end, and the cut between chunk 3 and chunk 4, at word 240, falls inside the sentence Select the books you are sending back and a reason, so neither chunk holds it whole. With 15 words of overlap, each chunk starts 15 words before the previous one ended, and chunk 5 holds that sentence whole.\"><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">60 words, no overlap: every chunk starts where the last one ended</text><path d=\"M370.0 102 V108 H402.4 V102\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"30.0\" y=\"60\" width=\"159.9047619047619\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.95238095238095\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 2</text><rect x=\"191.9047619047619\" y=\"82\" width=\"192.2857142857143\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"289.04761904761904\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 3</text><rect x=\"386.1904761904762\" y=\"60\" width=\"192.28571428571428\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"483.33333333333337\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 4</text><rect x=\"580.4761904761905\" y=\"82\" width=\"127.52380952380952\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"645.2380952380952\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 5</text><text x=\"30\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">60 words, 15 overlapping: each chunk starts 15 words before the last one ended</text><path d=\"M370.0 214 V220 H402.4 V214\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"30.0\" y=\"172\" width=\"62.76190476190476\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"62.38095238095238\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 2</text><rect x=\"46.19047619047619\" y=\"194\" width=\"192.28571428571428\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"143.33333333333334\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 3</text><rect x=\"191.9047619047619\" y=\"172\" width=\"192.2857142857143\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"289.04761904761904\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 4</text><rect x=\"337.6190476190476\" y=\"194\" width=\"192.28571428571433\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"434.76190476190476\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 5</text><rect x=\"483.3333333333333\" y=\"172\" width=\"192.28571428571428\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"580.4761904761905\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">chunk 6</text><text x=\"94.76190476190476\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">word 150</text><text x=\"256.66666666666663\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">word 200</text><text x=\"418.57142857142856\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">word 250</text><text x=\"580.4761904761905\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">word 300</text><text x=\"386.1904761904762\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">\"Select the books you are sending back and a reason.\"</text></svg>", "caption": "The same 60-word chunks with and without overlap. The amber bracket marks words 235 to 244, one sentence: cut in two at word 240 when the chunks sit end to end, whole inside chunk 5 when each chunk starts 15 words early. Chunks are numbered from 0, as boundaries.py numbers them."}
```

## What it costs

The same policy now makes 20 chunks instead of 15. Each chunk is still 60 words, so a quarter of every
chunk is a repeat of its neighbour: the index holds a third more chunks, the embedding bill is a third
higher, and the search compares the question with a third more vectors. For a policy that is nothing;
for a corpus of millions of pages it is a third more storage and re-indexing time, the costs
`embeddings-vectors` lesson 18 measured.

It also changes what retrieval returns. Two neighbouring chunks share fifteen words, so a question
whose answer sits in the overlap can retrieve both, and the prompt then carries the same sentences
twice. Lesson 12 removes duplicates like that before the prompt is built.

## What it buys

The table at the end of this lesson measures every strategy against the 26 answerable questions of
the test set, counting a question as found when the sentence that answers it is inside one of the
three chunks retrieved. Two lines of it belong here:

| strategy | chunks | found |
| --- | --- | --- |
| fixed, 60 words | 116 | 21 of 26 |
| fixed, 60 words, 15 overlapping | 150 | 24 of 26 |

**Overlap found three more answers out of 26**, for 34 more chunks across the corpus. It is the
cheapest improvement fixed-size chunking can get, and the usual advice is an overlap of 10 to 20 per
cent of the chunk size. It is still a patch on a cut made without looking. The next section stops
making cuts like that.
