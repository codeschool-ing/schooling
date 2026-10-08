---
title: Placement
version: 2
---

Once the sources are chosen, they still have to be written in some order, and so do the instructions
and the question around them. Lesson 7's prompt wrote the sources best first, which is the order the
search returned and the one nobody has to think about. Whether it is the best order is a property of
the model, not of the pipeline, and **this course does not measure it**. With three sources, most
of the time, there is hardly a middle for a source to be lost in, and thirty questions could not
tell a small effect from chance.

The measurement that exists is the one quoted two sections ago. *Lost in the Middle* found that the
models it tested used a relevant passage best when it was at the beginning or at the end of their
input, and worst when it was in the middle, and the effect grew with the number of passages around
it. The usual response is an order that puts the strongest sources at the two ends and lets the
weakest fill the middle:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Five source boxes in the order ends() writes them into the prompt: rank 1, rank 3, rank 5, rank 4, rank 2. The two strongest sit at the start of the prompt and next to the question; the weakest sits in the middle.\"><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">five sources, numbered by their rank in the search</text><rect x=\"30\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"86.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rank 1</text><text x=\"86.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">place 1</text><rect x=\"160\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"216.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rank 3</text><text x=\"216.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">place 2</text><rect x=\"290\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"346.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rank 5</text><text x=\"346.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">place 3</text><rect x=\"420\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"476.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rank 4</text><text x=\"476.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">place 4</text><rect x=\"550\" y=\"60\" width=\"112\" height=\"54\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">rank 2</text><text x=\"606.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">place 5</text><path d=\"M30 134 L30 142 L662 142 L662 134\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"30\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">start of the prompt</text><text x=\"662\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">next to the question</text><text x=\"346.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the middle, where the weakest go</text></svg>", "caption": "The order ends() writes, and the one Haystack's LostInTheMiddleRanker writes too. It follows a measurement of other models; this course did not measure it on llama3.2:3b."}
```

`ends` in `context.py` writes that order, and Haystack ships the same idea as a component, the
`LostInTheMiddleRanker` named after the paper:

```schooling-example
{
  "language": "python",
  "file": "order.py",
  "parts": [
    {
      "code": "from context import ends\nfrom haystack import Document\nfrom haystack.components.rankers import LostInTheMiddleRanker\n\nranked = [\"first\", \"second\", \"third\", \"fourth\", \"fifth\"]\nprint(\"ends():              \", ends(ranked))\ndocs = [Document(content=name) for name in ranked]\nprint(\"LostInTheMiddleRanker:\", [d.content for d in LostInTheMiddleRanker().run(documents=docs)[\"documents\"]])",
      "note": "The order `ends` puts five ranked sources in, beside the order Haystack's `LostInTheMiddleRanker` uses for the same idea."
    }
  ]
}
```

```
ana@vm:~/rag$ python order.py
ends():               ['first', 'third', 'fifth', 'fourth', 'second']
LostInTheMiddleRanker: ['first', 'third', 'fifth', 'fourth', 'second']
```

**The two agree**: first, third, fifth, fourth, second. Given five sources ranked by the search, the
best goes first, the second best goes last, next to the question, and the fifth, the weakest, lands in
the middle.

## Instructions first, question last

The same research is the argument for the layout lesson 7 already used. The instructions go first,
in the system message, where the provider's API keeps them apart from everything the user sent. The
question goes last, right before the model starts writing, so the last thing it read is what it was
asked. The sources go in between, ordered as above. A prompt that puts the question first and then
three thousand tokens of sources asks the model to carry the question across all of them.

## What to do without a measurement

Nothing here makes `ends` right for a given model, and nothing makes it wrong; with three sources, as
this pipeline usually sends, the middle is a single place. The order is therefore a setting to test
on the deployment's real model, with lesson 8's test, before believing either way. What this lesson
can show is that changing it costs nothing: the same sources, the same tokens, a different sequence.
