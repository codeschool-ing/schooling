---
title: The query pipeline, with the floor as a component
version: 2
---

Lesson 10 needed an `if` after the chain to refuse without calling the model. In Haystack the
natural place for that decision is a component of its own, and a component may declare more than
one output and fill only one of them per run:

```schooling-example
{
  "language": "python",
  "file": "hs_floor.py",
  "parts": [
    {
      "code": "from answer import REFUSAL\nfrom haystack import Document, component",
      "note": "The refusal sentence is lesson 7's."
    },
    {
      "code": "@component\nclass Floor:\n    \"\"\"Pass on the documents that reach lesson 6's floor, or the refusal if none does.\"\"\"",
      "note": "`@component` turns a class into a Haystack component: something with a `run` method and declared outputs."
    },
    {
      "code": "    def __init__(self, floor: float = 0.5):\n        self.floor = floor",
      "note": "The floor is a parameter, so it is written into the pipeline's file with the rest."
    },
    {
      "code": "    @component.output_types(documents=list[Document], refusal=str)\n    def run(self, documents: list[Document]):\n        kept = [d for d in documents if d.score >= self.floor]\n        return {\"documents\": kept} if kept else {\"refusal\": REFUSAL}",
      "note": "Two declared outputs, and each run fills only one of them. A component connected to `documents` runs only when documents come out; when the refusal comes out instead, nothing downstream runs and the model is never called."
    }
  ]
}
```

The rest of the pipeline is Haystack's own parts, with lesson 6's filter and lesson 7's prompt:

```schooling-example
{
  "language": "python",
  "file": "hs_ask.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import SYSTEM\nfrom haystack import Pipeline\nfrom haystack.components.builders import ChatPromptBuilder\nfrom haystack.components.embedders import OpenAITextEmbedder\nfrom haystack.components.generators.chat import OpenAIChatGenerator\nfrom haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever\nfrom haystack.dataclasses import ChatMessage\nfrom haystack.document_stores.in_memory import InMemoryDocumentStore\nfrom hs_floor import Floor",
      "note": "Lesson 7's instructions, and Haystack's text embedder, retriever, prompt builder and chat generator."
    },
    {
      "code": "store = InMemoryDocumentStore.load_from_disk(\"store.json\")\npublic = {\"operator\": \"AND\", \"conditions\": [\n    {\"field\": \"meta.status\", \"operator\": \"==\", \"value\": \"current\"},\n    {\"field\": \"meta.audience\", \"operator\": \"==\", \"value\": \"public\"}]}\nsources = (\"{% for d in documents %}[{{ loop.index }}] {{ d.meta.title }} (updated {{ d.meta.updated }})\\n\"\n           \"{{ d.content }}\\n\\n{% endfor %}Question: {{ question }}\")",
      "note": "The store the indexing program saved. Lesson 6's filter written in Haystack's own syntax, a field, an operator and a value. The prompt is a Jinja template that numbers the sources the way lesson 7 does."
    },
    {
      "code": "rag = Pipeline()\nrag.add_component(\"embed\", OpenAITextEmbedder(model=\"all-minilm\"))\nrag.add_component(\"retrieve\", InMemoryEmbeddingRetriever(store, top_k=3, filters=public))\nrag.add_component(\"floor\", Floor(0.5))\nrag.add_component(\"prompt\", ChatPromptBuilder(template=[ChatMessage.from_system(SYSTEM),\n                                                        ChatMessage.from_user(sources)],\n                                              required_variables=[\"documents\", \"question\"]))\nrag.add_component(\"generate\", OpenAIChatGenerator(model=\"llama3.2:3b\", generation_kwargs={\"temperature\": 0}))\nrag.connect(\"embed.embedding\", \"retrieve.query_embedding\")\nrag.connect(\"retrieve\", \"floor\")\nrag.connect(\"floor.documents\", \"prompt.documents\")\nrag.connect(\"prompt\", \"generate\")",
      "note": "Five components and four connections. Only `floor.documents` reaches the prompt, so the refusal path ends at the floor."
    },
    {
      "code": "if __name__ == \"__main__\":\n    question = sys.argv[1]\n    out = rag.run({\"embed\": {\"text\": question}, \"prompt\": {\"question\": question}},\n                  include_outputs_from={\"retrieve\"})\n    print(out[\"generate\"][\"replies\"][0].text if \"generate\" in out else out[\"floor\"][\"refusal\"])\n    for d in out[\"retrieve\"][\"documents\"]:\n        print(f\"  {d.score:.3f}  {d.meta['id']}\")",
      "note": "The question goes in twice, to be embedded and to be written into the prompt. `include_outputs_from` keeps what the retriever returned, so the scores can be printed even when the model is not called."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The query pipeline as a graph: embed, retrieve, floor, prompt and generate, connected left to right. The question enters twice, into embed and into prompt. From floor, documents go on to prompt, and the refusal leaves downwards without reaching the model; generate produces the reply.\"><defs><marker id=\"rg-73a4bd\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"26\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"78.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">embed</text><rect x=\"160\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"212.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">retrieve</text><rect x=\"294\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"346.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">floor</text><rect x=\"428\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">prompt</text><rect x=\"562\" y=\"130\" width=\"104\" height=\"46\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"614.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">generate</text><path d=\"M130 153.0 L158 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M264 153.0 L292 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M398 153.0 L426 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M532 153.0 L560 153.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><text x=\"26\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the question</text><path d=\"M78.0 58 L480.0 58\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M78.0 58 L78.0 128\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M480.0 58 L480.0 128\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><path d=\"M346.0 176 L346.0 236\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><text x=\"356.0\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the refusal, no model call</text><text x=\"356.0\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">refusal</text><text x=\"413.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">documents</text><path d=\"M614.0 176 L614.0 236\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rg-73a4bd)\"></path><text x=\"614.0\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the reply</text></svg>", "caption": "hs_ask.py as Haystack holds it: five named components and the connections between them. The floor has two outputs, and a run fills one; when it is the refusal, prompt and generate never run."}
```

The filter is written in Haystack's syntax rather than LangChain's dictionary: a list of conditions,
each a field, an operator and a value, joined by `AND`. The scores here are **similarities, where
higher is better**, like lesson 6's and unlike `PGVector`'s distances in lesson 10. The store
computes a dot product by default, which equals the cosine similarity for vectors of length 1, and
Ollama returns all-minilm's vectors with a length of 1.

```
ana@vm:~/rag$ python hs_ask.py "How many days do I have to return a printed book?"
According to sources [1] and [2], you have 30 days from delivery to return a printed book in the condition you received it.

However, source [3] states that you have 7 days from delivery to withdraw from a purchase without giving a reason, as the consumer protection law guarantees. This period is extended to 30 days for printed books by our returns and refunds policy, as stated in sources [1] and [2]. 

Since source [3] is outdated (updated 2026-01-05) and source [1] and [2] are more recent (updated 2026-02-02), we prefer the more recent sources. Therefore, you have 30 days from delivery to return a printed book.
  0.787  returns-policy
  0.787  returns-policy
  0.733  terms-of-sale
```

The reply is right, 30 days from the current policy, and it carries the previous section's
duplicate. **The first two sources are the same chunk with the same score, 0.787**: the copy with
the old owner and the copy with the new one, both current, both public, and both returned. The model
cited the one sentence to both, *sources [1] and [2]*, and one of the three places in the prompt was
spent on a sentence it already had. Lesson 12 counts what that kind of waste costs, and removes it.

The third source is the terms of sale, and the model made something of it that no source says. It
called them *outdated* because their date is earlier, which is lesson 7's instruction applied where it
does not belong: the terms are current, and their seven days are the legal minimum the policy extends
to thirty. The number survived the reasoning, this time.

```
ana@vm:~/rag$ python hs_ask.py "Can I pay with cryptocurrency?"
I could not find that in our documents.
  0.306  payments-and-invoices
  0.243  terms-of-sale
  0.234  gift-cards
```

The best source scored 0.306, below the floor, so the floor component sent the refusal and the
prompt builder and the generator never ran. The three scores are printed from the retriever's
output, which the run was asked to keep with `include_outputs_from`; without that, a pipeline run
returns only the outputs that nothing else consumed.
