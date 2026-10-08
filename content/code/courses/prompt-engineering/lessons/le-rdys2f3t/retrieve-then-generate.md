---
title: Retrieve, then generate
version: 2
---

A model asked about Café Aurora's Sunday hours will answer, fluently, with hours that sound right.
It has never read the café's handbook: the café was written for this course, and no model was
trained on it. **A model cannot know a document it never saw, and how you word the question does
not change that.** What changes it is putting the document's relevant lines in front of the model,
in the prompt, every time a question is asked. That is retrieval-augmented generation, RAG: retrieve
first, then generate.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A sequence of five boxes. The question goes to retrieve, which searches the handbook, six files, and returns the best passages. They go into the prompt, together with an instruction and the question itself. The prompt goes to the model, which writes from the sources, and the answer comes out citing source 1.\"><defs><marker id=\"rag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"155\" y=\"10\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"215\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the handbook, six files</text><path d=\"M215 54 L215 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><rect x=\"10\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the question</text><text x=\"70\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">on sundays?</text><rect x=\"155\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">retrieve</text><text x=\"215\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the best passages</text><rect x=\"300\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the prompt</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instruction, sources</text><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and the question</text><rect x=\"445\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"505\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"505\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">writes from</text><text x=\"505\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the sources</text><rect x=\"590\" y=\"90\" width=\"120\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the answer</text><text x=\"650\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00-12:00 [1]</text><path d=\"M130 128.0 L153 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M275 128.0 L298 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M420 128.0 L443 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M565 128.0 L588 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rag-ah)\"></path><path d=\"M70 166 L70 215 L360 215 L360 168\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#rag-ah)\"></path><text x=\"215\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the question goes in too</text></svg>", "caption": "Retrieve, then generate. The question is used twice: once to search the handbook, and again inside the prompt beside the passages the search found."}
```

Start with the half that does not need a model. `handbook/`, which lesson 4 had you make, is the
café's staff handbook, six short files, and every line of them is one passage:

```
ana@lab:~/pe$ ls handbook
allergens.md
deliveries.md
hours.md
loyalty.md
refunds.md
wifi.md
ana@lab:~/pe$ cat handbook/hours.md
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
```

`retrieve` takes a question and returns the passages that score highest against it, three by
default:

```
ana@lab:~/pe$ retrieve "when does the café open on sundays"
query words: caf open sundays
  2.94  hours.md       On Sundays it opens at 08:00 and closes at 12:00.
  2.51  hours.md       On public holidays the café follows the Sunday hours.
  2.07  hours.md       Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
```

The passage that answers the question came first. **Nothing in the search understood the
question**: it compared words, and the first line of the output shows which words it used.

## How the score is made

The formula is called BM25, and it is where most keyword search engines start. In plain words, a
passage scores for every word of the question it contains, and four rules decide how much:

- small, common words such as `when`, `does`, `the` and `on` are dropped before anything is
  counted, which is why only three query words are left;
- a word that appears in few passages counts for more than one that appears in many, because
  finding it says more about the passage. `sundays` is in one line of the handbook, so it alone
  gave the first passage 2.94;
- a word repeated in one passage counts for a little more each time, and less with every repeat;
- a long passage is discounted slightly, so a line does not win by being long.

Two details show in that output. `café` became `caf`, because this retriever only knows the
letters a to z and digits; it does that to the handbook too, so the two still match. And `open`
matched nothing, because the handbook only ever says `opens`: **to this search, two forms of one word are
two different words.** The second and third passages are there only because they contain `café`.

The scores are not percentages and have no fixed top. They only rank passages for one question, and
a score from one question means nothing beside a score from another.

## What happens next

Retrieval does not answer anything. It produces the evidence, and the model writes the answer from
it, which is the next section. That division tells you where to look: **when a RAG system gives a
wrong answer, the first question is whether the right passage was retrieved**, and that can be
checked without a model, by running the search on its own, as here.
