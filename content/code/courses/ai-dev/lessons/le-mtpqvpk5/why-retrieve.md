---
title: Why retrieve at all
version: 1
---

A support assistant for the shop has to answer from the shop's own rules: thirty days for a
return, 15.00 for shipping, what E1042 means. No model was trained on those, and lesson 1 section 11
showed what a model does with a question it was not trained on. **Retrieval-augmented generation
(RAG) puts the relevant rules into the request**, at the moment of the question, so the model
continues from the right text instead of reconstructing it.

::: track ai
You built this end to end in `rag`, with a real vector database and an evaluation set of hundreds
of questions. This lesson is the version a developer meets when the task is "add search to our
support page": small, with every part visible, and with the checks you should keep whatever the
size.
:::

::: track *
The whole technique is three steps, and this lesson builds each one in a few lines of Python:
find the passages that are relevant to the question, put them in the prompt, and check that the
answer uses them.
:::

## The handbook

The shop's support handbook is eight short Markdown files, written for the course like the rest of
the shop:

```
ana@dev:~/shop$ git add docs && git commit -qm "Support handbook" && ls docs/handbook && wc -w docs/handbook/*.md | tail -1
account.md
contact.md
coupons.md
payment-errors.md
products.md
returns.md
shipping.md
warranty.md
 793 total
ana@dev:~/shop$ python -c 'import tiktoken, pathlib; print(sum(len(tiktoken.get_encoding("o200k_base").encode(p.read_text())) for p in pathlib.Path("docs/handbook").glob("*.md")), "tokens in the handbook")'
993 tokens in the handbook
```

**993 tokens.** That is small enough to send whole with every question, and for a handbook this
size that would be a reasonable choice. Retrieval earns its place when the documents stop fitting,
or stop being cheap to send: a few hundred pages of policies, a product catalogue, every past
support ticket. Lesson 2's arithmetic decides where that line is for you, and this handbook is
small so that every step of the pipeline fits on a screen.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Retrieval-augmented generation in one picture. Ahead of time, the handbook is cut into 26 passages and each is embedded into an index. When a question arrives it is searched against the index, the top three passages go into the prompt with their ids, the model answers citing them, and a checker verifies the citations before the answer is shown.\"><defs><marker id=\"pl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">once, ahead of time</text><rect x=\"20\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">handbook</text><text x=\"80.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 files</text><rect x=\"180\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">passages</text><text x=\"240.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26, with ids</text><rect x=\"340\" y=\"34\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">index</text><text x=\"400.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">26 × 256</text><path d=\"M142 59 L176 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M302 59 L336 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">for every question</text><rect x=\"20\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">question</text><rect x=\"160\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">search</text><text x=\"220.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">top 3</text><rect x=\"300\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">prompt</text><text x=\"360.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passages + question</text><rect x=\"440\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">model</text><text x=\"500.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answer + [ids]</text><rect x=\"580\" y=\"136\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">check</text><text x=\"640.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">citations</text><path d=\"M142 161 L156 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M282 161 L296 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M422 161 L436 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M562 161 L576 161\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path><path d=\"M400 86 L400 110 L220 110 L220 132\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah)\"></path></svg>", "caption": "The top row runs when the documents change; the bottom row runs for every question. Lesson 6 builds each box."}
```

## Retrieval or training

The other way to give a model your knowledge is to train it further on your documents
(fine-tuning). For facts that change, retrieval wins on every count that matters here:

- **A change is an edit.** The return window changes in one file today and is in the next answer.
  A fine-tuned model knows the old window until somebody trains it again.
- **The answer can cite.** A passage has an id, so the answer can say where it came from, and a
  program can check it (lesson 6 section 08). Knowledge inside a model's parameters has no address.
- **What is not in the passages can be refused.** "The documents do not say" is a sentence a model
  can write when it was told to answer only from what it was given.

Fine-tuning is for changing how a model writes, its format or its tone, not for teaching it facts
that will change.
