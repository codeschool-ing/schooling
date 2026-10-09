---
title: Measuring Haystack's splitter
version: 2
---

Lesson 10's measurement, the same 26 answerable questions, the same three retrieved pieces, the
same count of tokens, now for Haystack's splitter at three settings: its default, lesson 4's 60
words, and one paragraph per chunk.

```schooling-example
{
  "language": "python",
  "file": "hs_measure.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom haystack.components.embedders import OpenAIDocumentEmbedder, OpenAITextEmbedder\nfrom haystack.components.preprocessors import DocumentSplitter\nfrom haystack.components.retrievers.in_memory import InMemoryEmbeddingRetriever\nfrom haystack.document_stores.in_memory import InMemoryDocumentStore\nfrom hs_docs import docs\nfrom search import vector\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.replace(\"|\", \" \").split())\nquery = OpenAITextEmbedder(model=\"all-minilm\")\n\n\ndef measure(name, retrieve):\n    found, tokens = 0, 0\n    for q in questions:\n        top = retrieve(q[\"question\"])\n        found += any(f in norm(t) for t in top for f in q[\"facts\"])\n        tokens += len(enc.encode(\"\\n\".join(top)))\n    print(f\"{name:30} {found:3}/{len(questions)} {tokens / len(questions):7.0f}\")\n\n\nprint(f\"{'pipeline':30} {'found':>6} {'tokens':>7}\")\nfor name, splitter in ((\"Haystack, defaults\", DocumentSplitter()),\n                       (\"Haystack, 60 words\", DocumentSplitter(split_by=\"word\", split_length=60)),\n                       (\"Haystack, passages\", DocumentSplitter(split_by=\"passage\", split_length=1))):\n    store = InMemoryDocumentStore()\n    chunks = splitter.run(documents=docs)[\"documents\"]\n    store.write_documents(OpenAIDocumentEmbedder(model=\"all-minilm\", progress_bar=False).run(chunks)[\"documents\"])\n    retriever = InMemoryEmbeddingRetriever(store, top_k=3)\n    measure(name, lambda q: [d.content for d in retriever.run(query.run(q)[\"embedding\"])[\"documents\"]])\nmeasure(\"lesson 5's index\", lambda q: [r[2] for r in vector(q, 3)])",
      "note": "Three of Haystack's splitters measured the way lesson 4 measured chunking, with lesson 5's own index at the end for comparison."
    }
  ]
}
```

```
ana@vm:~/rag$ python hs_measure.py
pipeline                        found  tokens
Haystack, defaults              25/26     717
Haystack, 60 words              22/26     244
Haystack, passages              21/26     124
lesson 5's index                26/26     168
```

**Haystack's default is the best default this course has measured.** At 200 words with no overlap
it found 25 of 26 for 717 tokens per question. LangChain's default found 23 for 1,943 and
LlamaIndex's found 22 for 2,044. Two hundred words is close to the 256 word pieces all-MiniLM-L6-v2
reads, so the search sees most of each chunk, where the larger defaults hid most of theirs. It is still more
than four times lesson 5's 168 tokens for one answer fewer.

**Sixty words found fewer than the default.** 22 of 26, where LangChain's 400 characters found
24 and lesson 5's index 26. A word count cuts wherever the sixtieth word falls, mid-sentence and
across headings, and without overlap a fact split by a cut is in neither half; lesson 4's own
"fixed, 60 words" row found 19 for the same reason. What lesson 5 added on top of 60 words was the
document's structure and the heading path in the embedded text, and those are what took it to 26.

**Paragraphs alone were the cheapest and found the fewest**, 21 for 124 tokens: many paragraphs here
are one or two sentences, too small to hold an answer and its context together.

So the order of the defaults is not the order of the tools. A library whose default happens to suit
a corpus still has a default; the settings that won here were chosen by this test, and the same
test is how any of the three would be tuned. The table belongs to Marginalia's thirteen documents
and its 26 questions, and a different corpus can reverse any of its rows.
