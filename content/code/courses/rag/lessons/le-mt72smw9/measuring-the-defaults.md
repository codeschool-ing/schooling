---
title: Measuring the defaults
version: 2
---

Every part of this lesson so far has been read: a signature, a printed prompt, a count of rows. The
claim that a default is worse than a measured choice needs one more thing, a measurement, and lesson
4 already has the method. For each of the 26 answerable questions in `eval.jsonl`, take the three
pieces of text a pipeline retrieves, ask whether one of the question's facts is inside them, and
count the tokens they would put in the prompt. `frameworks.py` does that for seven pipelines, all
with the same embedding model, so the only differences are how the text was cut and what is
returned:

```schooling-example
{
  "language": "python",
  "file": "frameworks.py",
  "parts": [
    {
      "code": "import glob\nimport json\n\nimport tiktoken\nfrom langchain_core.documents import Document\nfrom langchain_core.vectorstores import InMemoryVectorStore\nfrom langchain_openai import OpenAIEmbeddings\nfrom langchain_text_splitters import RecursiveCharacterTextSplitter\nfrom li_setup import docs\nfrom llama_index.core import StorageContext, VectorStoreIndex\nfrom llama_index.core.node_parser import HierarchicalNodeParser, SentenceWindowNodeParser, get_leaf_nodes\nfrom llama_index.core.postprocessor import MetadataReplacementPostProcessor\nfrom llama_index.core.retrievers import AutoMergingRetriever\nfrom search import vector\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.replace(\"|\", \" \").split())\n\n\ndef measure(name, retrieve):\n    found, tokens = 0, 0\n    for q in questions:\n        top = retrieve(q[\"question\"])\n        found += any(f in norm(t) for t in top for f in q[\"facts\"])\n        tokens += len(enc.encode(\"\\n\".join(top)))\n    print(f\"{name:34} {found:3}/{len(questions)} {tokens / len(questions):7.0f}\")\n\n\nprint(f\"{'pipeline':34} {'found':>6} {'tokens':>7}\")\ntexts = [Document(page_content=open(p).read()) for p in sorted(glob.glob(\"data/docs/*.md\"))]\nembeddings = OpenAIEmbeddings(model=\"all-minilm\", check_embedding_ctx_length=False)\nfor size, overlap in ((4000, 200), (400, 50)):\n    store = InMemoryVectorStore(embeddings)\n    store.add_documents(RecursiveCharacterTextSplitter(chunk_size=size, chunk_overlap=overlap).split_documents(texts))\n    measure(f\"LangChain, {size} characters\", lambda q: [d.page_content for d in store.similarity_search(q, k=3)])\n\nplain = VectorStoreIndex.from_documents(docs).as_retriever(similarity_top_k=3)\nmeasure(\"LlamaIndex, defaults\", lambda q: [n.node.get_content() for n in plain.retrieve(q)])\n\nwindows = VectorStoreIndex(SentenceWindowNodeParser.from_defaults(window_size=3).get_nodes_from_documents(docs))\nsentence = windows.as_retriever(similarity_top_k=3)\nwiden = MetadataReplacementPostProcessor(target_metadata_key=\"window\")\nmeasure(\"LlamaIndex, sentences alone\", lambda q: [n.node.get_content() for n in sentence.retrieve(q)])\nmeasure(\"LlamaIndex, sentence window\", lambda q: [n.node.get_content() for n in widen.postprocess_nodes(sentence.retrieve(q))])\n\nnodes = HierarchicalNodeParser.from_defaults().get_nodes_from_documents(docs)\nstorage = StorageContext.from_defaults()\nstorage.docstore.add_documents(nodes)\nleaves = VectorStoreIndex(get_leaf_nodes(nodes), storage_context=storage)\nmerging = AutoMergingRetriever(leaves.as_retriever(similarity_top_k=6), storage)\nmeasure(\"LlamaIndex, auto-merging\", lambda q: [n.node.get_content() for n in merging.retrieve(q)])\n\nmeasure(\"lesson 5's index\", lambda q: [r[2] for r in vector(q, 3)])",
      "note": "Every pipeline in this lesson measured the way lesson 4 measured chunking: how many of the 26 answerable questions had a right fact in what came back, and how many tokens that cost, with lesson 5's own index at the end for comparison."
    }
  ]
}
```

```
ana@vm:~/rag$ python frameworks.py
pipeline                            found  tokens
LangChain, 4000 characters          23/26    1943
LangChain, 400 characters           24/26     211
LlamaIndex, defaults                22/26    2044
LlamaIndex, sentences alone         21/26      96
LlamaIndex, sentence window         26/26     521
LlamaIndex, auto-merging            25/26     581
lesson 5's index                    26/26     168
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A scatter of seven pipelines: retrieved tokens per question against questions whose answer was retrieved, out of 26. LangChain at 4,000 characters: 1,943 tokens, 23. LangChain at 400 characters: 211, 24. LlamaIndex defaults: 2,044, 22. Sentences alone: 96, 21. Sentence window: 521, 26. Auto-merging: 581, 25. Lesson 5&#x27;s index: 168, 26.\"><path d=\"M70 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 280 L70.0 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M210.9090909090909 280 L210.9090909090909 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"210.9090909090909\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500</text><path d=\"M351.8181818181818 280 L351.8181818181818 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"351.8181818181818\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000</text><path d=\"M492.72727272727275 280 L492.72727272727275 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"492.72727272727275\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1500</text><path d=\"M633.6363636363636 280 L633.6363636363636 285\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"633.6363636363636\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2000</text><path d=\"M65 280.0 L70 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M65 240.0 L70 240.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21</text><path d=\"M65 200.0 L70 200.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><path d=\"M65 160.0 L70 160.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">23</text><path d=\"M65 120.0 L70 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M65 80.0 L70 80.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">26</text><text x=\"380.0\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">retrieved tokens per question</text><text x=\"70\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">questions whose answer was retrieved, of 26</text><circle cx=\"617.6\" cy=\"160.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"607.5727272727273\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">LangChain 4000</text><circle cx=\"129.5\" cy=\"120.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"139.46363636363637\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">LangChain 400</text><circle cx=\"646.0\" cy=\"200.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"636.0363636363636\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">LlamaIndex default</text><circle cx=\"97.1\" cy=\"240.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"107.05454545454546\" y=\"240.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sentences alone</text><circle cx=\"216.8\" cy=\"40.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"226.8272727272727\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sentence window</text><circle cx=\"233.7\" cy=\"80.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"243.73636363636365\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">auto-merging</text><circle cx=\"117.3\" cy=\"40.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"125.34545454545454\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lesson 5's index</text></svg>", "caption": "Up and to the left is better. Both frameworks' defaults sit at the bottom right, paying more than ten times the tokens of lesson 5's index to find fewer answers; tuned, they move to the left."}
```

**The two defaults are the worst trade in the table.** LangChain at 4,000 characters found 23 and
LlamaIndex's defaults found 22, while sending about 2,000 tokens per question. Lesson 5's index found
all 26 with 168. Large chunks were supposed to make a missed answer impossible, since each one
holds nearly a whole document. They missed more, and `embeddings-vectors` lesson 3 has the reason:
all-MiniLM-L6-v2 reads at most 256 word pieces, so a chunk of 491 words is searched by its first
two hundred or so, and an answer further down is in the chunk and invisible to the search.

**Tuned, both frameworks get close.** LangChain's splitter at 400 characters found 24 for 211
tokens, the same territory as lesson 4's 60-word rows. The sentence window found all 26, at 521
tokens, three times lesson 5's price for the same score: the precision of a sentence and the
context of a paragraph, paid for with the paragraph. Auto-merging found 25 for 581. Sentences alone
were the cheapest row and found the fewest, which is the reason both of those techniques exist.

Two cautions about what this table can say. Thirty questions about thirteen documents, as lesson 8
warned, separate a difference of 22 against 26 and say nothing about 25 against 26. And it measures
retrieval only, the half a framework's defaults decide; what the model does with the retrieved
text is lesson 8's other half, and the prompt a framework sends is a default of its own, which the
previous sections read.

**None of these numbers belongs to LangChain or LlamaIndex.** They belong to the settings, and the
settings belong to this corpus: the sizes in lesson 4 were chosen by this same test, and a framework
tuned with the test reaches the same place. A framework can carry a measured setting and cannot
choose one, because choosing needs the questions, and only the team has them.
