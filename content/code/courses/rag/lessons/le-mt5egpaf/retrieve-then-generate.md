---
title: Retrieve, then generate
version: 2
---

**Retrieval-augmented generation**, RAG, is the name for the arrangement the last section arrived at:
before the model answers, a search finds the passages most likely to contain the answer, and only
those go into the prompt. The model is the same model. What changes is that it reads three relevant
pages instead of none, or instead of all of them.

The name was coined in a 2020 paper by Lewis and others, which trained the retriever and the
generator together. Almost nobody does that now. In practice "RAG" means any system where a search
runs first and a model writes from its results, and that is what it means in this course.

## The two halves

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" aria-label=\"Two rows. Once, and again whenever a document changes: documents are cut into chunks, each chunk is embedded, and the vectors are stored in an index. Every time somebody asks: the question goes to search, which reads the index and returns the nearest chunks; they go into a prompt with the question; the generator reads the prompt and writes an answer that cites its sources.\"><defs><marker id=\"rg-3e47fd\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">once, and again whenever a document changes</text><rect x=\"20\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">documents</text><text x=\"100.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">policies, terms, manuals</text><path d=\"M180 75 L201 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"205\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">chunks</text><text x=\"285.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pieces small enough</text><path d=\"M365 75 L386 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"390\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">embeddings</text><text x=\"470.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one vector each</text><path d=\"M550 75 L571 75\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"575\" y=\"44\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">index</text><text x=\"655.0\" y=\"84.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vectors and text</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">every time somebody asks</text><rect x=\"20\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">question</text><text x=\"100.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what was asked</text><path d=\"M180 201 L201 201\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"205\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">search</text><text x=\"285.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nearest chunks</text><path d=\"M365 201 L386 201\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"390\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">prompt</text><text x=\"470.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sources + question</text><path d=\"M550 201 L571 201\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"575\" y=\"170\" width=\"160\" height=\"62\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"193.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">generator</text><text x=\"655.0\" y=\"210.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reads, then writes</text><path d=\"M655 106 L325 166\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#rg-3e47fd)\"></path><text x=\"470\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">search reads the index</text><path d=\"M655 232 L655 270\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-3e47fd)\"></path><rect x=\"370\" y=\"274\" width=\"380\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">an answer that cites its sources</text></svg>", "caption": "Retrieve, then generate. The top row runs before anybody asks anything; the bottom row runs for every question, and only the chunks the search returns reach the generator."}
```

The top row is **indexing**, and it happens before anybody asks anything: the documents are cut into
pieces, every piece is turned into a vector by an embedding model, and the vectors are stored with
their text in an index. It runs again when a document changes, never when a question arrives.

The bottom row is the **query**, and it happens for every question: the question is embedded with
the same model, the index returns the pieces whose vectors are nearest, those pieces go into a prompt
with the question, and the generator writes the answer, citing the pieces by number.

`embeddings-vectors` built most of the top row and the search: embedding, distance, vector databases
and their indexes. This course takes those as given and spends its time on what they do not answer.
How to cut a document so that the right piece exists to be found is lesson 4. What to store beside
each vector is lesson 5. How to search better than nearest-first is lesson 6, and how to make the
generator use and cite what it found is lesson 7. Whether any of it worked is lesson 8.

## The smallest version that works

`tiny_rag.py` is all of it in twenty-odd lines: sections cut at headings, embedded in memory, the
best three by cosine similarity, and a prompt.

```schooling-example
{
  "language": "python",
  "file": "tiny_rag.py",
  "parts": [
    {
      "code": "import glob\nimport re\nimport sys\n\nfrom vectors import embed\nfrom openai import OpenAI",
      "note": "Three imports: `embed` from the `vectors.py` of the setup, and the OpenAI client."
    },
    {
      "code": "# 1. Cut every document into its sections, at each \"## \" heading.\nsections = []\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    doc = path.split(\"/\")[-1][:-3]\n    for part in re.split(r\"\\n(?=## )\", open(path).read())[1:]:\n        heading = part.splitlines()[0][3:]\n        sections.append((f\"{doc} > {heading}\", part))",
      "note": "Retrieval needs pieces smaller than a document. The cheapest cut is at each `## ` heading, and each piece is named after its document and its heading, so a reader can tell where it came from. Lesson 4 is about doing this properly."
    },
    {
      "code": "# 2. Embed them once, and the question every time.\nvectors = embed([text for _, text in sections])\nquestion = sys.argv[1]\nscores = vectors @ embed(question)[0]",
      "note": "Every section becomes a vector once. The question becomes one each time it is asked, and one matrix product gives its cosine similarity to all of them, because `embed` returns vectors of length 1."
    },
    {
      "code": "# 3. Keep the best three.\nbest = scores.argsort()[::-1][:3]\nfor rank, i in enumerate(best, 1):\n    print(f\"[{rank}] {scores[i]:.3f}  {sections[i][0]}\")",
      "note": "The three most similar sections, printed with their scores so the choice can be seen."
    },
    {
      "code": "# 4. Put only those in the prompt, numbered, and ask.\nsources = \"\".join(f\"[{rank}] {sections[i][0]}\\n{sections[i][1]}\\n\" for rank, i in enumerate(best, 1))\nreply = OpenAI().chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[\n        {\"role\": \"system\", \"content\": \"Answer from the sources and cite them by number.\"},\n        {\"role\": \"user\", \"content\": f\"{sources}Question: {question}\"},\n    ],\n)\nprint(reply.choices[0].message.content)",
      "note": "Only those three go into the prompt, numbered `[1]` to `[3]`, followed by the question. Everything else in the corpus stays out."
    }
  ],
  "output": "ana@vm:~/rag$ python tiny_rag.py \"How many days do I have to return a printed book?\"\n[1] 0.810  returns-policy > The return window\n[2] 0.807  returns-policy-2025 > Returning a book\n[3] 0.744  returns-policy > Damaged, faulty and wrong items\nAccording to the provided sources, you have 30 days from delivery to return a printed book.\nana@vm:~/rag$ python tiny_rag.py \"How much is express delivery?\"\n[1] 0.698  shipping-and-delivery > Delivery options and costs\n[2] 0.544  shipping-and-delivery > Addresses\n[3] 0.463  shipping-and-delivery > Parcels that are late or lost\nAccording to [1], the cost of express delivery is 9.90."
}
```

**The question about express delivery found the right section first**, with a similarity of 0.698
against 0.544 for the next. That is retrieval working: out of all the sections in the corpus, the one
with the price table came first, without the question needing to match the section word for word.

```
ana@vm:~/rag$ cat data/docs/*.md | grep -c "^## "
92
```

Ninety-two sections, one heading each, and the search put the right one on top.

Both answers are right this time, and that is worth reading slowly too, because of what made them
right.

The express question got the price, `9.90`, out of the section's table, with the citation `[1]`.
The return question got thirty days. **Look at what the search put second for it**: the 2025 policy's
*Returning a book*, the rule that was replaced, at 0.807 against 0.810. It is about exactly the same
thing, so it scores almost exactly the same, and nothing in the pipeline knows that one of the two
is out of date. The model happened to take its answer from the first source. Given the two the other
way round, or a question worded slightly differently, nothing would have stopped it taking the
fourteen days of the second, and the next section shows a question where that is what happens.

The point here is the shape: **a retrieval system is a search engine and a writer, and each can fail
while the other succeeds.** A right answer built on a search that also returned the wrong policy is a
right answer by luck. Telling the two halves apart is most of the work of making one good, and it is
why lesson 8 measures them separately.
